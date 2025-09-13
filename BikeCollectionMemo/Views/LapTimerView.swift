import SwiftUI
import CoreLocation

struct LapTimerView: View {
    @StateObject private var lapTimerManager = LapTimerManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingCourseSelection = false
    @State private var showingHistory = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // タイマー表示
                VStack(spacing: 10) {
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
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(lapTimerManager.timerState == .tracking ? Color.green.opacity(0.1) : Color(.systemGray6))
                )

                // ステータス表示
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    statusItem(title: "ラップ", value: "\(lapTimerManager.currentLap)", color: .blue)
                    statusItem(title: "速度", value: lapTimerManager.currentSpeed.speedKmh, color: .green)
                    statusItem(title: "距離", value: lapTimerManager.distance.distanceString, color: .purple)
                    statusItem(title: "状態", value: lapTimerManager.timerState.rawValue, color: .orange)
                }

                // コントロールボタン
                controlButtons

                Spacer()
            }
            .padding(16)
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

    private var controlButtons: some View {
        VStack(spacing: 12) {
            if lapTimerManager.timerState == .idle {
                Button("計測開始") {
                    showingCourseSelection = true
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            } else if lapTimerManager.timerState == .tracking {
                HStack(spacing: 12) {
                    Button("ラップ") {
                        lapTimerManager.completeLap()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)

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
            }
        }
    }

}

#Preview {
    LapTimerView()
}