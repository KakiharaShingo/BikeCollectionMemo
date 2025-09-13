import SwiftUI
import MapKit

struct CheckInHistoryView: View {
    @StateObject private var checkInManager = CheckInManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: CheckInLocation.LocationCategory?
    @State private var showingFilters = false

    var filteredRecords: [CheckInRecord] {
        var records = checkInManager.checkInRecords

        // 検索フィルター
        if !searchText.isEmpty {
            records = records.filter { record in
                record.locationName.localizedCaseInsensitiveContains(searchText) ||
                (record.memo?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // カテゴリフィルター
        if let category = selectedCategory {
            records = records.filter { record in
                guard let location = checkInManager.findLocation(by: record.locationId) else { return false }
                return location.category == category
            }
        }

        return records
    }
    
    // 直近のコースを取得（1つだけ）
    var recentCourse: CheckInRecord? {
        guard let mostRecent = checkInManager.checkInRecords.first else { return nil }
        return mostRecent
    }
    
    // 直近のコース以外のレコードを取得
    var otherRecords: [CheckInRecord] {
        guard let recent = recentCourse else { return filteredRecords }
        return filteredRecords.filter { $0.id != recent.id }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 統計情報
                if !checkInManager.checkInRecords.isEmpty {
                    statisticsSection
                        .padding(.bottom, Constants.Spacing.small)
                }

                // メインコンテンツ
                if filteredRecords.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("チェックイン履歴")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "場所やメモで検索")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(selectedCategory != nil ? .blue : .primary)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(selectedCategory: $selectedCategory)
            }
        }
    }

    // MARK: - Statistics Section
    private var statisticsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.Spacing.medium) {
                CheckInStatCard(
                    title: "総チェックイン",
                    value: "\(checkInManager.getTotalCheckInCount())",
                    icon: "mappin.and.ellipse",
                    color: .blue
                )

                CheckInStatCard(
                    title: "訪問場所",
                    value: "\(checkInManager.getUniqueLocationsCount())",
                    icon: "location",
                    color: .green
                )

                // 最も訪問した場所
                if let mostVisited = checkInManager.getMostVisitedLocations(limit: 1).first {
                    CheckInStatCard(
                        title: "お気に入り",
                        value: mostVisited.locationName,
                        subtitle: "\(mostVisited.count)回訪問",
                        icon: "heart.fill",
                        color: .red
                    )
                }
            }
            .padding(.horizontal, Constants.Spacing.medium)
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: Constants.Spacing.large) {
            Spacer()

            Image(systemName: "mappin.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            VStack(spacing: Constants.Spacing.small) {
                Text(searchText.isEmpty ? "チェックイン履歴がありません" : "検索結果が見つかりません")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text(searchText.isEmpty ? "マップからチェックインして履歴を作成しましょう" : "検索条件を変更してみてください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(Constants.Spacing.large)
    }

    // MARK: - History List
    private var historyListView: some View {
        List {
            // 直近のコースセクション
            if let recent = recentCourse {
                Section(header: 
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("直近のチェックイン")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                ) {
                    CheckInRecordRow(record: recent)
                        .background(Color.blue.opacity(0.05))
                }
            }
            
            // その他の履歴
            if !otherRecords.isEmpty {
                ForEach(groupedOtherRecords, id: \.key) { group in
                    Section(header: Text(group.key).font(.subheadline).fontWeight(.semibold)) {
                        ForEach(group.value) { record in
                            CheckInRecordRow(record: record)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var groupedRecords: [(key: String, value: [CheckInRecord])] {
        let grouped = Dictionary(grouping: filteredRecords) { record in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月"
            return formatter.string(from: record.timestamp)
        }

        return grouped.sorted { $0.key > $1.key }
    }
    
    private var groupedOtherRecords: [(key: String, value: [CheckInRecord])] {
        let grouped = Dictionary(grouping: otherRecords) { record in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月"
            return formatter.string(from: record.timestamp)
        }

        return grouped.sorted { $0.key > $1.key }
    }
}

// MARK: - Supporting Views

struct CheckInStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color

    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Constants.Spacing.medium)
        .frame(minWidth: 120)
        .background(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                .fill(Color(.systemGray6))
        )
    }
}

struct CheckInRecordRow: View {
    let record: CheckInRecord
    @StateObject private var checkInManager = CheckInManager.shared

    var body: some View {
        HStack(alignment: .top, spacing: Constants.Spacing.medium) {
            // カテゴリアイコン
            if let location = checkInManager.findLocation(by: record.locationId) {
                Image(systemName: location.category.systemImage)
                    .foregroundColor(Color(location.category.color))
                    .font(.title3)
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 4) {
                // 場所名と時間
                HStack {
                    Text(record.locationName)
                        .font(.headline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(checkInManager.formatCheckInDate(record.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // バイク情報
                if let bikeName = record.bikeName {
                    HStack {
                        Image(systemName: "bicycle")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(bikeName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // 天気情報
                if let weather = record.weather {
                    HStack {
                        if let weatherCondition = WeatherCondition.allCases.first(where: { $0.rawValue == weather }) {
                            Image(systemName: weatherCondition.systemImage)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(weather)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 同行者
                if !record.companions.isEmpty {
                    HStack {
                        Image(systemName: "person.2")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(record.companions.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                // メモ
                if let memo = record.memo, !memo.isEmpty {
                    Text(memo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(action: {
                checkInManager.deleteCheckInRecord(record)
            }) {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

struct FilterView: View {
    @Binding var selectedCategory: CheckInLocation.LocationCategory?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("カテゴリフィルター") {
                    Button(action: {
                        selectedCategory = nil
                        dismiss()
                    }) {
                        HStack {
                            Text("すべて")
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    ForEach(CheckInLocation.LocationCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: category.systemImage)
                                    .foregroundColor(Color(category.color))

                                Text(category.rawValue)
                                    .foregroundColor(.primary)

                                Spacer()

                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CheckInHistoryView()
}