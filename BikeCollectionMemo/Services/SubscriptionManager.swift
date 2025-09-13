import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var availableProducts: [Product] = []
    @Published var purchasedProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // プロダクトID（実際のApp Store Connectで設定したIDに変更）
    private let productIDs = [
        "com.sereno.motomemo.subscription.monthly",
        "com.sereno.motomemo.subscription.yearly"
    ]
    
    // 無料プランでのバイク登録制限
    private let freePlanBikeLimit = 5
    
    // 選択されたバイクID（非プレミアム時に表示するバイク）
    @Published var selectedBikeID: String? {
        didSet {
            if let selectedBikeID = selectedBikeID {
                UserDefaults.standard.set(selectedBikeID, forKey: "selectedBikeID")
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedBikeID")
            }
        }
    }
    
    private var updateListenerTask: Task<Void, Error>?
    
    enum SubscriptionStatus {
        case unknown
        case notSubscribed
        case subscribed
        case expired
    }
    
    init() {
        // 保存された選択バイクIDを読み込み
        self.selectedBikeID = UserDefaults.standard.string(forKey: "selectedBikeID")
        
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
        
        // デバッグプレミアム状態の変更を監視
        NotificationCenter.default.addObserver(
            forName: .debugPremiumStatusChanged,
            object: nil,
            queue: .main
        ) { _ in
            self.objectWillChange.send()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let products = try await Product.products(for: productIDs)
            availableProducts = products.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "商品情報の読み込みに失敗しました"
            print("Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    isLoading = false
                    return true
                case .unverified:
                    errorMessage = "購入の検証に失敗しました"
                    isLoading = false
                    return false
                }
            case .userCancelled:
                isLoading = false
                return false
            case .pending:
                errorMessage = "購入が保留中です"
                isLoading = false
                return false
            @unknown default:
                errorMessage = "予期しないエラーが発生しました"
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "購入に失敗しました: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Restore
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "購入情報の復元に失敗しました"
        }
        
        isLoading = false
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async {
        var tempPurchasedProducts: [Product] = []
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if let product = availableProducts.first(where: { $0.id == transaction.productID }) {
                    tempPurchasedProducts.append(product)
                }
            case .unverified:
                continue
            }
        }
        
        purchasedProducts = tempPurchasedProducts
        
        if !purchasedProducts.isEmpty {
            subscriptionStatus = .subscribed
        } else {
            subscriptionStatus = .notSubscribed
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                case .unverified:
                    continue
                }
            }
        }
    }
    
    // MARK: - Business Logic
    
    func canAddMoreBikes(currentBikeCount: Int) -> Bool {
        // デバッグプレミアムまたは実際のサブスクリプションがある場合は無制限
        if isSubscribed {
            return true
        }
        // 無料プランの場合は制限あり
        return currentBikeCount < freePlanBikeLimit
    }
    
    func shouldShowUpgradePrompt(currentBikeCount: Int) -> Bool {
        return !canAddMoreBikes(currentBikeCount: currentBikeCount) && !isSubscribed
    }
    
    // MARK: - Bike Selection Management
    
    func shouldShowBikeSelectionUI(bikeCount: Int) -> Bool {
        return !isSubscribed && bikeCount > freePlanBikeLimit && selectedBikeID == nil
    }
    
    func getFilteredBikes<T: Collection>(from bikes: T) -> [T.Element] where T.Element: Any {
        // プレミアムユーザーは全てのバイクを表示
        if isSubscribed {
            return Array(bikes)
        }
        
        // 非プレミアムユーザーで選択されたバイクがある場合
        if let selectedBikeID = selectedBikeID {
            return Array(bikes).filter { bike in
                if let bike = bike as? Bike {
                    return bike.id?.uuidString == selectedBikeID
                }
                return false
            }
        }
        
        // 選択されたバイクがない場合は最初の1台のみ
        return Array(bikes.prefix(freePlanBikeLimit))
    }
    
    func selectBike(bikeID: String) {
        selectedBikeID = bikeID
    }
    
    func clearSelectedBike() {
        selectedBikeID = nil
    }
    
    var isSubscribed: Bool {
        // デバッグモードでプレミアムが有効な場合は優先
        if Constants.Development.showDeveloperSettings {
            let debugPremiumEnabled = UserDefaults.standard.bool(forKey: Constants.SettingsKeys.debugPremiumEnabled)
            if debugPremiumEnabled {
                return true
            }
        }
        return subscriptionStatus == .subscribed
    }
    
    var statusDescription: String {
        switch subscriptionStatus {
        case .unknown:
            return "確認中..."
        case .notSubscribed:
            return "無料プラン"
        case .subscribed:
            return "プレミアムプラン"
        case .expired:
            return "期限切れ"
        }
    }
    
    // MARK: - Product Information
    
    func monthlyProduct() -> Product? {
        return availableProducts.first { $0.id == "com.sereno.motomemo.subscription.monthly" }
    }
    
    func yearlyProduct() -> Product? {
        return availableProducts.first { $0.id == "com.sereno.motomemo.subscription.yearly" }
    }
    
    func formatPrice(for product: Product) -> String {
        return product.displayPrice
    }
    
    // MARK: - Debug/Development
    
    #if DEBUG
    func simulateSubscription() {
        subscriptionStatus = .subscribed
    }
    
    func simulateNoSubscription() {
        subscriptionStatus = .notSubscribed
    }
    #endif
}

// MARK: - Extensions

extension SubscriptionManager {
    var freePlanLimitDescription: String {
        return "無料プランでは\(freePlanBikeLimit)台まで登録できます"
    }
    
    var premiumBenefits: [String] {
        return [
            "無制限のバイク登録",
            // 仮リリースでは広告なしのため一時的にコメントアウト
            // "広告なし",
            "優先サポート",
            "将来の新機能へのアーリーアクセス"
        ]
    }
}
