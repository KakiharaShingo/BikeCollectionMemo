import Foundation
import SwiftUI
import Combine

// Mock implementation for AdMob functionality
// TODO: Add GoogleMobileAds SDK for production use

@MainActor
class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()
    
    // Ad Unit IDs (for future use)
    private let appID = "ca-app-pub-7155393284008150~6824903344"
    private let bannerAdUnitID = "ca-app-pub-7155393284008150/6336946049"
    private let interstitialAdUnitID = "ca-app-pub-7155393284008150/1310698697"
    
    @Published var isAdLoaded = true
    @Published var showAds = true
    @Published var enableInterstitialAds = false // インタースティシャル広告の有効/無効制御
    
    private let subscriptionManager = SubscriptionManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        
        // サブスクリプション状態の監視
        subscriptionManager.$subscriptionStatus
            .sink { [weak self] status in
                self?.updateAdVisibility(subscriptionStatus: status)
            }
            .store(in: &cancellables)
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
    
    // MARK: - Mock Interstitial Ads
    
    func showInterstitialAd() {
        guard shouldShowAds() && enableInterstitialAds else { return }
        print("Mock: Showing interstitial ad")
    }
    
    func showInterstitialAdWithCooldown() {
        guard shouldShowAds() && enableInterstitialAds else { return }
        print("Mock: Showing interstitial ad with cooldown")
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

// MARK: - Mock Banner Ad View

struct BannerAdView: View {
    @StateObject private var adMobManager = AdMobManager.shared
    
    // 標準的なバナー広告の高さ
    static let bannerHeight: CGFloat = 50
    
    var body: some View {
        if adMobManager.shouldShowAds() {
            VStack(spacing: 0) {
                // 区切り線
                Divider()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: Self.bannerHeight)
                    .overlay(
                        HStack {
                            Image(systemName: "megaphone")
                                .foregroundColor(.orange)
                            Text("広告スペース (Mock)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("AdMob ID: 6336946049")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                    )
            }
            .background(Color(UIColor.systemBackground))
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