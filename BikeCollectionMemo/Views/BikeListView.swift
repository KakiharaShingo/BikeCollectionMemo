import SwiftUI
import CoreData

struct BikeListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Bike.updatedAt, ascending: false)],
        animation: .default)
    private var bikes: FetchedResults<Bike>
    
    @StateObject private var bikeViewModel = BikeViewModel()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingAddBike = false
    @State private var showingUpgradePrompt = false
    @State private var showingBikeSelection = false
    @State private var searchText = ""
    @State private var isLoading = false
    
    var filteredBikes: [Bike] {
        let searchFiltered: [Bike]
        if searchText.isEmpty {
            searchFiltered = Array(bikes)
        } else {
            searchFiltered = bikes.filter { bike in
                bike.wrappedName.localizedCaseInsensitiveContains(searchText) ||
                bike.wrappedManufacturer.localizedCaseInsensitiveContains(searchText) ||
                bike.wrappedModel.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // サブスクリプション状態に基づいてフィルタリング
        return subscriptionManager.getFilteredBikes(from: searchFiltered) as! [Bike]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // バイク選択を促すバナー
                if subscriptionManager.shouldShowBikeSelectionUI(bikeCount: bikes.count) {
                    BikeSelectionBanner {
                        showingBikeSelection = true
                    }
                }
                
                // 非プレミアムユーザーの制限通知
                if !subscriptionManager.isSubscribed && bikes.count > 1 && subscriptionManager.selectedBikeID != nil {
                    NonPremiumLimitBanner {
                        showingBikeSelection = true
                    }
                }
                
                if bikes.isEmpty && !isLoading {
                    EmptyBikeView(showingAddBike: $showingAddBike)
                } else if !filteredBikes.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: Constants.Spacing.medium) {
                            ForEach(filteredBikes, id: \.objectID) { bike in
                                NavigationLink(destination: BikeDetailView(bike: bike)) {
                                    BikeRowView(bike: bike)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, Constants.Spacing.medium)
                        .padding(.top, Constants.Spacing.small)
                    }
                } else if !searchText.isEmpty && filteredBikes.isEmpty {
                    // 検索結果が空の場合
                    VStack(alignment: .center, spacing: Constants.Spacing.large) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("検索結果がありません")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("別のキーワードで検索してみてください")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .navigationTitle("バイク")
            .searchable(text: $searchText, prompt: "バイクを検索")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if subscriptionManager.canAddMoreBikes(currentBikeCount: bikes.count) {
                            showingAddBike = true
                        } else {
                            showingUpgradePrompt = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(Constants.Colors.primaryFallback)
                    }
                }
            }
            .background(Constants.Colors.backgroundFallback)
        }
        .sheet(isPresented: $showingAddBike) {
            AddBikeView(bikeViewModel: bikeViewModel)
        }
        .sheet(isPresented: $showingUpgradePrompt) {
            BikeUpgradePromptView()
        }
        .sheet(isPresented: $showingBikeSelection) {
            BikeSelectionView(bikes: Array(bikes))
        }
    }
}

struct BikeRowView: View {
    let bike: Bike
    
    var body: some View {
        HStack(alignment: .center, spacing: Constants.Spacing.medium) {
            // バイク画像
            Group {
                if let imageData = bike.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "motorcycle")
                        .font(.title)
                        .foregroundColor(Constants.Colors.secondaryFallback)
                }
            }
            .frame(width: 80, height: 80)
            .background(Constants.Colors.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
            
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                Text(bike.wrappedName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(bike.wrappedManufacturer) \(bike.wrappedModel)")
                    .font(.body)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(bike.year)年")
                    .font(.subheadline)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let lastMaintenance = bike.lastMaintenanceDate {
                    Text("最終整備: \(formatDate(lastMaintenance))")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.accentFallback)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Constants.Spacing.small) {
                Text("¥\(Int(bike.totalMaintenanceCost))")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Text("総整備費")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(Constants.Colors.secondaryFallback)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(Constants.Spacing.medium)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Constants.Colors.surfaceFallback, Constants.Colors.surfaceFallback.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                .stroke(Constants.Colors.primaryFallback.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct EmptyBikeView: View {
    @Binding var showingAddBike: Bool
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingUpgradePrompt = false
    
    var body: some View {
        VStack(alignment: .center, spacing: Constants.Spacing.large) {
            Image(systemName: "motorcycle")
                .font(.system(size: 80))
                .foregroundColor(Constants.Colors.secondaryFallback)
            
            VStack(alignment: .center, spacing: Constants.Spacing.medium) {
                Text("バイクを登録しよう")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("愛車の整備記録を残すために\nまずはバイクを登録してください")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Constants.Colors.secondaryFallback)
            }
            
            Button(action: {
                if subscriptionManager.canAddMoreBikes(currentBikeCount: 0) {
                    showingAddBike = true
                } else {
                    showingUpgradePrompt = true
                }
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("バイクを追加")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, Constants.Spacing.large)
                .padding(.vertical, Constants.Spacing.medium)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Constants.Colors.primaryFallback, Constants.Colors.accentFallback]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
                .shadow(color: Constants.Colors.primaryFallback.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Constants.Colors.backgroundFallback)
        .sheet(isPresented: $showingUpgradePrompt) {
            BikeUpgradePromptView()
        }
    }
}

struct AsyncImage: View {
    let data: Data?
    let content: (Image) -> Image
    let placeholder: () -> Image
    
    init(data: Data?, @ViewBuilder content: @escaping (Image) -> Image, @ViewBuilder placeholder: @escaping () -> Image) {
        self.data = data
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        if let data = data, let uiImage = UIImage(data: data) {
            content(Image(uiImage: uiImage))
        } else {
            placeholder()
        }
    }
}

// MARK: - Banner Components

struct BikeSelectionBanner: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Constants.Spacing.medium) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                    Text("表示するバイクを選択してください")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("無料プランでは1台のみ表示できます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(Constants.Spacing.medium)
            .background(Color.orange.opacity(0.1))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.orange.opacity(0.3)),
                alignment: .bottom
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NonPremiumLimitBanner: View {
    let onTap: () -> Void
    @State private var showingUpgrade = false
    
    var body: some View {
        HStack(spacing: Constants.Spacing.medium) {
            Image(systemName: "info.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                Text("1台のみ表示中（無料プラン）")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("他のバイクを表示する場合はタップ")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("プレミアム") {
                showingUpgrade = true
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Constants.Colors.primaryFallback)
            .clipShape(Capsule())
            
            Button(action: onTap) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Color.blue.opacity(0.05))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.blue.opacity(0.2)),
            alignment: .bottom
        )
        .sheet(isPresented: $showingUpgrade) {
            PremiumUpgradeView()
        }
    }
}

#Preview {
    BikeListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}