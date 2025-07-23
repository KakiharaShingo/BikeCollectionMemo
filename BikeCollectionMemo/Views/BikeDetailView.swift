import SwiftUI
import CoreData

struct BikeDetailView: View {
    @ObservedObject var bike: Bike
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var bikeViewModel = BikeViewModel()
    @StateObject private var maintenanceViewModel = MaintenanceRecordViewModel()
    @StateObject private var partsViewModel = PartsMemoViewModel()
    @State private var refreshTrigger = UUID()
    
    @State private var showingEditBike = false
    @State private var showingAddMaintenance = false
    @State private var showingAddParts = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                // バイク情報セクション
                BikeInfoSection(bike: bike)
                
                // 統計セクション
                StatsCardSection(bike: bike, refreshTrigger: refreshTrigger)
                
                // 最近の整備記録セクション
                RecentMaintenanceSection(bike: bike, showingAddMaintenance: $showingAddMaintenance, refreshTrigger: refreshTrigger)
                
                // 部品メモセクション
                PartsMemosSection(bike: bike, showingAddParts: $showingAddParts, refreshTrigger: refreshTrigger)
            }
            .padding(Constants.Spacing.medium)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingEditBike = true
                    }) {
                        Label("編集", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Constants.Colors.primaryFallback)
                }
            }
        }
        .sheet(isPresented: $showingEditBike) {
            EditBikeView(bike: bike, bikeViewModel: bikeViewModel)
        }
        .sheet(isPresented: $showingAddMaintenance) {
            AddMaintenanceRecordView(bike: bike, viewModel: maintenanceViewModel)
        }
        .sheet(isPresented: $showingAddParts) {
            AddPartsView(bike: bike, viewModel: partsViewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            // Core Dataの変更を検知して更新
            refreshTrigger = UUID()
        }
        .alert("バイクを削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                deleteBike()
            }
        } message: {
            Text("このバイクと関連する全ての整備記録・部品メモが削除されます。この操作は取り消せません。")
        }
    }
    
    private func deleteBike() {
        bikeViewModel.deleteBike(bike)
    }
}

struct BikeInfoSection: View {
    let bike: Bike
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            // バイク画像
            Group {
                if let imageData = bike.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "motorcycle")
                        .font(.system(size: 60))
                        .foregroundColor(Constants.Colors.secondaryFallback)
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Constants.Colors.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
            
            // バイク情報
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                Text(bike.wrappedName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("\(bike.wrappedManufacturer) \(bike.wrappedModel)")
                    .font(.title3)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                
                Text("\(bike.year)年")
                    .font(.subheadline)
                    .foregroundColor(Constants.Colors.secondaryFallback)
            }
        }
    }
}

struct StatsCardSection: View {
    let bike: Bike
    let refreshTrigger: UUID
    
    var maintenanceCount: Int {
        // refreshTriggerを使って強制的に再評価
        _ = refreshTrigger
        return bike.maintenanceRecordsArray.count
    }
    
    var totalMaintenanceCost: Double {
        // refreshTriggerを使って強制的に再評価
        _ = refreshTrigger
        return bike.totalMaintenanceCost
    }
    
    var partsCount: Int {
        // refreshTriggerを使って強制的に再評価
        _ = refreshTrigger
        return bike.partsMemosArray.count
    }
    
    var body: some View {
        HStack(spacing: Constants.Spacing.medium) {
            StatCard(
                title: "整備記録",
                value: "\(maintenanceCount)件",
                icon: "wrench.and.screwdriver",
                color: .blue
            )
            
            StatCard(
                title: "総整備費",
                value: "¥\(Int(totalMaintenanceCost))",
                icon: "yensign.circle",
                color: .blue
            )
            
            StatCard(
                title: "部品メモ",
                value: "\(partsCount)件",
                icon: "gear",
                color: .blue
            )
        }
    }
}

struct StatCard: View {
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
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Constants.Colors.secondaryFallback)
        }
        .frame(maxWidth: .infinity)
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
    }
}

struct RecentMaintenanceSection: View {
    let bike: Bike
    @Binding var showingAddMaintenance: Bool
    let refreshTrigger: UUID
    
    var recentRecords: [MaintenanceRecord] {
        // refreshTriggerを使って強制的に再評価
        _ = refreshTrigger
        return Array(bike.maintenanceRecordsArray.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            HStack {
                Text("最近の整備記録")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showingAddMaintenance = true
                }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(Constants.Colors.accentFallback)
                }
            }
            
            if recentRecords.isEmpty {
                EmptyStateView(
                    icon: "wrench.and.screwdriver",
                    title: "整備記録がありません",
                    subtitle: "新しい整備記録を追加してください"
                ) {
                    showingAddMaintenance = true
                }
            } else {
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    ForEach(recentRecords, id: \.objectID) { record in
                        NavigationLink(destination: MaintenanceRecordDetailView(record: record)) {
                            MaintenanceRecordCompactRow(record: record)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if bike.maintenanceRecordsArray.count > 3 {
                    NavigationLink(destination: BikeMaintenanceHistoryView(bike: bike)) {
                        Text("すべて表示 (\(bike.maintenanceRecordsArray.count)件)")
                            .font(.subheadline)
                            .foregroundColor(Constants.Colors.accentFallback)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Constants.Spacing.small)
                    }
                }
            }
        }
    }
}

struct PartsMemosSection: View {
    let bike: Bike
    @Binding var showingAddParts: Bool
    let refreshTrigger: UUID
    
    var recentParts: [PartsMemo] {
        // refreshTriggerを使って強制的に再評価
        _ = refreshTrigger
        return Array(bike.partsMemosArray.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            HStack {
                Text("部品メモ")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showingAddParts = true
                }) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(Constants.Colors.accentFallback)
                }
            }
            
            if recentParts.isEmpty {
                EmptyStateView(
                    icon: "gear",
                    title: "部品メモがありません",
                    subtitle: "必要な部品をメモしてください"
                ) {
                    showingAddParts = true
                }
            } else {
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    ForEach(recentParts, id: \.objectID) { part in
                        PartsCompactRow(part: part)
                    }
                }
                
                if bike.partsMemosArray.count > 3 {
                    NavigationLink(destination: BikePartsListView(bike: bike)) {
                        Text("すべて表示 (\(bike.partsMemosArray.count)件)")
                            .font(.subheadline)
                            .foregroundColor(Constants.Colors.accentFallback)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Constants.Spacing.small)
                    }
                }
            }
        }
    }
}

struct MaintenanceRecordCompactRow: View {
    let record: MaintenanceRecord
    
    var body: some View {
        HStack {
            // 写真サムネイル
            if let photos = record.photos as? Set<Photo>,
               let firstPhoto = photos.sorted(by: { $0.sortOrder < $1.sortOrder }).first,
               let imageData = firstPhoto.imageData,
               let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
                    
                    // 複数写真の場合は件数表示
                    if photos.count > 1 {
                        Text("\(photos.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(1)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                            .padding(1)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                    .fill(Constants.Colors.surfaceFallback)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.secondaryFallback)
                    )
            }
            
            VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                Text(record.wrappedCategory)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(record.wrappedItem)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.secondaryFallback)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Constants.Spacing.extraSmall) {
                Text(record.costString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text(record.dateString)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.secondaryFallback)
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
    }
}

struct PartsCompactRow: View {
    let part: PartsMemo
    @ObservedObject private var viewModel = PartsMemoViewModel()
    @State private var showingEditParts = false
    
    var priorityColor: Color {
        switch part.wrappedPriority {
        case "高": return .red
        case "中": return .orange
        case "低": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(priorityColor)
                .frame(width: 3, height: 40)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                HStack {
                    Text(part.wrappedPartName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(part.isPurchased ? Constants.Colors.secondaryFallback : .primary)
                        .strikethrough(part.isPurchased)
                    
                    if part.isPurchased {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
                
                if !part.wrappedPartNumber.isEmpty {
                    Text("品番: \(part.wrappedPartNumber)")
                        .font(.caption)
                        .foregroundColor(part.isPurchased ? Constants.Colors.secondaryFallback : .primary)
                        .strikethrough(part.isPurchased)
                }
            }
            
            Spacer()
            
            Text(part.estimatedCostString)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(part.isPurchased ? Constants.Colors.secondaryFallback : .blue)
                .strikethrough(part.isPurchased)
        }
        .padding(Constants.Spacing.medium)
        .background(part.isPurchased ? Constants.Colors.surfaceFallback.opacity(0.5) : Constants.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditParts = true
        }
        .sheet(isPresented: $showingEditParts) {
            EditPartsView(partsMemo: part, viewModel: viewModel)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: Constants.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Constants.Colors.secondaryFallback)
            
            VStack(spacing: Constants.Spacing.extraSmall) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.secondaryFallback)
            }
            
            Button("追加する") {
                action()
            }
            .font(.subheadline)
            .foregroundColor(Constants.Colors.accentFallback)
        }
        .frame(maxWidth: .infinity)
        .padding(Constants.Spacing.large)
        .background(Constants.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
    }
}

#Preview {
    NavigationView {
        BikeDetailView(bike: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is Bike }) as! Bike)
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}