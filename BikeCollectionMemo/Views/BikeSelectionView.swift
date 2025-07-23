import SwiftUI
import CoreData

struct BikeSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    let bikes: [Bike]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Constants.Spacing.large) {
                // ヘッダー
                VStack(spacing: Constants.Spacing.medium) {
                    Image(systemName: "motorcycle")
                        .font(.system(size: 60))
                        .foregroundColor(Constants.Colors.primaryFallback)
                    
                    Text("表示するバイクを選択")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("無料プランでは1台のみ表示できます\nプレミアムプランで全てのバイクを表示")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(.top, Constants.Spacing.large)
                
                // バイクリスト
                ScrollView {
                    LazyVStack(spacing: Constants.Spacing.medium) {
                        ForEach(bikes, id: \.objectID) { bike in
                            BikeSelectionRow(bike: bike) {
                                subscriptionManager.selectBike(bikeID: bike.id?.uuidString ?? "")
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, Constants.Spacing.medium)
                }
                
                Spacer()
                
                // プレミアム案内
                PremiumPromptCard()
                    .padding(.horizontal, Constants.Spacing.medium)
            }
            .navigationTitle("バイク選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BikeSelectionRow: View {
    let bike: Bike
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
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
                .frame(width: 60, height: 60)
                .background(Constants.Colors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                
                VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                    Text(bike.wrappedName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(bike.wrappedManufacturer) \(bike.wrappedModel)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(bike.year)年")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(Constants.Spacing.medium)
            .background(Constants.Colors.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                    .stroke(Constants.Colors.primaryFallback.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PremiumPromptCard: View {
    @State private var showingUpgrade = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("プレミアムプラン")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text("• 無制限のバイク登録・表示\n• 優先サポート\n• 新機能の早期アクセス")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("プレミアムにアップグレード") {
                showingUpgrade = true
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.Spacing.small)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Constants.Colors.primaryFallback, Constants.Colors.accentFallback]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.primaryFallback.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                .stroke(Constants.Colors.primaryFallback.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showingUpgrade) {
            PremiumUpgradeView()
        }
    }
}

#Preview {
    BikeSelectionView(bikes: [])
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}