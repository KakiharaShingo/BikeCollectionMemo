import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?
    @State private var showingPurchaseAlert = false
    @State private var purchaseSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // ヘッダー
                    PremiumHeaderView()
                    
                    // 機能比較
                    FeatureComparisonView()
                    
                    // プラン選択
                    if !subscriptionManager.availableProducts.isEmpty {
                        PlanSelectionView(
                            products: subscriptionManager.availableProducts,
                            selectedProduct: $selectedProduct
                        )
                    }
                    
                    // 購入ボタン
                    PurchaseButtonView(
                        selectedProduct: selectedProduct,
                        isLoading: subscriptionManager.isLoading,
                        onPurchase: purchase,
                        onRestore: restore
                    )
                    
                    // 利用規約・プライバシーポリシー
                    LegalLinksView()
                }
                .padding(Constants.Spacing.medium)
            }
            .navigationTitle("プレミアムプラン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await subscriptionManager.loadProducts()
                selectedProduct = subscriptionManager.yearlyProduct() // デフォルトで年間プラン選択
            }
        }
        .alert("購入完了", isPresented: $purchaseSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("プレミアムプランへのアップグレードが完了しました！")
        }
        .alert("エラー", isPresented: .constant(subscriptionManager.errorMessage != nil)) {
            Button("OK") {
                subscriptionManager.errorMessage = nil
            }
        } message: {
            Text(subscriptionManager.errorMessage ?? "")
        }
    }
    
    private func purchase() {
        guard let product = selectedProduct else { return }
        
        Task {
            let success = await subscriptionManager.purchase(product)
            if success {
                purchaseSuccess = true
            }
        }
    }
    
    private func restore() {
        Task {
            await subscriptionManager.restorePurchases()
        }
    }
}

struct PremiumHeaderView: View {
    var body: some View {
        VStack(spacing: 20) {
            // アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .yellow]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("プレミアムプランにアップグレード")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("すべての機能を制限なしで利用できます")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct FeatureComparisonView: View {
    let features = [
        ("バイク登録数", "1台まで", "無制限"),
        ("広告表示", "あり", "なし"),
        ("サポート", "標準", "優先"),
        ("新機能", "標準リリース", "アーリーアクセス")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("機能")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("無料")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                
                Text("プレミアム")
                    .font(.headline)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, Constants.Spacing.medium)
            .background(Constants.Colors.surfaceFallback)
            
            // 機能リスト
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                HStack {
                    Text(feature.0)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(feature.1)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                    
                    HStack {
                        if feature.0 == "バイク登録数" || feature.0 == "広告表示" {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        Text(feature.2)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, Constants.Spacing.small)
                .background(index % 2 == 0 ? Color.clear : Constants.Colors.surfaceFallback.opacity(0.5))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PlanSelectionView: View {
    let products: [Product]
    @Binding var selectedProduct: Product?
    
    var body: some View {
        VStack(spacing: 15) {
            Text("プランを選択")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(products, id: \.id) { product in
                PlanCardView(
                    product: product,
                    isSelected: selectedProduct?.id == product.id
                ) {
                    selectedProduct = product
                }
            }
        }
    }
}

struct PlanCardView: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var isYearlyPlan: Bool {
        product.id.contains("yearly")
    }
    
    private var planTitle: String {
        isYearlyPlan ? "年間プラン" : "月間プラン"
    }
    
    private var planDescription: String {
        if isYearlyPlan {
            return "2ヶ月分お得！"
        } else {
            return "いつでもキャンセル可能"
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(planTitle)
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        if isYearlyPlan {
                            Text("おすすめ")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    
                    Text(planDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text(isYearlyPlan ? "/年" : "/月")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .green : .gray)
            }
            .padding(Constants.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Constants.Colors.surfaceFallback)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PurchaseButtonView: View {
    let selectedProduct: Product?
    let isLoading: Bool
    let onPurchase: () -> Void
    let onRestore: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Button(action: onPurchase) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "crown.fill")
                        Text("アップグレード")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.orange, .yellow]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
            }
            .disabled(selectedProduct == nil || isLoading)
            
            Button("購入履歴を復元", action: onRestore)
                .font(.subheadline)
                .foregroundColor(.blue)
                .disabled(isLoading)
        }
    }
}

struct LegalLinksView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("購入すると利用規約とプライバシーポリシーに同意したことになります")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button("利用規約") {
                    // 利用規約を開く
                    if let url = URL(string: "https://kakiharashingo.github.io/BikeCollectionMemo/terms-of-service.html") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Button("プライバシーポリシー") {
                    // プライバシーポリシーを開く
                    if let url = URL(string: "https://kakiharashingo.github.io/BikeCollectionMemo/privacy-policy.html") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Upgrade Prompt

struct BikeUpgradePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPremiumView = false
    
    var body: some View {
        VStack(spacing: 30) {
            // アイコン
            Image(systemName: "lock.circle")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            VStack(spacing: 15) {
                Text("もっとバイクを追加しませんか？")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("無料プランでは1台まで登録できます。\nプレミアムプランにアップグレードして、\n無制限にバイクを登録しましょう！")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 15) {
                Button(action: {
                    showingPremiumView = true
                }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("プレミアムプランを見る")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .yellow]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                }
                
                Button("後で") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding(Constants.Spacing.large)
        .sheet(isPresented: $showingPremiumView) {
            PremiumUpgradeView()
        }
    }
}

#Preview {
    PremiumUpgradeView()
}