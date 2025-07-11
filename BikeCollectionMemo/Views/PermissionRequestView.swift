import SwiftUI
import AppTrackingTransparency

struct PermissionRequestView: View {
    @StateObject private var permissionManager = PermissionManager()
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showingPermissionRequest = false
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.2, green: 0.3, blue: 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // ヘッダー
                    VStack(spacing: 15) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("プライバシーとアクセス許可")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("BikeCollectionMemoをより良く使用するために、以下の許可をお願いします")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // 許可項目
                    VStack(spacing: 20) {
                        PermissionCard(
                            icon: "bell.fill",
                            title: "通知",
                            description: "整備時期のリマインダーや重要なお知らせを受け取れます",
                            status: permissionManager.notificationStatusString,
                            isGranted: permissionManager.notificationStatus == .authorized
                        )
                        
                        if #available(iOS 14, *) {
                            PermissionCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "トラッキング",
                                description: "アプリの改善とパーソナライズされた広告配信のために使用されます",
                                status: permissionManager.trackingStatusString,
                                isGranted: permissionManager.trackingStatus == .authorized
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // データ保護に関する説明
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.green)
                            Text("あなたのプライバシーを保護します")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            PrivacyPoint(text: "個人データは暗号化して保存されます")
                            PrivacyPoint(text: "データはデバイス内に安全に保管されます")
                            PrivacyPoint(text: "許可はいつでも設定から変更できます")
                            PrivacyPoint(text: "不要な情報は一切収集しません")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 30)
                    
                    // アクションボタン
                    VStack(spacing: 15) {
                        Button(action: {
                            requestPermissions()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                Text("許可を設定")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(showingPermissionRequest)
                        
                        Button(action: {
                            skipPermissions()
                        }) {
                            Text("後で設定する")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            permissionManager.checkCurrentStatuses()
        }
    }
    
    private func requestPermissions() {
        showingPermissionRequest = true
        
        Task {
            await permissionManager.requestPermissions()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showingPermissionRequest = false
                onComplete()
            }
        }
    }
    
    private func skipPermissions() {
        UserDefaults.standard.hasRequestedPermissions = true
        onComplete()
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let status: String
    let isGranted: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isGranted ? .green : .white)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isGranted ? .green : .white.opacity(0.5))
                        .font(.title3)
                    
                    Text(status)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct PrivacyPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
                .padding(.top, 2)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct OnboardingPermissionView: View {
    @State private var showingPermissionRequest = false
    let onComplete: () -> Void
    
    var body: some View {
        VStack {
            if showingPermissionRequest {
                PermissionRequestView(onComplete: onComplete)
            } else {
                // 最初のオンボーディング画面
                OnboardingWelcomeView {
                    showingPermissionRequest = true
                }
            }
        }
    }
}

struct OnboardingWelcomeView: View {
    let onNext: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.2, green: 0.3, blue: 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // ロゴとタイトル
                VStack(spacing: 20) {
                    Image(systemName: "motorcycle")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 10) {
                        Text("BikeCollectionMemo")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("愛車の整備記録を簡単管理")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // 特徴
                VStack(spacing: 20) {
                    FeatureRow(icon: "wrench.and.screwdriver", text: "詳細な整備記録管理")
                    FeatureRow(icon: "gear", text: "部品の購入メモ")
                    FeatureRow(icon: "magnifyingglass", text: "簡単検索機能")
                    FeatureRow(icon: "square.and.arrow.up", text: "データバックアップ")
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // 開始ボタン
                Button(action: onNext) {
                    HStack {
                        Text("はじめる")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 25)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingPermissionView {
        print("Onboarding completed")
    }
}