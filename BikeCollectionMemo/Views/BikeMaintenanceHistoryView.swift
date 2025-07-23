import SwiftUI

struct BikeMaintenanceHistoryView: View {
    let bike: Bike
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = MaintenanceRecordViewModel()
    
    @State private var searchText = ""
    @State private var showingAddMaintenance = false
    @State private var selectedCategory = "全て"
    @State private var showingDeleteConfirmation = false
    @State private var itemsToDelete: IndexSet?
    
    private var categories: [String] {
        var cats = ["全て"]
        cats.append(contentsOf: Constants.MaintenanceCategories.getAllCategories())
        return cats
    }
    
    private var filteredRecords: [MaintenanceRecord] {
        var filtered = bike.maintenanceRecordsArray
        
        // カテゴリーフィルター
        if selectedCategory != "全て" {
            filtered = filtered.filter { $0.wrappedCategory == selectedCategory }
        }
        
        // 検索フィルター
        if !searchText.isEmpty {
            filtered = filtered.filter { record in
                record.wrappedCategory.localizedCaseInsensitiveContains(searchText) ||
                record.wrappedSubcategory.localizedCaseInsensitiveContains(searchText) ||
                record.wrappedItem.localizedCaseInsensitiveContains(searchText) ||
                record.wrappedNotes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    private var totalCost: Double {
        filteredRecords.reduce(0) { $0 + $1.cost }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 統計情報
            if !filteredRecords.isEmpty {
                StatisticsSectionView(
                    recordCount: filteredRecords.count,
                    totalCost: totalCost
                )
            }
            
            // カテゴリーフィルター
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Constants.Spacing.small) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, Constants.Spacing.medium)
                                .padding(.vertical, Constants.Spacing.small)
                                .background(
                                    selectedCategory == category ?
                                    Constants.Colors.accentFallback :
                                    Constants.Colors.surfaceFallback
                                )
                                .foregroundColor(
                                    selectedCategory == category ?
                                    .white :
                                    Constants.Colors.onSurface
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, Constants.Spacing.medium)
                .padding(.vertical, Constants.Spacing.small)
            }
            
            // 整備記録リスト
            if filteredRecords.isEmpty {
                EmptyMaintenanceHistoryView(showingAddMaintenance: $showingAddMaintenance)
            } else {
                List {
                    ForEach(filteredRecords, id: \.objectID) { record in
                        NavigationLink(destination: MaintenanceRecordDetailView(record: record)) {
                            MaintenanceRecordRowView(record: record)
                        }
                    }
                    .onDelete(perform: confirmDelete)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("\(bike.wrappedName)の整備履歴")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "整備記録を検索")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddMaintenance = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(Constants.Colors.primaryFallback)
                }
            }
        }
        .sheet(isPresented: $showingAddMaintenance) {
            AddMaintenanceRecordView(bike: bike, viewModel: viewModel)
        }
        .alert("整備記録を削除", isPresented: $showingDeleteConfirmation) {
            Button("削除", role: .destructive) {
                if let offsets = itemsToDelete {
                    deleteRecords(offsets: offsets)
                }
            }
            Button("キャンセル", role: .cancel) {
                itemsToDelete = nil
            }
        } message: {
            let count = itemsToDelete?.count ?? 0
            Text(count == 1 ? "この整備記録を削除しますか？\nこの操作は取り消せません。" : "\(count)件の整備記録を削除しますか？\nこの操作は取り消せません。")
        }
    }
    
    private func confirmDelete(offsets: IndexSet) {
        itemsToDelete = offsets
        showingDeleteConfirmation = true
    }
    
    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredRecords[$0] }.forEach { record in
                viewModel.deleteMaintenanceRecord(record)
            }
        }
        itemsToDelete = nil
    }
}

struct StatisticsSectionView: View {
    let recordCount: Int
    let totalCost: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                Text("記録件数")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                
                Text("\(recordCount)件")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Constants.Colors.primaryFallback)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Constants.Spacing.extraSmall) {
                Text("総費用")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                
                Text("¥\(Int(totalCost))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Constants.Colors.accentFallback)
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
        .padding(.horizontal, Constants.Spacing.medium)
        .padding(.top, Constants.Spacing.small)
    }
}

struct EmptyMaintenanceHistoryView: View {
    @Binding var showingAddMaintenance: Bool
    
    var body: some View {
        VStack(spacing: Constants.Spacing.large) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.secondaryFallback)
            
            VStack(spacing: Constants.Spacing.small) {
                Text("整備記録がありません")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("最初の整備記録を\n追加してみましょう")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Constants.Colors.secondaryFallback)
            }
            
            Button(action: {
                showingAddMaintenance = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("整備記録を追加")
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
        BikeMaintenanceHistoryView(
            bike: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is Bike }) as! Bike
        )
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}