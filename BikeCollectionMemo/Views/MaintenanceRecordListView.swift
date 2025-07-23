import SwiftUI
import CoreData

struct MaintenanceRecordListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MaintenanceRecord.date, ascending: false)],
        animation: .default)
    private var maintenanceRecords: FetchedResults<MaintenanceRecord>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bike.name, ascending: true)],
        animation: .default)
    private var bikes: FetchedResults<Bike>
    
    @State private var searchText = ""
    @State private var selectedBike: Bike?
    @State private var showingFilterSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var itemsToDelete: IndexSet?
    
    var filteredRecords: [MaintenanceRecord] {
        var filtered = Array(maintenanceRecords)
        
        // バイクフィルター
        if let selectedBike = selectedBike {
            filtered = filtered.filter { $0.bike == selectedBike }
        }
        
        // 検索フィルター
        if !searchText.isEmpty {
            filtered = filtered.filter { record in
                record.wrappedCategory.localizedCaseInsensitiveContains(searchText) ||
                record.wrappedSubcategory.localizedCaseInsensitiveContains(searchText) ||
                record.wrappedItem.localizedCaseInsensitiveContains(searchText) ||
                record.wrappedNotes.localizedCaseInsensitiveContains(searchText) ||
                record.bike?.wrappedName.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if maintenanceRecords.isEmpty {
                    EmptyMaintenanceView()
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
            .navigationTitle("整備記録")
            .searchable(text: $searchText, prompt: "整備記録を検索")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(selectedBike != nil ? Constants.Colors.accentFallback : Constants.Colors.secondaryFallback)
                    }
                }
            }
            .background(Constants.Colors.backgroundFallback)
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterBikeSheet(bikes: Array(bikes), selectedBike: $selectedBike)
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
            offsets.map { filteredRecords[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // エラーハンドリング
                let nsError = error as NSError
                print("Core Data error: \(nsError), \(nsError.userInfo)")
            }
        }
        itemsToDelete = nil
    }
}

struct MaintenanceRecordRowView: View {
    let record: MaintenanceRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            HStack(alignment: .center) {
                // 写真サムネイル
                if let photos = record.photos as? Set<Photo>,
                   let firstPhoto = photos.sorted(by: { $0.sortOrder < $1.sortOrder }).first,
                   let imageData = firstPhoto.imageData,
                   let uiImage = UIImage(data: imageData) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                                    .stroke(Constants.Colors.primaryFallback.opacity(0.2), lineWidth: 1)
                            )
                        
                        // 複数写真の場合は件数表示
                        if photos.count > 1 {
                            Text("+\(photos.count - 1)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(2)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                                .padding(2)
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                        .fill(Constants.Colors.surfaceFallback)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.title3)
                                .foregroundColor(Constants.Colors.secondaryFallback)
                        )
                }
                
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    Text(record.wrappedCategory)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !record.wrappedSubcategory.isEmpty {
                        Text(record.wrappedSubcategory)
                            .font(.body)
                            .foregroundColor(Constants.Colors.secondaryFallback)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Constants.Spacing.small) {
                    Text(record.costString)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Text(record.dateString)
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.secondaryFallback)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            
            Text(record.wrappedItem)
                .font(.body)
                .foregroundColor(.primary)
            
            if let bike = record.bike {
                HStack {
                    Image(systemName: "motorcycle")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.secondaryFallback)
                    
                    Text(bike.wrappedName)
                        .font(.caption)
                        .foregroundColor(Constants.Colors.secondaryFallback)
                    
                    Spacer()
                    
                    if record.mileage > 0 {
                        Text("\(record.mileage)km")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if !record.wrappedNotes.isEmpty {
                Text(record.wrappedNotes)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, Constants.Spacing.extraSmall)
    }
}

struct EmptyMaintenanceView: View {
    var body: some View {
        VStack(alignment: .center, spacing: Constants.Spacing.large) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 80))
                .foregroundColor(Constants.Colors.secondaryFallback)
            
            VStack(alignment: .center, spacing: Constants.Spacing.medium) {
                Text("整備記録がありません")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("バイクの詳細画面から\n整備記録を追加してください")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Constants.Colors.secondaryFallback)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Constants.Colors.backgroundFallback)
    }
}

struct FilterBikeSheet: View {
    let bikes: [Bike]
    @Binding var selectedBike: Bike?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    selectedBike = nil
                    dismiss()
                }) {
                    HStack {
                        Text("すべてのバイク")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedBike == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(Constants.Colors.accentFallback)
                        }
                    }
                }
                
                ForEach(bikes, id: \.objectID) { bike in
                    Button(action: {
                        selectedBike = bike
                        dismiss()
                    }) {
                        HStack {
                            Text(bike.wrappedName)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedBike == bike {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Constants.Colors.accentFallback)
                            }
                        }
                    }
                }
            }
            .navigationTitle("バイクでフィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MaintenanceRecordListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}