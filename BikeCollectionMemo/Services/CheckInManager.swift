import Foundation
import CoreData

@MainActor
class CheckInManager: ObservableObject {
    static let shared = CheckInManager()

    @Published var checkInRecords: [CheckInRecord] = []
    @Published var userLocations: [CheckInLocation] = []

    private let userDefaults = UserDefaults.standard
    private let checkInRecordsKey = "checkInRecords"
    private let userLocationsKey = "userLocations"

    init() {
        loadData()
    }

    // MARK: - Data Persistence
    private func loadData() {
        loadCheckInRecords()
        loadUserLocations()
    }

    private func loadCheckInRecords() {
        if let data = userDefaults.data(forKey: checkInRecordsKey),
           let records = try? JSONDecoder().decode([CheckInRecord].self, from: data) {
            checkInRecords = records.sorted { $0.timestamp > $1.timestamp }
        }
    }

    private func saveCheckInRecords() {
        if let data = try? JSONEncoder().encode(checkInRecords) {
            userDefaults.set(data, forKey: checkInRecordsKey)
        }
    }

    private func loadUserLocations() {
        if let data = userDefaults.data(forKey: userLocationsKey),
           let locations = try? JSONDecoder().decode([CheckInLocation].self, from: data) {
            userLocations = locations
        }
    }

    private func saveUserLocations() {
        if let data = try? JSONEncoder().encode(userLocations) {
            userDefaults.set(data, forKey: userLocationsKey)
        }
    }

    // MARK: - CheckIn Records Management
    func addCheckInRecord(_ record: CheckInRecord) {
        checkInRecords.insert(record, at: 0) // 最新を先頭に
        saveCheckInRecords()
    }

    func deleteCheckInRecord(_ record: CheckInRecord) {
        checkInRecords.removeAll { $0.id == record.id }
        saveCheckInRecords()
    }

    func getCheckInRecords(for locationId: UUID) -> [CheckInRecord] {
        return checkInRecords.filter { $0.locationId == locationId }
    }

    func getCheckInCount(for locationId: UUID) -> Int {
        return getCheckInRecords(for: locationId).count
    }

    func getLastCheckIn(for locationId: UUID) -> CheckInRecord? {
        return getCheckInRecords(for: locationId).first
    }

    // MARK: - User Locations Management
    func addUserLocation(_ location: CheckInLocation) {
        userLocations.append(location)
        saveUserLocations()
    }

    func deleteUserLocation(_ location: CheckInLocation) {
        userLocations.removeAll { $0.id == location.id }
        saveUserLocations()
    }

    // MARK: - Statistics
    func getTotalCheckInCount() -> Int {
        return checkInRecords.count
    }

    func getUniqueLocationsCount() -> Int {
        let uniqueLocationIds = Set(checkInRecords.map { $0.locationId })
        return uniqueLocationIds.count
    }

    func getMostVisitedLocations(limit: Int = 5) -> [(locationName: String, count: Int)] {
        let locationCounts = Dictionary(grouping: checkInRecords, by: { $0.locationName })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        return Array(locationCounts.prefix(limit))
            .map { (locationName: $0.key, count: $0.value) }
    }

    func getCheckInsByMonth() -> [String: Int] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"

        let monthlyCheckIns = Dictionary(grouping: checkInRecords) { record in
            dateFormatter.string(from: record.timestamp)
        }.mapValues { $0.count }

        return monthlyCheckIns
    }

    func getRecentCheckIns(limit: Int = 10) -> [CheckInRecord] {
        return Array(checkInRecords.prefix(limit))
    }

    // MARK: - Search and Filter
    func searchLocations(query: String) -> [CheckInLocation] {
        let allLocations = CheckInLocation.presetLocations + userLocations
        guard !query.isEmpty else { return allLocations }

        return allLocations.filter { location in
            location.name.localizedCaseInsensitiveContains(query) ||
            (location.address?.localizedCaseInsensitiveContains(query) ?? false) ||
            location.category.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    func filterCheckInRecords(by category: CheckInLocation.LocationCategory? = nil,
                             dateFrom: Date? = nil,
                             dateTo: Date? = nil,
                             bikeId: String? = nil) -> [CheckInRecord] {
        return checkInRecords.filter { record in
            // カテゴリフィルター
            if let category = category {
                let location = findLocation(by: record.locationId)
                if location?.category != category {
                    return false
                }
            }

            // 日付フィルター
            if let dateFrom = dateFrom, record.timestamp < dateFrom {
                return false
            }
            if let dateTo = dateTo, record.timestamp > dateTo {
                return false
            }

            // バイクフィルター
            if let bikeId = bikeId, record.bikeId != bikeId {
                return false
            }

            return true
        }
    }

    // MARK: - Helper Methods
    func findLocation(by id: UUID) -> CheckInLocation? {
        let allLocations = CheckInLocation.presetLocations + userLocations
        return allLocations.first { $0.id == id }
    }

    func formatCheckInDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return "今日 \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.timeStyle = .short
            return "昨日 \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

    // MARK: - Core Data Integration (Future Enhancement)
    // 将来的にCore Dataと統合する場合のためのメソッド群

    func getBikesFromCoreData() -> [Bike] {
        // Core Dataからバイクリストを取得
        // 実装は既存のBikeのCore Data実装に依存
        return []
    }
}