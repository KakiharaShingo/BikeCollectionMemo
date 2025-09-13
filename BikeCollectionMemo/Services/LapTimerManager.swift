import Foundation
import CoreLocation
import Combine

@MainActor
class LapTimerManager: NSObject, ObservableObject {
    static let shared = LapTimerManager()

    // MARK: - Published Properties
    @Published var currentSession: LapTimeSession?
    @Published var timerState: LapTimerState = .idle
    @Published var currentLapTime: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var currentLap: Int = 0
    @Published var currentSpeed: Double = 0 // m/s
    @Published var maxSpeed: Double = 0 // m/s
    @Published var distance: Double = 0 // メートル
    @Published var isNearStartLine: Bool = false

    // MARK: - Private Properties
    private var timer: Timer?
    private var startTime: Date?
    private var lapStartTime: Date?
    private var lastLocation: CLLocation?
    private var trackPoints: [GPSTrackPoint] = []
    private var laps: [LapRecord] = []
    private var currentCourse: TimingCourse?
    private var lapDistances: [Double] = []
    private var speedReadings: [Double] = []

    // MARK: - UserDefaults Keys
    private let sessionsKey = "lap_time_sessions"
    private let coursesKey = "timing_courses"

    private let locationManager = LocationManager.shared

    override init() {
        super.init()
        setupLocationTracking()
    }

    // MARK: - Session Management
    func startSession(course: TimingCourse, bikeId: String? = nil, bikeName: String? = nil) {
        guard timerState == .idle else { return }

        currentCourse = course
        currentSession = LapTimeSession(
            courseName: course.name,
            startLocation: course.startFinishLine,
            courseId: course.id,
            bikeId: bikeId,
            bikeName: bikeName
        )

        resetCounters()
        timerState = .tracking
        startTime = Date()
        lapStartTime = Date()
        currentLap = 1

        startTimer()
        locationManager.startLocationUpdates()
    }

    func pauseSession() {
        guard timerState == .tracking else { return }
        timerState = .paused
        stopTimer()
    }

    func resumeSession() {
        guard timerState == .paused else { return }
        timerState = .tracking
        startTimer()
    }

    func stopSession() {
        timerState = .idle
        stopTimer()
        locationManager.stopLocationUpdates()

        if var session = currentSession {
            // セッション終了処理
            session = LapTimeSession(
                courseId: session.courseId,
                courseName: session.courseName,
                startTime: session.startTime,
                endTime: Date(),
                bikeId: session.bikeId,
                bikeName: session.bikeName,
                laps: laps,
                totalDistance: distance,
                startLocation: session.startLocation,
                trackPoints: trackPoints
            )

            saveSession(session)
        }

        currentSession = nil
        resetCounters()
    }

    func completeLap() {
        guard timerState == .tracking, let lapStart = lapStartTime else { return }

        let lapEndTime = Date()
        let lapTime = lapEndTime.timeIntervalSince(lapStart)

        // 現在のラップを完了
        let completedLap = LapRecord(
            lapNumber: currentLap,
            startTime: lapStart,
            startLocation: currentCourse?.startFinishLine ?? CLLocationCoordinate2D(),
            endTime: lapEndTime,
            endLocation: lastLocation?.coordinate,
            lapDistance: currentLap <= lapDistances.count ? lapDistances[currentLap - 1] : 0,
            maxSpeed: maxSpeed,
            averageSpeed: speedReadings.isEmpty ? 0 : speedReadings.reduce(0, +) / Double(speedReadings.count)
        )

        laps.append(completedLap)

        // 次のラップの準備
        currentLap += 1
        lapStartTime = Date()
        currentLapTime = 0
        maxSpeed = 0
        speedReadings.removeAll()

        // ラップ距離をリセット（次のラップ用）
        if lapDistances.count >= currentLap - 1 {
            let currentLapDistance = lapDistances.count >= currentLap - 1 ? lapDistances[currentLap - 2] : 0
            distance = distance - currentLapDistance
        }
    }

    // MARK: - Timer Management
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimer() {
        guard let startTime = startTime, let lapStart = lapStartTime else { return }

        totalTime = Date().timeIntervalSince(startTime)
        currentLapTime = Date().timeIntervalSince(lapStart)
    }

    private func resetCounters() {
        currentLapTime = 0
        totalTime = 0
        currentLap = 0
        currentSpeed = 0
        maxSpeed = 0
        distance = 0
        trackPoints.removeAll()
        laps.removeAll()
        lapDistances.removeAll()
        speedReadings.removeAll()
        lastLocation = nil
        isNearStartLine = false
    }

    // MARK: - Location Tracking
    private func setupLocationTracking() {
        // LocationManagerの位置更新を監視
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] coordinate in
                Task { @MainActor in
                    await self?.processLocationUpdate(coordinate)
                }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func processLocationUpdate(_ coordinate: CLLocationCoordinate2D) async {
        guard timerState == .tracking else { return }

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        // GPSトラックポイントを記録
        let trackPoint = GPSTrackPoint(location: location)
        trackPoints.append(trackPoint)

        // 速度の更新
        if let speed = trackPoint.speed, speed >= 0 {
            currentSpeed = speed
            maxSpeed = max(maxSpeed, speed)
            speedReadings.append(speed)
        }

        // 距離の計算
        if let lastLoc = lastLocation {
            let segmentDistance = location.distance(from: lastLoc)
            distance += segmentDistance

            // ラップ距離の追跡
            if lapDistances.count < currentLap {
                lapDistances.append(segmentDistance)
            } else {
                lapDistances[currentLap - 1] += segmentDistance
            }
        }

        lastLocation = location

        // スタート/フィニッシュライン通過判定
        if let course = currentCourse {
            let distanceToStartLine = location.distance(from: CLLocation(
                latitude: course.startFinishLine.latitude,
                longitude: course.startFinishLine.longitude
            ))

            isNearStartLine = distanceToStartLine <= course.toleranceRadius

            // 自動ラップ検出（2周目以降）
            if currentLap > 1 && isNearStartLine && !wasNearStartLine {
                completeLap()
            }
        }

        wasNearStartLine = isNearStartLine
    }

    private var wasNearStartLine: Bool = false

    // MARK: - Data Persistence
    func saveSession(_ session: LapTimeSession) {
        var sessions = getSavedSessions()
        sessions.append(session)

        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    func getSavedSessions() -> [LapTimeSession] {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let sessions = try? JSONDecoder().decode([LapTimeSession].self, from: data) else {
            return []
        }
        return sessions.sorted { $0.startTime > $1.startTime }
    }

    func deleteSession(_ session: LapTimeSession) {
        var sessions = getSavedSessions()
        sessions.removeAll { $0.id == session.id }

        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsKey)
        }
    }

    // MARK: - Course Management
    func saveCustomCourse(_ course: TimingCourse) {
        var courses = getSavedCourses()
        courses.append(course)

        if let data = try? JSONEncoder().encode(courses) {
            UserDefaults.standard.set(data, forKey: coursesKey)
        }
    }

    func getSavedCourses() -> [TimingCourse] {
        guard let data = UserDefaults.standard.data(forKey: coursesKey),
              let courses = try? JSONDecoder().decode([TimingCourse].self, from: data) else {
            return TimingCourse.presetCourses
        }
        return TimingCourse.presetCourses + courses
    }

    func deleteCourse(_ course: TimingCourse) {
        guard !course.isPreset else { return } // プリセットコースは削除不可

        var courses = getSavedCourses().filter { !$0.isPreset }
        courses.removeAll { $0.id == course.id }

        if let data = try? JSONEncoder().encode(courses) {
            UserDefaults.standard.set(data, forKey: coursesKey)
        }
    }

    // MARK: - Statistics
    func getBestLapForCourse(_ courseId: UUID) -> LapRecord? {
        let sessions = getSavedSessions().filter { $0.courseId == courseId }
        let allLaps = sessions.flatMap { $0.laps }
        return allLaps.compactMap { lap -> (LapRecord, TimeInterval)? in
            guard let lapTime = lap.lapTime else { return nil }
            return (lap, lapTime)
        }.min { $0.1 < $1.1 }?.0
    }

    func getSessionsForCourse(_ courseId: UUID) -> [LapTimeSession] {
        return getSavedSessions().filter { $0.courseId == courseId }
    }
}

// MARK: - LapRecord Extension
extension LapRecord {
    init(lapNumber: Int, startTime: Date, startLocation: CLLocationCoordinate2D, endTime: Date?, endLocation: CLLocationCoordinate2D?, lapDistance: Double, maxSpeed: Double, averageSpeed: Double) {
        self.lapNumber = lapNumber
        self.startTime = startTime
        self.endTime = endTime
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.lapDistance = lapDistance
        self.maxSpeed = maxSpeed
        self.averageSpeed = averageSpeed
    }
}