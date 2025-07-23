import SwiftUI

struct BikePartsListView: View {
    let bike: Bike
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = PartsMemoViewModel()
    
    @State private var searchText = ""
    @State private var showingAddParts = false
    @State private var selectedFilter = "全て"
    @State private var selectedPriority = "全て"
    @State private var showingDeleteConfirmation = false
    @State private var itemsToDelete: IndexSet?
    
    private let filters = ["全て", "未購入", "購入済み"]
    private let priorities = ["全て", "高", "中", "低"]
    
    private var filteredParts: [PartsMemo] {
        var filtered = bike.partsMemosArray
        
        // 購入状態フィルター
        switch selectedFilter {
        case "未購入":
            filtered = filtered.filter { !$0.isPurchased }
        case "購入済み":
            filtered = filtered.filter { $0.isPurchased }
        default:
            break
        }
        
        // 優先度フィルター
        if selectedPriority != "全て" {
            filtered = filtered.filter { $0.wrappedPriority == selectedPriority }
        }
        
        // 検索フィルター
        if !searchText.isEmpty {
            filtered = filtered.filter { part in
                part.wrappedPartName.localizedCaseInsensitiveContains(searchText) ||
                part.wrappedPartNumber.localizedCaseInsensitiveContains(searchText) ||
                part.wrappedDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    private var totalEstimatedCost: Double {
        filteredParts.filter { !$0.isPurchased }.reduce(0) { $0 + $1.estimatedCost }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 統計情報
            if !filteredParts.isEmpty {
                PartsStatsSectionView(
                    totalCount: filteredParts.count,
                    unpurchasedCount: filteredParts.filter { !$0.isPurchased }.count,
                    totalCost: totalEstimatedCost
                )
            }
            
            // フィルターセクション
            FilterSectionView(
                selectedFilter: $selectedFilter,
                selectedPriority: $selectedPriority,
                filters: filters,
                priorities: priorities
            )
            
            // 部品リスト
            if filteredParts.isEmpty {
                EmptyPartsListView(showingAddParts: $showingAddParts)
            } else {
                List {
                    ForEach(filteredParts, id: \.objectID) { part in
                        PartsDetailRowView(part: part, viewModel: viewModel)
                    }
                    .onDelete(perform: confirmDelete)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("\(bike.wrappedName)の部品")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "部品を検索")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddParts = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(Constants.Colors.primaryFallback)
                }
            }
        }
        .sheet(isPresented: $showingAddParts) {
            AddPartsView(bike: bike, viewModel: viewModel)
        }
        .alert("部品メモを削除", isPresented: $showingDeleteConfirmation) {
            Button("削除", role: .destructive) {
                if let offsets = itemsToDelete {
                    deleteParts(offsets: offsets)
                }
            }
            Button("キャンセル", role: .cancel) {
                itemsToDelete = nil
            }
        } message: {
            let count = itemsToDelete?.count ?? 0
            Text(count == 1 ? "この部品メモを削除しますか？\nこの操作は取り消せません。" : "\(count)件の部品メモを削除しますか？\nこの操作は取り消せません。")
        }
    }
    
    private func confirmDelete(offsets: IndexSet) {
        itemsToDelete = offsets
        showingDeleteConfirmation = true
    }
    
    private func deleteParts(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredParts[$0] }.forEach { part in
                viewModel.deletePartsMemo(part)
            }
        }
        itemsToDelete = nil
    }
}

struct PartsStatsSectionView: View {
    let totalCount: Int
    let unpurchasedCount: Int
    let totalCost: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                Text("総件数")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                
                Text("\(totalCount)件")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .center, spacing: Constants.Spacing.extraSmall) {
                Text("未購入")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                
                Text("\(unpurchasedCount)件")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Constants.Spacing.extraSmall) {
                Text("予算総額")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                
                Text("¥\(Int(totalCost))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
        .padding(.horizontal, Constants.Spacing.medium)
        .padding(.top, Constants.Spacing.small)
    }
}

struct FilterSectionView: View {
    @Binding var selectedFilter: String
    @Binding var selectedPriority: String
    let filters: [String]
    let priorities: [String]
    
    var body: some View {
        VStack(spacing: Constants.Spacing.small) {
            // 購入状態フィルター
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Constants.Spacing.small) {
                    ForEach(filters, id: \.self) { filter in
                        Button(action: {
                            selectedFilter = filter
                        }) {
                            Text(filter)
                                .font(.caption)
                                .padding(.horizontal, Constants.Spacing.medium)
                                .padding(.vertical, Constants.Spacing.small)
                                .background(
                                    selectedFilter == filter ?
                                    Constants.Colors.primaryFallback :
                                    Constants.Colors.surfaceFallback
                                )
                                .foregroundColor(
                                    selectedFilter == filter ?
                                    .white :
                                    .black
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, Constants.Spacing.medium)
            }
            
            // 優先度フィルター
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Constants.Spacing.small) {
                    ForEach(priorities, id: \.self) { priority in
                        Button(action: {
                            selectedPriority = priority
                        }) {
                            HStack(spacing: Constants.Spacing.extraSmall) {
                                if priority != "全て" {
                                    Circle()
                                        .fill(priorityColor(for: priority))
                                        .frame(width: 8, height: 8)
                                }
                                Text(priority)
                            }
                            .font(.caption)
                            .padding(.horizontal, Constants.Spacing.medium)
                            .padding(.vertical, Constants.Spacing.small)
                            .background(
                                selectedPriority == priority ?
                                Constants.Colors.accentFallback :
                                Constants.Colors.surfaceFallback
                            )
                            .foregroundColor(
                                selectedPriority == priority ?
                                .white :
                                .black
                            )
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, Constants.Spacing.medium)
            }
        }
        .padding(.vertical, Constants.Spacing.small)
    }
    
    private func priorityColor(for priority: String) -> Color {
        switch priority {
        case "高": return .red
        case "中": return .orange
        case "低": return .green
        default: return .gray
        }
    }
}

struct PartsDetailRowView: View {
    let part: PartsMemo
    @ObservedObject var viewModel: PartsMemoViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEditParts = false
    @State private var showingDeleteConfirmation = false
    
    var priorityColor: Color {
        switch part.wrappedPriority {
        case "高": return .red
        case "中": return .orange
        case "低": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: Constants.Spacing.medium) {
            // 優先度インジケーター
            RoundedRectangle(cornerRadius: 2)
                .fill(priorityColor)
                .frame(width: 4, height: 80)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                HStack {
                    Text(part.wrappedPartName)
                        .font(.headline)
                        .foregroundColor(part.isPurchased ? Constants.Colors.secondaryFallback : .primary)
                        .strikethrough(part.isPurchased)
                    
                    Spacer()
                    
                    Text(part.estimatedCostString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(part.isPurchased ? Constants.Colors.secondaryFallback : .blue)
                        .strikethrough(part.isPurchased)
                }
                
                if !part.wrappedPartNumber.isEmpty {
                    Text("品番: \(part.wrappedPartNumber)")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text(part.wrappedPriority)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(priorityColor)
                    
                    Spacer()
                    
                    if part.isPurchased {
                        Text("購入済み")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                if !part.wrappedDescription.isEmpty {
                    Text(part.wrappedDescription)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
            }
            
            VStack(spacing: Constants.Spacing.extraSmall) {
                Button(action: {
                    togglePurchaseStatus()
                }) {
                    Image(systemName: part.isPurchased ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(part.isPurchased ? .green : Constants.Colors.secondaryFallback)
                }
                .buttonStyle(PlainButtonStyle())
                
                if part.isPurchased {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Text("完了")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
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
        .alert("部品メモを削除", isPresented: $showingDeleteConfirmation) {
            Button("削除", role: .destructive) {
                deletePart()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この部品メモを削除しますか？\n購入済みの部品を完了として削除します。")
        }
    }
    
    private func togglePurchaseStatus() {
        withAnimation {
            viewModel.togglePurchaseStatus(part)
        }
    }
    
    private func deletePart() {
        withAnimation {
            viewModel.deletePartsMemo(part)
        }
    }
}

struct EmptyPartsListView: View {
    @Binding var showingAddParts: Bool
    
    var body: some View {
        VStack(spacing: Constants.Spacing.large) {
            Image(systemName: "gear")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.secondaryFallback)
            
            VStack(spacing: Constants.Spacing.small) {
                Text("部品メモがありません")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("必要な部品を\nメモしてみましょう")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Constants.Colors.secondaryFallback)
            }
            
            Button(action: {
                showingAddParts = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("部品メモを追加")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, Constants.Spacing.large)
                .padding(.vertical, Constants.Spacing.medium)
                .background(Constants.Colors.primaryFallback)
                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Constants.Colors.backgroundFallback)
    }
}

#Preview {
    NavigationView {
        BikePartsListView(
            bike: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is Bike }) as! Bike
        )
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}