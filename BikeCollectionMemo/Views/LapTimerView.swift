import SwiftUI
import CoreLocation

struct LapTimerView: View {
    @StateObject private var lapTimerManager = LapTimerManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingCourseSelection = false
    @State private var showingHistory = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // タイマー表示
                    TimerDisplayCard()

                    // ステータス表示
                    LapStatusCard()

                    // コントロールボタン
                    TimerControlButtons(showingCourseSelection: $showingCourseSelection)

                    Spacer(minLength: 50)
                }
                .padding(Constants.Spacing.medium)
            }
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
                CourseSelectionView { course, bike in
                    lapTimerManager.startSession(
                        course: course,
                        bikeId: bike?.id,
                        bikeName: bike?.name
                    )
                }
            }
            .sheet(isPresented: $showingHistory) {
                LapTimerHistoryView()
            }
        }
    }

}

// MARK: - Timer Display Card
struct TimerDisplayCard: View {
    @StateObject private var lapTimerManager = LapTimerManager.shared

    var body: some View {
        VStack(spacing: Constants.Spacing.medium) {
            Text("現在のラップ")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(lapTimerManager.currentLapTime.lapTimeString)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)

            Text("合計時間: \(lapTimerManager.totalTime.shortTimeString)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(Constants.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                .fill(lapTimerManager.timerState == .tracking ? Color.green.opacity(0.1) : Color(.systemGray6))
        )
    }
}

// MARK: - Lap Status Card
struct LapStatusCard: View {
    @StateObject private var lapTimerManager = LapTimerManager.shared

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Constants.Spacing.small) {
            StatusItem(title: "ラップ", value: "\(lapTimerManager.currentLap)", color: .blue)
            StatusItem(title: "速度", value: lapTimerManager.currentSpeed.speedKmh, color: .green)
            StatusItem(title: "距離", value: lapTimerManager.distance.distanceString, color: .purple)
            StatusItem(title: "状態", value: lapTimerManager.timerState.rawValue, color: .orange)
        }
    }
}

// MARK: - Timer Control Buttons
struct TimerControlButtons: View {
    @StateObject private var lapTimerManager = LapTimerManager.shared
    @Binding var showingCourseSelection: Bool

    var body: some View {
        VStack(spacing: Constants.Spacing.medium) {
            if lapTimerManager.timerState == .idle {
                Button("計測開始") {
                    showingCourseSelection = true
                }
                .buttonStyle(PrimaryButtonStyle())
            } else if lapTimerManager.timerState == .tracking {
                HStack(spacing: Constants.Spacing.medium) {
                    Button("ラップ") {
                        lapTimerManager.completeLap()
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button("停止") {
                        lapTimerManager.stopSession()
                    }
                    .buttonStyle(DangerButtonStyle())
                }
            }
        }
    }
}

// MARK: - Status Item
struct StatusItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
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
        .padding(Constants.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    LapTimerView()
}