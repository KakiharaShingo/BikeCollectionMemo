import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct RaceResultListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: RaceResult.entity(),
        sortDescriptors: [
            NSSortDescriptor(key: "createdAt", ascending: false),
            NSSortDescriptor(key: "id", ascending: false)
        ],
        predicate: nil,
        animation: .default)
    private var raceResults: FetchedResults<RaceResult>
    
    @StateObject private var viewModel = RaceResultViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingAddView = false
    @State private var selectedResult: RaceResult?
    @State private var showingDetailView = false
    @State private var refreshTrigger = false
    @State private var showingExportView = false
    @State private var showingUpgradePrompt = false
    @State private var showingDeleteConfirmation = false
    @State private var itemsToDelete: IndexSet?
    
    var body: some View {
        NavigationStack {
            Group {
                if raceResults.isEmpty {
                    EmptyRaceResultView {
                        if canAddRaceResult() {
                            showingAddView = true
                        } else {
                            showingUpgradePrompt = true
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        // 制限表示
                        if !subscriptionManager.isSubscribed && raceResults.count >= 25 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("レース記録: \(raceResults.count)/30件")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Spacer()
                                if raceResults.count >= 30 {
                                    Text("上限に達しました")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                        }
                        
                        List {
                            ForEach(raceResults, id: \.id) { raceResult in
                            RaceResultRowView(raceResult: raceResult, viewModel: viewModel)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedResult = raceResult
                                    showingDetailView = true
                                }
                        }
                        .onDelete(perform: confirmDelete)
                        }
                    }
                }
            }
            .navigationTitle("レース記録")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !raceResults.isEmpty {
                        Button(action: {
                            if subscriptionManager.isSubscribed {
                                showingExportView = true
                            } else {
                                showingUpgradePrompt = true
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(subscriptionManager.isSubscribed ? .primary : .gray)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if canAddRaceResult() {
                            showingAddView = true
                        } else {
                            showingUpgradePrompt = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddRaceResultView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingDetailView) {
                if let selectedResult = selectedResult {
                    RaceResultDetailView(raceResult: selectedResult)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .sheet(isPresented: $showingUpgradePrompt) {
                RaceUpgradePromptView()
            }
            .onChange(of: showingAddView) { wasShowing, isShowing in
                // 新規追加画面が閉じられた時にリストを更新
                if wasShowing && !isShowing {
                    refreshList()
                }
            }
            .onChange(of: showingDetailView) { wasShowing, isShowing in
                // 詳細画面が閉じられた時にリストを更新
                if wasShowing && !isShowing {
                    refreshList()
                    selectedResult = nil
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                // Core Dataの変更があった時に強制更新
                refreshList()
            }
            .fileExporter(
                isPresented: $showingExportView,
                document: CSVDocument(csvContent: generateCSV()),
                contentType: UTType.commaSeparatedText,
                defaultFilename: "レース記録_\(DateFormatter.fileNameFormatter.string(from: Date()))"
            ) { result in
                switch result {
                case .success(let url):
                    print("CSV exported to: \(url)")
                case .failure(let error):
                    print("Export failed: \(error)")
                }
            }
            .alert("レース記録を削除", isPresented: $showingDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    if let offsets = itemsToDelete {
                        deleteResults(offsets: offsets)
                    }
                }
                Button("キャンセル", role: .cancel) {
                    itemsToDelete = nil
                }
            } message: {
                let count = itemsToDelete?.count ?? 0
                Text(count == 1 ? "このレース記録を削除しますか？\nこの操作は取り消せません。" : "\(count)件のレース記録を削除しますか？\nこの操作は取り消せません。")
            }
            .background(Constants.Colors.backgroundFallback)
        }
    }
    
    private func confirmDelete(offsets: IndexSet) {
        itemsToDelete = offsets
        showingDeleteConfirmation = true
    }
    
    private func deleteResults(offsets: IndexSet) {
        withAnimation {
            offsets.map { raceResults[$0] }.forEach { raceResult in
                viewModel.deleteRaceResult(raceResult)
            }
        }
        itemsToDelete = nil
    }
    
    private func refreshList() {
        // Core Dataの変更を強制的に反映
        viewContext.refreshAllObjects()
        
        // UI更新をトリガー
        DispatchQueue.main.async {
            refreshTrigger.toggle()
        }
    }
    
    private func generateCSV() -> String {
        let header = "開催日,レース名,コース,カテゴリー,順位,総参加台数,ベストラップ,総合タイム,天候,気温,使用バイク,メモ"
        
        let rows = raceResults.map { raceResult in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            let dateString = raceResult.raceDate.map { dateFormatter.string(from: $0) } ?? ""
            
            return [
                dateString,
                escapeCSVField(raceResult.raceName ?? ""),
                escapeCSVField(raceResult.track ?? ""),
                escapeCSVField(raceResult.category ?? ""),
                raceResult.position == 0 ? "DNF" : "\(raceResult.position)",
                "\(raceResult.totalParticipants)",
                escapeCSVField(raceResult.bestLapTime ?? ""),
                escapeCSVField(raceResult.totalTime ?? ""),
                escapeCSVField(raceResult.weather ?? ""),
                escapeCSVField(raceResult.temperature ?? ""),
                escapeCSVField(raceResult.bikeName ?? ""),
                escapeCSVField(raceResult.notes ?? "")
            ].joined(separator: ",")
        }
        
        return ([header] + rows).joined(separator: "\n")
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
    
    private func canAddRaceResult() -> Bool {
        return subscriptionManager.isSubscribed || raceResults.count < 30
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var csvContent: String
    
    init(csvContent: String) {
        self.csvContent = csvContent
    }
    
    init(configuration: ReadConfiguration) throws {
        csvContent = ""
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = csvContent.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}

struct RaceResultRowView: View {
    @ObservedObject var raceResult: RaceResult
    let viewModel: RaceResultViewModel
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return raceResult.raceDate.map { formatter.string(from: $0) } ?? ""
    }
    
    var body: some View {
        HStack(spacing: Constants.Spacing.medium) {
            // 順位表示
            VStack {
                Text("\(raceResult.position)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.getPositionColor(raceResult.position, totalParticipants: raceResult.totalParticipants))
                
                Text("位")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                // レース名
                Text(raceResult.raceName ?? "")
                    .font(.headline)
                    .lineLimit(1)
                
                // コース名
                Text(raceResult.track ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    // カテゴリー
                    if let category = raceResult.category, !category.isEmpty {
                        Text(category)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                            .frame(maxWidth: 120)
                    }
                    
                    Spacer()
                    
                    // 日付
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // ベストラップ
            if let bestLap = raceResult.bestLapTime, !bestLap.isEmpty {
                VStack(alignment: .trailing) {
                    Text("ベストラップ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(bestLap)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.vertical, Constants.Spacing.small)
    }
}

struct EmptyRaceResultView: View {
    let onAddTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // アイコン
            Image(systemName: "flag.checkered")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 15) {
                Text("レース記録がありません")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("レースの結果を記録して、\n成績や成長を追跡しましょう")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Button(action: onAddTapped) {
                HStack {
                    Image(systemName: "plus")
                    Text("最初のレース記録を追加")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
            }
            .padding(.horizontal, Constants.Spacing.large)
        }
        .padding(Constants.Spacing.large)
    }
}

#Preview {
    RaceResultListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}