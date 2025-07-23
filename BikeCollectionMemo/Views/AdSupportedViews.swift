import SwiftUI

// MARK: - Ad-Supported View Wrapper

struct AdSupportedView<Content: View>: View {
    let content: Content
    @StateObject private var adMobManager = AdMobManager.shared
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // バナー広告を画面下部に表示
            if adMobManager.shouldShowAds() {
                BannerAdView()
            }
        }
    }
}

// MARK: - Interstitial Ad Trigger

struct InterstitialAdTrigger: ViewModifier {
    @StateObject private var adMobManager = AdMobManager.shared
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { oldValue, newValue in
                if newValue {
                    // 少し遅延させて自然なタイミングで表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        adMobManager.showInterstitialAdWithCooldown()
                    }
                }
            }
    }
}

extension View {
    func interstitialAd(trigger: Bool) -> some View {
        modifier(InterstitialAdTrigger(trigger: trigger))
    }
}

// MARK: - Ad-Free Promotion Banner

struct AdFreePromotionBanner: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingUpgrade = false
    
    var body: some View {
        if !subscriptionManager.isSubscribed {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("広告を非表示にしませんか？")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("プレミアムプランで快適に利用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("アップグレード") {
                    showingUpgrade = true
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.orange, .yellow]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .padding(Constants.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, Constants.Spacing.medium)
            .sheet(isPresented: $showingUpgrade) {
                PremiumUpgradeView()
            }
        }
    }
}

// MARK: - Ad Settings View

struct AdSettingsView: View {
    @StateObject private var adMobManager = AdMobManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingUpgrade = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            Text("広告設定")
                .font(.headline)
            
            if subscriptionManager.isSubscribed {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("プレミアムプラン")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("広告は表示されません")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(Constants.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                        .fill(Color.green.opacity(0.1))
                )
            } else {
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    HStack {
                        Image(systemName: "megaphone")
                            .foregroundColor(.orange)
                        
                        Text("無料プラン")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("広告収入によってアプリの開発・運営を支えています。広告を非表示にするにはプレミアムプランにアップグレードしてください。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button("プレミアムプランを見る") {
                        showingUpgrade = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.top, Constants.Spacing.extraSmall)
                }
                .padding(Constants.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            
            Text("広告について")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.top, Constants.Spacing.small)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                BulletPoint(text: "広告は控えめに表示されます")
                BulletPoint(text: "個人情報は収集されません")
                BulletPoint(text: "不適切な広告をブロックしています")
                BulletPoint(text: "広告収入はアプリの改善に使用されます")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showingUpgrade) {
            PremiumUpgradeView()
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .fontWeight(.bold)
            
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// MARK: - Rewarded Ad Button

struct RewardedAdButton: View {
    let title: String
    let rewardDescription: String
    let onReward: () -> Void
    
    @StateObject private var adMobManager = AdMobManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isLoading = false
    
    var body: some View {
        if !subscriptionManager.isSubscribed {
            Button(action: showRewardedAd) {
                HStack {
                    Image(systemName: "play.circle")
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(rewardDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(Constants.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoading)
        }
    }
    
    private func showRewardedAd() {
        isLoading = true
        
        adMobManager.showRewardedAd {
            isLoading = false
            onReward()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AdFreePromotionBanner()
        
        AdSettingsView()
        
        RewardedAdButton(
            title: "広告を見てボーナス機能を獲得",
            rewardDescription: "30日間の拡張機能アクセス"
        ) {
            print("Reward granted!")
        }
    }
    .padding()
}