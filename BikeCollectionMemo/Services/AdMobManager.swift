import Foundation
import SwiftUI
import Combine
import GoogleMobileAds

@MainActor
class AdMobManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = AdMobManager()
    
    // Ad Unit IDs
    private let appID = "ca-app-pub-7155393284008150~6824903344"
    let bannerAdUnitID = "ca-app-pub-7155393284008150/6336946049"
    let interstitialAdUnitID = "ca-app-pub-7155393284008150/1310698697"
    
    // テスト用広告ID
    let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    let testInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    
    // デバッグモード設定
    let isDebugMode = true
    
    @Published var isAdLoaded = false
    @Published var showAds = true
    @Published var enableInterstitialAds = true // インタースティシャル広告の有効/無効制御
    
    private let subscriptionManager = SubscriptionManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var interstitialAd: InterstitialAd?
    
    override init() {
        super.init()
        
        // AdMobの初期化（アプリケーションIDを明示的に設定）
        print("🚀 Initializing AdMob with App ID: \(appID)")
        
        // デバッグモードを有効化（シミュレーター用テストデバイス設定）
        if isDebugMode {
            MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["SIMULATOR"]
            // より多くのテストデバイスIDを追加
            MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [
                "SIMULATOR",
                "33BE2250B43518CCDA7DE426D04EE231" // 一般的なテストデバイスID
            ]
        }
        
        MobileAds.shared.start { initializationStatus in
            print("✅ AdMob initialization completed")
            for adapter in initializationStatus.adapterStatusesByClassName {
                print("📋 Adapter: \(adapter.key), Status: \(adapter.value.state.rawValue)")
            }
        }
        
        // サブスクリプション状態の監視
        subscriptionManager.$subscriptionStatus
            .sink { [weak self] status in
                self?.updateAdVisibility(subscriptionStatus: status)
            }
            .store(in: &cancellables)
        
        // インタースティシャル広告を読み込み
        loadInterstitialAd()
    }
    
    // MARK: - Ad Visibility Control
    
    private func updateAdVisibility(subscriptionStatus: SubscriptionManager.SubscriptionStatus) {
        DispatchQueue.main.async {
            switch subscriptionStatus {
            case .subscribed:
                self.showAds = false
            case .notSubscribed, .expired, .unknown:
                self.showAds = true
            }
        }
    }
    
    func shouldShowAds() -> Bool {
        return showAds && !subscriptionManager.isSubscribed
    }
    
    // MARK: - Interstitial Ads
    
    private func loadInterstitialAd() {
        // 既存の広告があれば解放
        interstitialAd = nil
        isAdLoaded = false
        
        let request = Request()
        // テストモードでリクエストにキーワードを追加
        if isDebugMode {
            request.keywords = ["test", "debug"]
        }
        let adUnitID = isDebugMode ? testInterstitialAdUnitID : interstitialAdUnitID
        print("🔍 Loading interstitial ad with ID: \(adUnitID)")
        
        InterstitialAd.load(with: adUnitID, request: request, completionHandler: { [weak self] ad, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Failed to load interstitial ad: \(error.localizedDescription)")
                    print("❌ Interstitial error details: \(error)")
                    if let gadError = error as NSError? {
                        print("❌ GAD Error code: \(gadError.code)")
                        print("❌ GAD Error domain: \(gadError.domain)")
                        print("❌ GAD Error userInfo: \(gadError.userInfo)")
                    }
                    self.isAdLoaded = false
                    // エラー時は少し待ってから再試行
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self.loadInterstitialAd()
                    }
                    return
                }
                print("✅ Interstitial ad loaded successfully")
                self.interstitialAd = ad
                self.isAdLoaded = true
                self.interstitialAd?.fullScreenContentDelegate = self
            }
        })
    }
    
    func showInterstitialAd() {
        guard shouldShowAds() && enableInterstitialAds && isAdLoaded else { return }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Could not find root view controller")
            return
        }
        
        interstitialAd?.present(from: rootViewController)
    }
    
    func showInterstitialAdWithCooldown() {
        showInterstitialAd()
    }
    
    // MARK: - Mock Rewarded Ads
    
    func showRewardedAd(onReward: @escaping () -> Void) {
        guard shouldShowAds() && enableInterstitialAds else { return }
        print("Mock: Showing rewarded ad")
        
        // Simulate reward after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            onReward()
        }
    }
    
    // MARK: - Admin Controls
    
    func enableInterstitialAdvertising() {
        enableInterstitialAds = true
    }
    
    func disableInterstitialAdvertising() {
        enableInterstitialAds = false
    }
}

// MARK: - GADFullScreenContentDelegate

extension AdMobManager {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // 広告が閉じられた後、新しい広告を読み込み
        loadInterstitialAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Failed to present interstitial ad: \(error.localizedDescription)")
        loadInterstitialAd()
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Interstitial ad will be presented")
    }
}

// MARK: - Banner Ad View

struct BannerAdView: View {
    @StateObject private var adMobManager = AdMobManager.shared
    
    // 標準的なバナー広告の高さ
    static let bannerHeight: CGFloat = 50
    
    var body: some View {
        if adMobManager.shouldShowAds() {
            AdMobBannerView()
                .frame(height: Self.bannerHeight)
                .clipped()
        }
    }
}

struct AdMobBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        print("🔍 Creating AdMob banner view")
        
        let bannerView = BannerView(adSize: AdSizeBanner)
        
        // デバッグモードの場合はテスト広告IDを使用
        let adManager = AdMobManager.shared
        let adUnitID = adManager.isDebugMode ? adManager.testBannerAdUnitID : adManager.bannerAdUnitID
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        
        print("🔍 Banner view created with ad unit ID: \(bannerView.adUnitID ?? "nil")")
        
        // Root view controllerの設定を遅延させて確実に取得
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                bannerView.rootViewController = rootViewController
                print("🔍 Root view controller set")
                
                // Root view controllerが設定された後に広告をロード
                let request = Request()
                if adManager.isDebugMode {
                    request.keywords = ["test", "debug"]
                }
                bannerView.load(request)
                print("🔍 Ad request sent")
            } else {
                print("❌ Failed to find root view controller")
            }
        }
        
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        print("🔍 Updating banner view")
        
        // 広告の再読み込みを防ぐため、既に広告がロードされているかチェック
        guard uiView.adUnitID != nil, uiView.rootViewController != nil else {
            return
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ Banner ad loaded successfully")
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Banner ad failed to load: \(error.localizedDescription)")
            print("❌ Banner ad error details: \(error)")
            if let gadError = error as NSError? {
                print("❌ GAD Error code: \(gadError.code)")
                print("❌ GAD Error domain: \(gadError.domain)")
                print("❌ GAD Error userInfo: \(gadError.userInfo)")
            }
        }
        
        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            print("📊 Banner ad impression recorded")
        }
        
        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            print("📱 Banner ad will present screen")
        }
        
        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            print("📱 Banner ad dismissed screen")
        }
    }
}

// MARK: - Smart Banner Ad View

struct SmartBannerAdView: View {
    @StateObject private var adMobManager = AdMobManager.shared
    
    var body: some View {
        if adMobManager.shouldShowAds() {
            BannerAdView()
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.3), value: adMobManager.shouldShowAds())
        }
    }
}