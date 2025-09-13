import Foundation
import CoreLocation
import MapKit

// MARK: - CheckIn Location
struct CheckInLocation: Codable, Identifiable {
    let id = UUID()
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let category: LocationCategory
    let isPreset: Bool // プリセット場所かユーザー追加か

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum LocationCategory: String, CaseIterable, Codable {
        case raceTrack = "サーキット"
        case tourismSpot = "観光地"
        case mountainPass = "峠道"
        case gasStation = "ガソリンスタンド"
        case bikeShop = "バイク店"
        case restaurant = "レストラン・カフェ"
        case parkingArea = "道の駅・SA/PA"
        case viewpoint = "展望台"
        case shrine = "神社・仏閣"
        case other = "その他"

        var systemImage: String {
            switch self {
            case .raceTrack: return "flag.checkered"
            case .tourismSpot: return "camera"
            case .mountainPass: return "mountain.2"
            case .gasStation: return "fuelpump"
            case .bikeShop: return "wrench.and.screwdriver"
            case .restaurant: return "fork.knife"
            case .parkingArea: return "parkingsign"
            case .viewpoint: return "eye"
            case .shrine: return "building.columns"
            case .other: return "mappin"
            }
        }

        var color: String {
            switch self {
            case .raceTrack: return "red"
            case .tourismSpot: return "blue"
            case .mountainPass: return "green"
            case .gasStation: return "orange"
            case .bikeShop: return "purple"
            case .restaurant: return "brown"
            case .parkingArea: return "cyan"
            case .viewpoint: return "indigo"
            case .shrine: return "mint"
            case .other: return "gray"
            }
        }
    }
}

// MARK: - CheckIn Record
struct CheckInRecord: Codable, Identifiable {
    let id = UUID()
    let locationId: UUID
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let bikeId: String? // 使用したバイクのID
    let bikeName: String?
    let memo: String?
    let weather: String?
    let companions: [String] // 同行者リスト
    let photos: [String] // 写真ファイル名（将来の拡張用）

    init(location: CheckInLocation, bikeId: String? = nil, bikeName: String? = nil, memo: String? = nil, weather: String? = nil, companions: [String] = []) {
        self.locationId = location.id
        self.locationName = location.name
        self.coordinate = location.coordinate
        self.timestamp = Date()
        self.bikeId = bikeId
        self.bikeName = bikeName
        self.memo = memo
        self.weather = weather
        self.companions = companions
        self.photos = []
    }
}

// MARK: - Weather Options
enum WeatherCondition: String, CaseIterable, Codable {
    case sunny = "晴れ"
    case cloudy = "曇り"
    case rainy = "雨"
    case snowy = "雪"
    case foggy = "霧"
    case windy = "強風"

    var systemImage: String {
        switch self {
        case .sunny: return "sun.max"
        case .cloudy: return "cloud"
        case .rainy: return "cloud.rain"
        case .snowy: return "cloud.snow"
        case .foggy: return "cloud.fog"
        case .windy: return "wind"
        }
    }
}

// MARK: - Preset Locations
extension CheckInLocation {
    static let presetLocations: [CheckInLocation] = [
        // サーキット
        CheckInLocation(
            name: "鈴鹿サーキット",
            address: "三重県鈴鹿市稲生町7992",
            latitude: 34.8431,
            longitude: 136.5407,
            category: .raceTrack,
            isPreset: true
        ),
        CheckInLocation(
            name: "富士スピードウェイ",
            address: "静岡県駿東郡小山町中日向694",
            latitude: 35.3681,
            longitude: 138.9107,
            category: .raceTrack,
            isPreset: true
        ),
        CheckInLocation(
            name: "ツインリンクもてぎ",
            address: "栃木県芳賀郡茂木町桧山120-1",
            latitude: 36.5389,
            longitude: 140.2269,
            category: .raceTrack,
            isPreset: true
        ),

        // 峠道
        CheckInLocation(
            name: "いろは坂",
            address: "栃木県日光市中宮祠",
            latitude: 36.7089,
            longitude: 139.4581,
            category: .mountainPass,
            isPreset: true
        ),
        CheckInLocation(
            name: "箱根ターンパイク",
            address: "神奈川県足柄下郡箱根町",
            latitude: 35.2031,
            longitude: 139.0219,
            category: .mountainPass,
            isPreset: true
        ),
        CheckInLocation(
            name: "碓氷峠",
            address: "群馬県安中市松井田町",
            latitude: 36.3331,
            longitude: 138.7331,
            category: .mountainPass,
            isPreset: true
        ),

        // 観光地
        CheckInLocation(
            name: "河口湖",
            address: "山梨県南都留郡富士河口湖町",
            latitude: 35.5097,
            longitude: 138.7408,
            category: .tourismSpot,
            isPreset: true
        ),
        CheckInLocation(
            name: "阿蘇山",
            address: "熊本県阿蘇市",
            latitude: 32.8842,
            longitude: 131.1040,
            category: .tourismSpot,
            isPreset: true
        )
    ]
}

// MARK: - CLLocationCoordinate2D Extensions
extension CLLocationCoordinate2D: Codable, Equatable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }

    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}