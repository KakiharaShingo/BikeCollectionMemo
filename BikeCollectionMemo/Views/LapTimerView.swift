import SwiftUI

struct LapTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var lapTimerManager = LapTimerManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var showingCourseSelection = false
    @State private var showingHistory = false
    @State private var showingLocationPermissionAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                timerDisplaySection
                
                locationStatusSection
                
                statusSection
                
                buttonSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("ラップタイマー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("履歴") {
                        showingHistory = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCourseSelection) {
                CourseSelectionView(
                    onStart: { course, bike in
                        lapTimerManager.startSession(course: course, bikeId: bike?.id?.uuidString, bikeName: bike?.name)
                        showingCourseSelection = false
                    }
                )
            }
            .sheet(isPresented: $showingHistory) {
                LapTimerHistoryView()
            }
            .alert("位置情報の許可が必要です", isPresented: $showingLocationPermissionAlert) {
                Button("設定を開く") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("ラップタイマーを使用するには位置情報の許可が必要です。設定アプリで許可してください。")
            }
        }
        .onAppear {
            // アプリ起動時にセッションの復元を確認
            lapTimerManager.restoreSessionIfNeeded()
        }
    }

    private var timerDisplaySection: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("現在のラップ")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if let session = lapTimerManager.currentSession {
                        Text(session.courseName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if lapTimerManager.timerState == .tracking {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(lapTimerManager.timerState == .tracking ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: lapTimerManager.timerState)
                        
                        Text("計測中")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
            }

            Text(formatTime(lapTimerManager.currentLapTime))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .animation(.easeInOut(duration: 0.1), value: lapTimerManager.currentLapTime)

            Text("合計時間: \(formatTime(lapTimerManager.totalTime))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(lapTimerManager.timerState == .tracking ? Color.green.opacity(0.1) : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(lapTimerManager.timerState == .tracking ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
    }

    private var locationStatusSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: locationStatusIcon)
                    .foregroundColor(locationStatusColor)
                    .font(.subheadline)
                
                Text(locationStatusText)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if locationManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let errorMessage = locationManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(locationStatusColor.opacity(0.1))
        )
    }
    
    private var locationStatusIcon: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "location.fill"
        case .denied, .restricted:
            return "location.slash.fill"
        case .notDetermined:
            return "location"
        @unknown default:
            return "location"
        }
    }
    
    private var locationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "位置情報: 許可済み"
        case .denied, .restricted:
            return "位置情報: 拒否"
        case .notDetermined:
            return "位置情報: 未設定"
        @unknown default:
            return "位置情報: 不明"
        }
    }

    private var statusSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 10) {
            statusItem(title: "ラップ", value: "\(lapTimerManager.currentLap)", color: .blue)
            statusItem(title: "速度", value: formatSpeed(lapTimerManager.currentSpeed), color: .green)
            statusItem(title: "距離", value: formatDistance(lapTimerManager.distance), color: .purple)
            statusItem(title: "GPS精度", value: formatGpsAccuracy(lapTimerManager.gpsAccuracy), color: lapTimerManager.isGpsAccuracyGood ? .green : .red)
        }
    }

    private var buttonSection: some View {
        VStack(spacing: 12) {
            if lapTimerManager.timerState == .idle {
                startButton
            } else if lapTimerManager.timerState == .tracking {
                HStack(spacing: 12) {
                    lapButton
                    stopButton
                }
            }
        }
    }

    private var startButton: some View {
        Button("計測開始") {
            checkLocationPermissionAndStart()
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(canStartMeasurement ? Color.green : Color.gray)
        .cornerRadius(12)
        .padding(.horizontal)
        .disabled(!canStartMeasurement)
    }
    
    private var canStartMeasurement: Bool {
        locationManager.authorizationStatus == .authorizedWhenInUse || 
        locationManager.authorizationStatus == .authorizedAlways
    }
    
    private func checkLocationPermissionAndStart() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            showingCourseSelection = true
        case .notDetermined:
            locationManager.requestLocationPermission()
        case .denied, .restricted:
            showingLocationPermissionAlert = true
        @unknown default:
            break
        }
    }

    private var lapButton: some View {
        Button("ラップ") {
            lapTimerManager.completeLap()
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .cornerRadius(12)
    }

    private var stopButton: some View {
        Button("停止") {
            lapTimerManager.stopSession()
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.red)
        .cornerRadius(12)
    }

    private func statusItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)

        if minutes > 0 {
            return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
        } else {
            return String(format: "%d.%03d", seconds, milliseconds)
        }
    }

    private func formatSpeed(_ speed: Double) -> String {
        let kmh = speed * 3.6
        return String(format: "%.1f km/h", kmh)
    }

    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.2fkm", distance / 1000)
        }
    }

    private func formatGpsAccuracy(_ accuracy: Double) -> String {
        if accuracy <= 0 {
            return "不明"
        } else if accuracy < 1000 {
            return String(format: "%.0fm", accuracy)
        } else {
            return String(format: "%.1fkm", accuracy / 1000)
        }
    }

}

#Preview {
    LapTimerView()
}