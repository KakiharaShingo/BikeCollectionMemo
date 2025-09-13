import SwiftUI

struct LapTimerHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var lapTimerManager = LapTimerManager.shared

    @State private var selectedSession: LapTimeSession?
    @State private var showingSessionDetail = false

    var body: some View {
        NavigationView {
            Group {
                if lapTimerManager.getSavedSessions().isEmpty {
                    EmptyHistoryView()
                } else {
                    sessionListView
                }
            }
            .navigationTitle("ラップタイム履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSessionDetail) {
                if let session = selectedSession {
                    SessionDetailView(session: session)
                }
            }
        }
    }

    // MARK: - Session List View
    private var sessionListView: some View {
        List {
            ForEach(lapTimerManager.getSavedSessions(), id: \.id) { session in
                SessionRowView(session: session) {
                    selectedSession = session
                    showingSessionDetail = true
                }
            }
            .onDelete(perform: deleteSessions)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteSessions(offsets: IndexSet) {
        let sessions = lapTimerManager.getSavedSessions()
        for index in offsets {
            lapTimerManager.deleteSession(sessions[index])
        }
    }
}

// MARK: - Empty History View
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: Constants.Spacing.large) {
            Image(systemName: "stopwatch")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("履歴がありません")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("ラップタイマーを使って走行記録を作成しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.Spacing.large)

            Spacer()
        }
        .padding(Constants.Spacing.large)
    }
}

// MARK: - Session Row View
struct SessionRowView: View {
    let session: LapTimeSession
    let onTap: () -> Void

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                HStack {
                    Text(session.courseName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(dateFormatter.string(from: session.startTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let bikeName = session.bikeName {
                    HStack {
                        Image(systemName: "bicycle")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(bikeName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: Constants.Spacing.medium) {
                    // 総ラップ数
                    HStack(spacing: 4) {
                        Image(systemName: "flag.checkered")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("\(session.totalLaps)周")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // 総時間
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(session.duration.shortTimeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // ベストラップ
                    if let bestLap = session.bestLapTime {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(bestLap.lapTimeString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
            }
            .padding(.vertical, Constants.Spacing.small)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Session Detail View
struct SessionDetailView: View {
    let session: LapTimeSession
    @Environment(\.dismiss) private var dismiss

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                    // セッション概要
                    sessionSummarySection

                    // ラップ詳細
                    lapDetailsSection

                    // 統計情報
                    statisticsSection
                }
                .padding(Constants.Spacing.medium)
            }
            .navigationTitle(session.courseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Session Summary
    private var sessionSummarySection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            Text("セッション概要")
                .font(.headline)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                InfoRow(title: "日時", value: dateFormatter.string(from: session.startTime))

                InfoRow(title: "コース", value: session.courseName)

                if let bikeName = session.bikeName {
                    InfoRow(title: "バイク", value: bikeName)
                }

                InfoRow(title: "総時間", value: session.duration.shortTimeString)

                InfoRow(title: "総距離", value: session.totalDistance.distanceString)

                InfoRow(title: "総ラップ数", value: "\(session.totalLaps)周")
            }
            .padding(Constants.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(Color(.systemGray6))
            )
        }
    }

    // MARK: - Lap Details
    private var lapDetailsSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            Text("ラップ詳細")
                .font(.headline)
                .fontWeight(.bold)

            if session.laps.isEmpty {
                Text("ラップデータがありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(session.laps, id: \.id) { lap in
                    LapDetailCard(lap: lap)
                }
            }
        }
    }

    // MARK: - Statistics
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            Text("統計情報")
                .font(.headline)
                .fontWeight(.bold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Constants.Spacing.medium) {
                if let bestLap = session.bestLapTime {
                    LapStatCard(title: "ベストラップ", value: bestLap.lapTimeString, color: .orange)
                }

                if let avgLap = session.averageLapTime {
                    LapStatCard(title: "平均ラップ", value: avgLap.lapTimeString, color: .blue)
                }

                if !session.laps.isEmpty {
                    let maxSpeed = session.laps.map { $0.maxSpeed }.max() ?? 0
                    LapStatCard(title: "最高速度", value: maxSpeed.speedKmh, color: .red)

                    let avgSpeed = session.laps.map { $0.averageSpeed }.reduce(0, +) / Double(session.laps.count)
                    LapStatCard(title: "平均速度", value: avgSpeed.speedKmh, color: .green)
                }
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Lap Detail Card
struct LapDetailCard: View {
    let lap: LapRecord

    var body: some View {
        HStack(spacing: Constants.Spacing.medium) {
            // ラップ番号
            VStack {
                Text("Lap")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(lap.lapNumber)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                // ラップタイム
                if let lapTime = lap.lapTime {
                    Text(lapTime.lapTimeString)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                } else {
                    Text("未完了")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                // 距離と速度
                HStack(spacing: Constants.Spacing.medium) {
                    HStack(spacing: 4) {
                        Image(systemName: "road.lanes")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(lap.lapDistance.distanceString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "speedometer")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(lap.maxSpeed.speedKmh)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(Constants.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Lap Stat Card
struct LapStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: Constants.Spacing.small) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(Constants.Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    LapTimerHistoryView()
}