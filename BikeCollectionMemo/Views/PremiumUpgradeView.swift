import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?
    @State private var purchaseSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // ヘッダー
                    PremiumHeaderView()
                    
                    // 機能比較
                    FeatureComparisonView()
                    
                    // プラン選択と購入ボタンを統合
                    VStack(spacing: 20) {
                        if !subscriptionManager.availableProducts.isEmpty {
                            PlanSelectionView(
                                products: subscriptionManager.availableProducts,
                                selectedProduct: $selectedProduct
                            )
                            
                            // 購入ボタンを統合
                            Button(action: {
                                purchase()
                            }) {
                                HStack {
                                    if subscriptionManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "crown.fill")
                                        Text(selectedProduct != nil ? "購入する" : "年間プランで始める")
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
                            .disabled(subscriptionManager.isLoading)
                            
                            Button("購入履歴を復元", action: restore)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .disabled(subscriptionManager.isLoading)
                            
                        } else {
                            // デバッグ用：プロダクトが読み込まれていない場合の表示
                            VStack(spacing: 15) {
                                if subscriptionManager.isLoading {
                                    ProgressView("プランを読み込み中...")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    VStack(spacing: 15) {
                                        Text("プランの読み込みに失敗しました")
                                            .foregroundColor(.red)
                                        
                                        Text("開発環境では実際の価格が表示されません")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Button("再試行") {
                                            Task {
                                                await subscriptionManager.loadProducts()
                                            }
                                        }
                                        .foregroundColor(.blue)
                                        
                                        // デバッグ用プラン表示
                                        MockPlanSelectionView(selectedProduct: $selectedProduct)
                                        
                                        // デバッグ用購入ボタン
                                        Button("デバッグ購入") {
                                            // デバッグ環境用
                                            purchaseSuccess = true
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.orange)
                                        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                                    }
                                }
                            }
                            .padding()
                            .background(Constants.Colors.surfaceFallback)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                        }
                    }
                    
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
                
                #if DEBUG
                // デバッグ環境でプロダクトが読み込まれない場合、デバッグ用の処理
                if subscriptionManager.availableProducts.isEmpty {
                    print("Debug: No products loaded. Using mock products for development.")
                    print("Debug: SubscriptionManager isLoading: \(subscriptionManager.isLoading)")
                    print("Debug: SubscriptionManager errorMessage: \(subscriptionManager.errorMessage ?? "none")")
                } else {
                    print("Debug: Loaded \(subscriptionManager.availableProducts.count) products:")
                    for product in subscriptionManager.availableProducts {
                        print("Debug: Product ID: \(product.id), Price: \(product.displayPrice)")
                    }
                }
                #endif
                
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
        // プランが選択されていない場合は年間プランをデフォルト選択
        let productToPurchase = selectedProduct ?? subscriptionManager.yearlyProduct()
        guard let product = productToPurchase else { return }
        
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
        // 仮リリースでは広告なしのため一時的にコメントアウト
        // ("広告表示", "あり", "なし"),
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
    
    private var monthlyProduct: Product? {
        products.first { $0.id.contains("monthly") }
    }
    
    private var yearlyProduct: Product? {
        products.first { $0.id.contains("yearly") }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("プランを選択")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("どちらのプランでも全ての機能をご利用いただけます")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // プラン比較カード
            if let monthly = monthlyProduct, let yearly = yearlyProduct {
                PlanComparisonView(monthlyProduct: monthly, yearlyProduct: yearly, selectedProduct: $selectedProduct)
            }
            
            // 個別プランカード
            ForEach(products.sorted(by: { p1, p2 in
                // 年間プランを先に表示
                if p1.id.contains("yearly") && p2.id.contains("monthly") {
                    return true
                } else if p1.id.contains("monthly") && p2.id.contains("yearly") {
                    return false
                }
                return p1.price < p2.price
            }), id: \.id) { product in
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

struct PlanComparisonView: View {
    let monthlyProduct: Product
    let yearlyProduct: Product
    @Binding var selectedProduct: Product?
    
    private var monthlyCost: Double {
        Double(truncating: monthlyProduct.price as NSNumber) * 12
    }
    
    private var yearlyCost: Double {
        Double(truncating: yearlyProduct.price as NSNumber)
    }
    
    private var savings: Double {
        monthlyCost - yearlyCost
    }
    
    private var savingsPercentage: Int {
        Int((savings / monthlyCost) * 100)
    }
    
    var body: some View {
        VStack(spacing: Constants.Spacing.medium) {
            Text("年間プランがお得！")
                .font(.headline)
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: Constants.Spacing.medium) {
                // 月間プラン
                VStack(spacing: Constants.Spacing.small) {
                    Text("月間プラン")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(monthlyProduct.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("/月")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("年間 ¥\(Int(monthlyCost))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Constants.Spacing.medium)
                .background(Constants.Colors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                
                // VS
                Text("VS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                // 年間プラン
                VStack(spacing: Constants.Spacing.small) {
                    HStack {
                        Text("年間プラン")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(savingsPercentage)%OFF")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    
                    Text(yearlyProduct.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("/年")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("¥\(Int(savings))節約")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(Constants.Spacing.medium)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                        .stroke(Color.orange, lineWidth: 1)
                )
            }
        }
        .padding(Constants.Spacing.medium)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.05), Color.yellow.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
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
            return "2ヶ月分お得！年間利用で最大の節約"
        } else {
            return "いつでもキャンセル可能・短期利用に最適"
        }
    }
    
    private var monthlyEquivalent: String? {
        if isYearlyPlan {
            // 年間プランの月額換算を計算
            let yearlyPrice = product.price
            let monthlyEquivalent = yearlyPrice / 12
            return String(format: "月額換算 ¥%.0f", Double(truncating: monthlyEquivalent as NSNumber))
        }
        return nil
    }
    
    private var savingsText: String? {
        if isYearlyPlan {
            // 月額¥380 × 12ヶ月 = ¥4,560 年間プランが¥3,800なら¥760節約
            return "年間で約¥760節約"
        }
        return nil
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: Constants.Spacing.medium) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(planTitle)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            if isYearlyPlan {
                                Text("おすすめ")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.orange, .red]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                            }
                            
                            Spacer()
                        }
                        
                        Text(planDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.displayPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(isYearlyPlan ? "/年" : "/月")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let monthlyEquivalent = monthlyEquivalent {
                            Text(monthlyEquivalent)
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                if let savingsText = savingsText {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(savingsText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                    .padding(.horizontal, Constants.Spacing.small)
                    .padding(.vertical, Constants.Spacing.extraSmall)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
                }
                
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .green : .gray)
                    
                    Text(isSelected ? "選択中" : "選択する")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .green : .gray)
                    
                    Spacer()
                }
            }
            .padding(Constants.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                    .fill(isSelected ? Color.blue.opacity(0.05) : Constants.Colors.surfaceFallback)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                            .stroke(
                                isSelected ? Color.blue : 
                                (isYearlyPlan ? Color.orange.opacity(0.5) : Color.gray.opacity(0.2)), 
                                lineWidth: isSelected ? 2 : 1
                            )
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
            .disabled(isLoading)
            
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

// MARK: - Purchase Confirmation Sheet

struct PurchaseConfirmationSheet: View {
    let selectedProduct: Product?
    let subscriptionManager: SubscriptionManager
    let onPurchase: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private var isYearlyPlan: Bool {
        selectedProduct?.id.contains("yearly") ?? false
    }
    
    private var planTitle: String {
        isYearlyPlan ? "年間プラン" : "月間プラン"
    }
    
    private var planPrice: String {
        selectedProduct?.displayPrice ?? ""
    }
    
    private var planPeriod: String {
        isYearlyPlan ? "/年" : "/月"
    }
    
    private var planBenefits: [String] {
        let benefits = [
            "無制限のバイク登録",
            // 仮リリースでは広告なしのため一時的にコメントアウト
            // "広告なし",
            "優先サポート",
            "新機能のアーリーアクセス"
        ]
        
        if isYearlyPlan {
            return ["年間で約¥760節約"] + benefits
        } else {
            return benefits
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // ヘッダー
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: isYearlyPlan ? [.orange, .red] : [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: isYearlyPlan ? "crown.fill" : "sparkles")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("購入確認")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if isYearlyPlan {
                                Text("おすすめプラン")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    // プラン詳細
                    VStack(spacing: 20) {
                        HStack {
                            Text("プラン")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(planTitle)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                if isYearlyPlan {
                                    Text("2ヶ月分お得な年間プラン")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                } else {
                                    Text("いつでもキャンセル可能")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(planPrice)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(isYearlyPlan ? .orange : .blue)
                                
                                Text(planPeriod)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if isYearlyPlan {
                                    Text("月額換算 ¥317")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding(Constants.Spacing.medium)
                        .background(Constants.Colors.surfaceFallback)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                                .stroke(isYearlyPlan ? Color.orange : Color.blue, lineWidth: 1)
                        )
                    }
                    
                    // 特典一覧
                    VStack(spacing: 15) {
                        HStack {
                            Text("含まれる特典")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(Array(planBenefits.enumerated()), id: \.offset) { index, benefit in
                                HStack {
                                    Image(systemName: index == 0 && isYearlyPlan ? "tag.fill" : "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(index == 0 && isYearlyPlan ? .green : .blue)
                                    
                                    Text(benefit)
                                        .font(.subheadline)
                                        .fontWeight(index == 0 && isYearlyPlan ? .semibold : .regular)
                                        .foregroundColor(index == 0 && isYearlyPlan ? .green : .primary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, Constants.Spacing.medium)
                                .padding(.vertical, Constants.Spacing.small)
                                .background(
                                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                                        .fill(index == 0 && isYearlyPlan ? Color.green.opacity(0.1) : Constants.Colors.surfaceFallback)
                                )
                            }
                        }
                    }
                    
                    // 重要な情報
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("重要な情報")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• 購入後は自動的に更新されます")
                            Text("• キャンセルは次回更新日の24時間前まで可能です")
                            Text("• 設定 > Apple ID > サブスクリプションから管理できます")
                            Text("• 購入すると利用規約とプライバシーポリシーに同意したことになります")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(Constants.Spacing.medium)
                    .background(Color.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                    
                    // 購入ボタン
                    VStack(spacing: 15) {
                        Button(action: {
                            dismiss()
                            onPurchase()
                        }) {
                            HStack {
                                if subscriptionManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "creditcard.fill")
                                    Text("\(planPrice)で購入する")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: isYearlyPlan ? [.orange, .red] : [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
                        }
                        .disabled(subscriptionManager.isLoading)
                        
                        Button("キャンセル") {
                            dismiss()
                            onCancel()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(Constants.Spacing.medium)
            }
            .navigationTitle("プレミアムプラン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                        onCancel()
                    }
                }
            }
        }
    }
}

// MARK: - Mock Plan Selection for Development

struct MockPlanSelectionView: View {
    @Binding var selectedProduct: Product?
    
    private let mockMonthlyPrice = "¥380"
    private let mockYearlyPrice = "¥3,800"
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("プランを選択")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("開発環境用のモックプラン表示です")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 年間プランカード
            MockPlanCardView(
                title: "年間プラン",
                price: mockYearlyPrice,
                period: "/年",
                description: "2ヶ月分お得！年間利用で最大の節約",
                savingsText: "年間で約¥760節約",
                isYearly: true,
                isSelected: selectedProduct?.id.contains("yearly") ?? false
            ) {
                // 年間プランを選択（モック）
            }
            
            // 月間プランカード
            MockPlanCardView(
                title: "月間プラン",
                price: mockMonthlyPrice,
                period: "/月",
                description: "いつでもキャンセル可能・短期利用に最適",
                savingsText: nil,
                isYearly: false,
                isSelected: selectedProduct?.id.contains("monthly") ?? false
            ) {
                // 月間プランを選択（モック）
            }
            
            Text("開発環境では実際の購入はできません")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }
}

struct MockPlanCardView: View {
    let title: String
    let price: String
    let period: String
    let description: String
    let savingsText: String?
    let isYearly: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: Constants.Spacing.medium) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            if isYearly {
                                Text("おすすめ")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.orange, .red]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                            }
                            
                            Spacer()
                        }
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(price)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(period)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if isYearly {
                            Text("月額換算 ¥317")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                if let savingsText = savingsText {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(savingsText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                    .padding(.horizontal, Constants.Spacing.small)
                    .padding(.vertical, Constants.Spacing.extraSmall)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
                }
                
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .green : .gray)
                    
                    Text("開発用モック")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
            .padding(Constants.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                    .fill(isSelected ? Color.blue.opacity(0.05) : Constants.Colors.surfaceFallback)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                            .stroke(
                                isSelected ? Color.blue : 
                                (isYearly ? Color.orange.opacity(0.5) : Color.gray.opacity(0.2)), 
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PremiumUpgradeView()
}