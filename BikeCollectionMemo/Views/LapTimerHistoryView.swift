import SwiftUI

struct LapTimerHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var lapTimerManager = LapTimerManager.shared
    
    @State private var selectedSession: LapTimeSession?
    @State private var showingSessionDetail = false
    @State private var searchText = ""
    @State private var selectedCourse: TimingCourse?
    
    var filteredSessions: [LapTimeSession] {
        var sessions = lapTimerManager.getSavedSessions()
        
        if !searchText.isEmpty {
            sessions = sessions.filter { session in
                session.courseName.localizedCaseInsensitiveContains(searchText) ||
                (session.bikeName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if let course = selectedCourse {
            sessions = sessions.filter { $0.courseId == course.id }
        }
        
        return sessions
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索とフィルター
                searchAndFilterSection
                
                // セッション一覧
                if filteredSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
            .navigationTitle("ラップタイマー履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("すべて表示") {
                            selectedCourse = nil
                        }
                        
                        ForEach(lapTimerManager.getSavedCourses(), id: \.id) { course in
                            Button(course.name) {
                                selectedCourse = course
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingSessionDetail) {
                if let session = selectedSession {
                    LapTimerSessionDetailView(session: session)
                }
            }
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: Constants.Spacing.small) {
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("コース名やバイク名で検索", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button("クリア") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, Constants.Spacing.small)
            .padding(.vertical, Constants.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            
            // フィルター表示
            if let course = selectedCourse {
                HStack {
                    Text("フィルター: \(course.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("クリア") {
                        selectedCourse = nil
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, Constants.Spacing.small)
            }
        }
        .padding(.horizontal, Constants.Spacing.medium)
        .padding(.vertical, Constants.Spacing.small)
    }
    
    // MARK: - Sessions List
    private var sessionsList: some View {
        List(filteredSessions, id: \.id) { session in
            SessionRowView(session: session) {
                selectedSession = session
                showingSessionDetail = true
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: Constants.Spacing.large) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("履歴がありません")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("ラップタイマーで計測を開始すると、ここに履歴が表示されます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.Spacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Session Row View
struct SessionRowView: View {
    let session: LapTimeSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                // ヘッダー情報
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.courseName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if let bikeName = session.bikeName {
                            Text(bikeName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(session.startTime, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(session.startTime, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 統計情報
                HStack(spacing: Constants.Spacing.medium) {
                    StatisticItem(
                        icon: "number",
                        title: "ラップ",
                        value: "\(session.totalLaps)",
                        color: .blue
                    )
                    
                    if let bestLap = session.bestLapTime {
                        StatisticItem(
                            icon: "timer",
                            title: "ベスト",
                            value: bestLap.lapTimeString,
                            color: .green
                        )
                    }
                    
                    if let avgLap = session.averageLapTime {
                        StatisticItem(
                            icon: "clock",
                            title: "平均",
                            value: avgLap.lapTimeString,
                            color: .orange
                        )
                    }
                    
                    StatisticItem(
                        icon: "location",
                        title: "距離",
                        value: session.totalDistance.distanceString,
                        color: .purple
                    )
                }
            }
            .padding(.vertical, Constants.Spacing.small)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Statistic Item
struct StatisticItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Session Detail View
struct LapTimerSessionDetailView: View {
    let session: LapTimeSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                    // セッション情報
                    sessionInfoSection
                    
                    // ラップ詳細
                    lapsSection
                    
                    // 統計情報
                    statisticsSection
                }
                .padding(Constants.Spacing.medium)
            }
            .navigationTitle("セッション詳細")
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
    
    private var sessionInfoSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("セッション情報")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                InfoRow(title: "コース", value: session.courseName)
                if let bikeName = session.bikeName {
                    InfoRow(title: "バイク", value: bikeName)
                }
                InfoRow(title: "開始時刻", value: session.startTime.formatted(date: .abbreviated, time: .shortened))
                if let endTime = session.endTime {
                    InfoRow(title: "終了時刻", value: endTime.formatted(date: .abbreviated, time: .shortened))
                }
                InfoRow(title: "総時間", value: session.duration.lapTimeString)
                InfoRow(title: "総距離", value: session.totalDistance.distanceString)
            }
            .padding(Constants.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private var lapsSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("ラップ詳細")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: Constants.Spacing.small) {
                ForEach(session.laps, id: \.id) { lap in
                    LapDetailRow(lap: lap)
                }
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("統計情報")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Constants.Spacing.small) {
                if let bestLap = session.bestLapTime {
                    StatisticCard(
                        title: "ベストラップ",
                        value: bestLap.lapTimeString,
                        icon: "timer",
                        color: .green
                    )
                }
                
                if let avgLap = session.averageLapTime {
                    StatisticCard(
                        title: "平均ラップ",
                        value: avgLap.lapTimeString,
                        icon: "clock",
                        color: .orange
                    )
                }
                
                StatisticCard(
                    title: "総ラップ数",
                    value: "\(session.totalLaps)",
                    icon: "number",
                    color: .blue
                )
                
                StatisticCard(
                    title: "総距離",
                    value: session.totalDistance.distanceString,
                    icon: "location",
                    color: .purple
                )
            }
        }
    }
}

// MARK: - Supporting Views
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct LapDetailRow: View {
    let lap: LapRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ラップ \(lap.lapNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let lapTime = lap.lapTime {
                    Text(lapTime.lapTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(lap.maxSpeed.speedKmh)
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text(lap.lapDistance.distanceString)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(Constants.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                .fill(Color(.systemGray6))
        )
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Constants.Spacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Constants.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    LapTimerHistoryView()
}