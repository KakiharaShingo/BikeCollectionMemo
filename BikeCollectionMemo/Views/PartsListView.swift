import SwiftUI
import CoreData

struct PartsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \PartsMemo.isPurchased, ascending: true),
            NSSortDescriptor(keyPath: \PartsMemo.priority, ascending: true),
            NSSortDescriptor(keyPath: \PartsMemo.createdAt, ascending: false)
        ],
        animation: .default)
    private var partsMemos: FetchedResults<PartsMemo>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bike.name, ascending: true)],
        animation: .default)
    private var bikes: FetchedResults<Bike>
    
    @State private var searchText = ""
    @State private var selectedBike: Bike?
    @State private var showingFilterSheet = false
    @State private var showOnlyUnpurchased = true
    @State private var itemsToDelete: Set<NSManagedObjectID> = []
    @State private var showingBulkDeleteConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var swipeItemsToDelete: IndexSet?
    
    var filteredParts: [PartsMemo] {
        var filtered = Array(partsMemos)
        
        // 購入状態フィルター（削除予定のアイテムは一時的に表示）
        if showOnlyUnpurchased {
            filtered = filtered.filter { !$0.isPurchased || itemsToDelete.contains($0.objectID) }
        }
        
        // バイクフィルター
        if let selectedBike = selectedBike {
            filtered = filtered.filter { $0.bike == selectedBike }
        }
        
        // 検索フィルター
        if !searchText.isEmpty {
            filtered = filtered.filter { memo in
                memo.wrappedPartName.localizedCaseInsensitiveContains(searchText) ||
                memo.wrappedPartNumber.localizedCaseInsensitiveContains(searchText) ||
                memo.wrappedDescription.localizedCaseInsensitiveContains(searchText) ||
                memo.bike?.wrappedName.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return filtered
    }
    
    var totalEstimatedCost: Double {
        filteredParts.filter { !$0.isPurchased }.reduce(0) { $0 + $1.estimatedCost }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !filteredParts.isEmpty {
                    // 統計情報
                    StatsSectionView(
                        totalCost: totalEstimatedCost,
                        itemCount: filteredParts.filter { !$0.isPurchased }.count
                    )
                }
                
                if partsMemos.isEmpty {
                    EmptyPartsView()
                } else {
                    List {
                        ForEach(filteredParts, id: \.objectID) { part in
                            PartsRowView(part: part, itemsToDelete: $itemsToDelete)
                        }
                        .onDelete(perform: confirmSwipeDelete)
                    }
                    .listStyle(PlainListStyle())
                }
                
                // 一斉完了ボタン
                if !itemsToDelete.isEmpty {
                    Button(action: {
                        showingBulkDeleteConfirmation = true
                    }) {
                        HStack {
                            Text("完了")
                            Text("(\(itemsToDelete.count)件)")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()
                }
            }
            .background(Constants.Colors.backgroundFallback)
            .navigationTitle("部品メモ")
            .searchable(text: $searchText, prompt: "部品を検索")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(selectedBike != nil ? Constants.Colors.accentFallback : Constants.Colors.secondaryFallback)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showOnlyUnpurchased.toggle()
                    }) {
                        Image(systemName: showOnlyUnpurchased ? "eye.slash" : "eye")
                            .foregroundColor(Constants.Colors.primaryFallback)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterBikeSheet(bikes: Array(bikes), selectedBike: $selectedBike)
        }
        .alert("部品メモを一斉完了", isPresented: $showingBulkDeleteConfirmation) {
            Button("完了", role: .destructive) {
                bulkCompleteParts()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("\(itemsToDelete.count)件の部品メモを完了しますか？\n購入済みの部品として非表示になります。")
        }
        .alert("部品メモを削除", isPresented: $showingDeleteConfirmation) {
            Button("削除", role: .destructive) {
                if let offsets = swipeItemsToDelete {
                    deleteParts(offsets: offsets)
                }
            }
            Button("キャンセル", role: .cancel) {
                swipeItemsToDelete = nil
            }
        } message: {
            let count = swipeItemsToDelete?.count ?? 0
            Text(count == 1 ? "この部品メモを削除しますか？\nこの操作は取り消せません。" : "\(count)件の部品メモを削除しますか？\nこの操作は取り消せません。")
        }
    }
    
    private func confirmSwipeDelete(offsets: IndexSet) {
        swipeItemsToDelete = offsets
        showingDeleteConfirmation = true
    }
    
    private func deleteParts(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredParts[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Core Data error: \(nsError), \(nsError.userInfo)")
            }
        }
        swipeItemsToDelete = nil
    }
    
    private func bulkCompleteParts() {
        withAnimation {
            // 削除予定リストのアイテムを実際に完了状態に変更
            for objectID in itemsToDelete {
                if let part = try? viewContext.existingObject(with: objectID) as? PartsMemo {
                    part.isPurchased = true
                    part.updatedAt = Date()
                    
                    // 関連するBikeオブジェクトの更新を通知
                    if let bike = part.bike {
                        viewContext.refresh(bike, mergeChanges: true)
                    }
                }
            }
            
            // Core Dataに保存
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Core Data error: \(nsError), \(nsError.userInfo)")
            }
            
            // 削除予定リストをクリア
            itemsToDelete.removeAll()
        }
    }
}

struct StatsSectionView: View {
    let totalCost: Double
    let itemCount: Int
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                Text("予算総額")
                    .font(.subheadline)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                
                Text("¥\(Int(totalCost))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Constants.Spacing.small) {
                Text("未購入")
                    .font(.subheadline)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                
                Text("\(itemCount)件")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding(Constants.Spacing.medium)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Constants.Colors.accentFallback.opacity(0.1), Constants.Colors.primaryFallback.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, Constants.Spacing.medium)
        .padding(.top, Constants.Spacing.small)
    }
}

struct PartsRowView: View {
    let part: PartsMemo
    @Binding var itemsToDelete: Set<NSManagedObjectID>
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var viewModel = PartsMemoViewModel()
    @State private var showingEditParts = false
    
    var priorityColor: Color {
        switch part.wrappedPriority {
        case "高":
            return .red
        case "中":
            return .orange
        case "低":
            return .green
        default:
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: Constants.Spacing.medium) {
            // 優先度インジケーター
            RoundedRectangle(cornerRadius: 2)
                .fill(priorityColor)
                .frame(width: 4, height: 60)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                HStack(alignment: .center) {
                    Text(part.wrappedPartName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(part.isPurchased ? Constants.Colors.secondaryFallback : .black)
                        .strikethrough(part.isPurchased)
                    
                    Spacer()
                    
                    Text(part.estimatedCostString)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(part.isPurchased ? Constants.Colors.secondaryFallback : .blue)
                        .strikethrough(part.isPurchased)
                }
                
                if !part.wrappedPartNumber.isEmpty {
                    Text("品番: \(part.wrappedPartNumber)")
                        .font(.caption)
                        .foregroundColor(.black)
                }
                
                if let bike = part.bike {
                    HStack {
                        Image(systemName: "motorcycle")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.secondaryFallback)
                        
                        Text(bike.wrappedName)
                            .font(.caption)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Text(part.wrappedPriority)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(priorityColor)
                    }
                }
                
                if !part.wrappedDescription.isEmpty {
                    Text(part.wrappedDescription)
                        .font(.caption)
                        .foregroundColor(.black)
                        .lineLimit(2)
                }
            }
            
            VStack(spacing: Constants.Spacing.extraSmall) {
                Button(action: {
                    togglePurchaseStatus()
                }) {
                    Image(systemName: (part.isPurchased || itemsToDelete.contains(part.objectID)) ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor((part.isPurchased || itemsToDelete.contains(part.objectID)) ? .green : Constants.Colors.secondaryFallback)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 個別の完了ボタンは削除
            }
        }
        .padding(.vertical, Constants.Spacing.small)
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditParts = true
        }
        .sheet(isPresented: $showingEditParts) {
            EditPartsView(partsMemo: part, viewModel: viewModel)
        }
    }
    
    private func togglePurchaseStatus() {
        withAnimation {
            if !part.isPurchased {
                // 未購入の場合、削除予定リストに追加するだけ（実際のステータスは変更しない）
                if itemsToDelete.contains(part.objectID) {
                    itemsToDelete.remove(part.objectID)
                } else {
                    itemsToDelete.insert(part.objectID)
                }
            } else {
                // 既に購入済みの場合はトグルしない
                return
            }
        }
    }
}

struct EmptyPartsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: Constants.Spacing.large) {
            Image(systemName: "gear")
                .font(.system(size: 80))
                .foregroundColor(Constants.Colors.secondaryFallback)
            
            VStack(alignment: .center, spacing: Constants.Spacing.medium) {
                Text("部品メモがありません")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Text("バイクの詳細画面から\n必要な部品をメモしてください")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Constants.Colors.secondaryFallback)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Constants.Colors.backgroundFallback)
    }
}

#Preview {
    PartsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}