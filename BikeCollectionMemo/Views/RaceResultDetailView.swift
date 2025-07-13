import SwiftUI
import CoreData

struct RaceResultDetailView: View {
    @ObservedObject var raceResult: RaceResult
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = RaceResultViewModel()
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日（E）"
        formatter.locale = Locale(identifier: "ja_JP")
        return raceResult.raceDate.map { formatter.string(from: $0) } ?? ""
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // ヘッダー情報
                    VStack(spacing: Constants.Spacing.medium) {
                        // 順位表示
                        HStack {
                            Spacer()
                            VStack {
                                Text("\(raceResult.position)")
                                    .font(.system(size: 60, weight: .bold))
                                    .foregroundColor(viewModel.getPositionColor(raceResult.position, totalParticipants: raceResult.totalParticipants))
                                
                                Text("位 / \(raceResult.totalParticipants)台")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Constants.Colors.surfaceFallback)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
                        
                        // レース名とカテゴリー
                        VStack(spacing: Constants.Spacing.small) {
                            Text(raceResult.raceName ?? "")
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            if let category = raceResult.category, !category.isEmpty {
                                Text(category)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    // 詳細情報
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Constants.Spacing.medium) {
                        
                        DetailInfoCard(title: "開催日", value: formattedDate, icon: "calendar")
                        DetailInfoCard(title: "コース", value: raceResult.track ?? "", icon: "location")
                        
                        if let bestLap = raceResult.bestLapTime, !bestLap.isEmpty {
                            DetailInfoCard(title: "ベストラップ", value: bestLap, icon: "stopwatch")
                        }
                        
                        if let totalTime = raceResult.totalTime, !totalTime.isEmpty {
                            DetailInfoCard(title: "総合タイム", value: totalTime, icon: "timer")
                        }
                        
                        if let weather = raceResult.weather, !weather.isEmpty {
                            DetailInfoCard(title: "天候", value: weather, icon: "cloud.sun")
                        }
                        
                        if let temperature = raceResult.temperature, !temperature.isEmpty {
                            DetailInfoCard(title: "気温", value: temperature, icon: "thermometer")
                        }
                    }
                    
                    // 使用バイク
                    if let bikeName = raceResult.bikeName, !bikeName.isEmpty {
                        RaceDetailSection(title: "使用バイク", content: bikeName, icon: "bicycle")
                    }
                    
                    // メモ・感想
                    if let notes = raceResult.notes, !notes.isEmpty {
                        RaceDetailSection(title: "メモ・感想", content: notes, icon: "note.text")
                    }
                    
                    // 写真
                    if let photos = raceResult.photos as? Set<RacePhoto>, !photos.isEmpty {
                        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                            HStack {
                                Image(systemName: "photo")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Text("写真")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            let sortedPhotos = photos.sorted { $0.sortOrder < $1.sortOrder }
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: Constants.Spacing.small) {
                                ForEach(Array(sortedPhotos.enumerated()), id: \.element.id) { index, photo in
                                    if let imageData = photo.imageData,
                                       let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
                                    }
                                }
                            }
                        }
                        .padding(Constants.Spacing.medium)
                        .background(Constants.Colors.surfaceFallback)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                    }
                }
                .padding(Constants.Spacing.medium)
            }
            .navigationTitle("レース詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingEditView = true
                        }) {
                            Label("編集", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditRaceResultView(raceResult: raceResult)
                .environment(\.managedObjectContext, viewContext)
        }
        .onChange(of: showingEditView) { wasShowing, isShowing in
            // 編集画面が閉じられた時にCore Dataを更新
            if wasShowing && !isShowing {
                viewContext.refreshAllObjects()
                // 親ビューに変更を通知するためにオブジェクトを更新
                viewContext.refresh(raceResult, mergeChanges: true)
            }
        }
        .alert("レース記録を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                viewModel.deleteRaceResult(raceResult)
                dismiss()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この操作は取り消せません。")
        }
    }
}

struct DetailInfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: Constants.Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
    }
}

struct RaceDetailSection: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            Text(content)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleRaceResult = RaceResult(context: context)
    sampleRaceResult.id = UUID()
    sampleRaceResult.raceName = "全日本エンデューロ選手権"
    sampleRaceResult.raceDate = Date()
    sampleRaceResult.track = "スポーツランドSUGO"
    sampleRaceResult.category = "エンデューロ"
    sampleRaceResult.position = 3
    sampleRaceResult.totalParticipants = 25
    sampleRaceResult.bestLapTime = "12:34.56"
    sampleRaceResult.totalTime = "2:45:23"
    sampleRaceResult.weather = "曇り"
    sampleRaceResult.temperature = "22℃"
    sampleRaceResult.bikeName = "CRF250X"
    sampleRaceResult.notes = "今回は3位入賞！泥濘セクションで苦戦したが、岩場は上手く走れた。次回はもっとタイムを詰めたい。"
    
    return RaceResultDetailView(raceResult: sampleRaceResult)
        .environment(\.managedObjectContext, context)
}