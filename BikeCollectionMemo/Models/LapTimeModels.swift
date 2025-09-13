import Foundation
import CoreLocation

// MARK: - Lap Time Session
struct LapTimeSession: Codable, Identifiable {
    var id = UUID()
    let courseId: UUID?
    let courseName: String
    let startTime: Date
    let endTime: Date?
    let bikeId: String?
    let bikeName: String?
    let laps: [LapRecord]
    let totalDistance: Double // メートル
    let startLocation: CLLocationCoordinate2D
    let trackPoints: [GPSTrackPoint] // GPS軌跡

    var duration: TimeInterval {
        return (endTime ?? Date()).timeIntervalSince(startTime)
    }

    var bestLapTime: TimeInterval? {
        return laps.compactMap { $0.lapTime }.min()
    }

    var averageLapTime: TimeInterval? {
        let completedLaps = laps.compactMap { $0.lapTime }
        guard !completedLaps.isEmpty else { return nil }
        return completedLaps.reduce(0, +) / Double(completedLaps.count)
    }

    var totalLaps: Int {
        return laps.count
    }

    init(courseName: String, startLocation: CLLocationCoordinate2D, courseId: UUID? = nil, bikeId: String? = nil, bikeName: String? = nil) {
        self.courseId = courseId
        self.courseName = courseName
        self.startTime = Date()
        self.endTime = nil
        self.bikeId = bikeId
        self.bikeName = bikeName
        self.laps = []
        self.totalDistance = 0
        self.startLocation = startLocation
        self.trackPoints = []
    }

    init(courseId: UUID?, courseName: String, startTime: Date, endTime: Date?, bikeId: String?, bikeName: String?, laps: [LapRecord], totalDistance: Double, startLocation: CLLocationCoordinate2D, trackPoints: [GPSTrackPoint]) {
        self.id = UUID()
        self.courseId = courseId
        self.courseName = courseName
        self.startTime = startTime
        self.endTime = endTime
        self.bikeId = bikeId
        self.bikeName = bikeName
        self.laps = laps
        self.totalDistance = totalDistance
        self.startLocation = startLocation
        self.trackPoints = trackPoints
    }
}

// MARK: - Lap Record
struct LapRecord: Codable, Identifiable {
    let id = UUID()
    let lapNumber: Int
    let startTime: Date
    let endTime: Date?
    let startLocation: CLLocationCoordinate2D
    let endLocation: CLLocationCoordinate2D?
    let lapDistance: Double // メートル
    let maxSpeed: Double // m/s
    let averageSpeed: Double // m/s

    var lapTime: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var isCompleted: Bool {
        return endTime != nil
    }

    init(lapNumber: Int, startTime: Date, startLocation: CLLocationCoordinate2D) {
        self.lapNumber = lapNumber
        self.startTime = startTime
        self.endTime = nil
        self.startLocation = startLocation
        self.endLocation = nil
        self.lapDistance = 0
        self.maxSpeed = 0
        self.averageSpeed = 0
    }
}

// MARK: - GPS Track Point
struct GPSTrackPoint: Codable {
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let altitude: Double?
    let speed: Double? // m/s
    let accuracy: Double // メートル

    init(location: CLLocation) {
        self.coordinate = location.coordinate
        self.timestamp = location.timestamp
        self.altitude = location.altitude
        self.speed = location.speed >= 0 ? location.speed : nil
        self.accuracy = location.horizontalAccuracy
    }
}

// MARK: - Lap Timer State
enum LapTimerState: String, Codable {
    case idle = "停止中"
    case tracking = "計測中"
    case paused = "一時停止"
    case completed = "完了"
}

// MARK: - Course Definition
struct TimingCourse: Codable, Identifiable {
    let id = UUID()
    let name: String
    let startFinishLine: CLLocationCoordinate2D
    let toleranceRadius: Double // メートル（スタート/フィニッシュラインの許容範囲）
    let expectedLapDistance: Double? // メートル（推定ラップ距離）
    let isPreset: Bool
    let createdDate: Date

    init(name: String, startFinishLine: CLLocationCoordinate2D, toleranceRadius: Double = 30.0, expectedLapDistance: Double? = nil, isPreset: Bool = false) {
        self.name = name
        self.startFinishLine = startFinishLine
        self.toleranceRadius = toleranceRadius
        self.expectedLapDistance = expectedLapDistance
        self.isPreset = isPreset
        self.createdDate = Date()
    }
}

// MARK: - Preset Courses
extension TimingCourse {
    static let presetCourses: [TimingCourse] = [
        TimingCourse(
            name: "鈴鹿サーキット",
            startFinishLine: CLLocationCoordinate2D(latitude: 34.8431, longitude: 136.5407),
            toleranceRadius: 50.0,
            expectedLapDistance: 5807.0,
            isPreset: true
        ),
        TimingCourse(
            name: "富士スピードウェイ",
            startFinishLine: CLLocationCoordinate2D(latitude: 35.3681, longitude: 138.9107),
            toleranceRadius: 50.0,
            expectedLapDistance: 4563.0,
            isPreset: true
        ),
        TimingCourse(
            name: "ツインリンクもてぎ",
            startFinishLine: CLLocationCoordinate2D(latitude: 36.5389, longitude: 140.2269),
            toleranceRadius: 50.0,
            expectedLapDistance: 4801.0,
            isPreset: true
        )
    ]
}

// MARK: - Time Formatting Extensions
extension TimeInterval {
    var lapTimeString: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        let milliseconds = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)

        if minutes > 0 {
            return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
        } else {
            return String(format: "%d.%03d", seconds, milliseconds)
        }
    }

    var shortTimeString: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

extension Double {
    var speedKmh: String {
        let kmh = self * 3.6 // m/s to km/h
        return String(format: "%.1f km/h", kmh)
    }

    var distanceString: String {
        if self < 1000 {
            return String(format: "%.0fm", self)
        } else {
            return String(format: "%.2fkm", self / 1000)
        }
    }
}