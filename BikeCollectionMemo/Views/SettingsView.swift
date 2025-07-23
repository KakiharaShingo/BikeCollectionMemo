import SwiftUI
import SafariServices

struct SettingsView: View {
    @StateObject private var backupService = BackupService()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @State private var showingBackupAlert = false
    @State private var showingRestoreSheet = false
    @State private var showingSubscriptionSheet = false
    @State private var showingFeedbackSheet = false
    @State private var showingAboutSheet = false
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    
    var body: some View {
        NavigationStack {
            List {
                
                // データ管理セクション
                Section("データ管理") {
                    SettingsRowView(
                        icon: "square.and.arrow.up",
                        title: "バックアップ",
                        subtitle: "CSVファイルで保存",
                        iconColor: .blue
                    ) {
                        showingBackupAlert = true
                    }
                    
                    SettingsRowView(
                        icon: "square.and.arrow.down",
                        title: "復元",
                        subtitle: "CSVファイルから復元",
                        iconColor: .green
                    ) {
                        showingRestoreSheet = true
                    }
                }
                
                // 機能設定セクション
                Section("機能設定") {
                    HStack {
                        HStack(spacing: Constants.Spacing.medium) {
                            ZStack {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: "flag.checkered")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("レース記録機能")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text("レース結果の記録・管理機能")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $settingsViewModel.isRaceRecordEnabled)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }
                
                // 開発者設定セクション（本番リリース時には非表示）
                if Constants.Development.showDeveloperSettings {
                    Section("開発者設定") {
                        HStack {
                            HStack(spacing: Constants.Spacing.medium) {
                                ZStack {
                                    Circle()
                                        .fill(.purple)
                                        .frame(width: 30, height: 30)
                                    
                                    Image(systemName: "hammer.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("デバッグモード")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text("開発・テスト用の設定を表示")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $settingsViewModel.isDebugModeEnabled)
                                .labelsHidden()
                        }
                        .padding(.vertical, 4)
                        
                        if settingsViewModel.isDebugModeEnabled {
                            HStack {
                                HStack(spacing: Constants.Spacing.medium) {
                                    ZStack {
                                        Circle()
                                            .fill(.orange)
                                            .frame(width: 30, height: 30)
                                        
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("デバッグプレミアム")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Text("テスト用プレミアム機能")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $settingsViewModel.isDebugPremiumEnabled)
                                    .labelsHidden()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // プレミアム機能セクション
                Section("プレミアム機能") {
                    SettingsRowView(
                        icon: "crown.fill",
                        title: "プレミアムプラン",
                        subtitle: subscriptionManager.isSubscribed ? "アクティブ - すべての機能が利用可能" : "無制限のバイク登録・優先サポート",
                        // 仮リリース用: 広告関連の文言を一時的に変更
                        // subtitle: subscriptionManager.isSubscribed ? "アクティブ - すべての機能が利用可能" : "無制限のバイク登録・広告なし",
                        iconColor: .orange
                    ) {
                        showingSubscriptionSheet = true
                    }
                }
                
                // 仮リリースでは広告なしのため一時的にコメントアウト
                // Section("広告") {
                //     AdSettingsView()
                // }
                
                // サポートセクション
                Section("サポート") {
                    SettingsRowView(
                        icon: "envelope",
                        title: "機能要望・お問い合わせ",
                        subtitle: "改善提案をお送りください",
                        iconColor: .blue
                    ) {
                        showingFeedbackSheet = true
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingsRowContentView(
                            icon: "hand.raised",
                            title: "プライバシーポリシー",
                            iconColor: .purple,
                            showChevron: false
                        )
                    }
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        SettingsRowContentView(
                            icon: "doc.text",
                            title: "利用規約",
                            iconColor: .gray,
                            showChevron: false
                        )
                    }
                    
                    NavigationLink(destination: HelpSupportView()) {
                        SettingsRowContentView(
                            icon: "questionmark.circle",
                            title: "ヘルプ・サポート",
                            iconColor: .green,
                            showChevron: false
                        )
                    }
                }
                
                // アプリについてセクション
                Section("アプリについて") {
                    SettingsRowView(
                        icon: "info.circle",
                        title: "アプリについて",
                        subtitle: "開発者情報・ライセンス",
                        iconColor: .gray
                    ) {
                        showingAboutSheet = true
                    }
                }
            }
            .background(Constants.Colors.backgroundFallback)
            .navigationTitle("設定")
        }
        .onAppear {
            Task {
                await subscriptionManager.loadProducts()
                await subscriptionManager.updateSubscriptionStatus()
            }
        }
        .alert("バックアップ", isPresented: $showingBackupAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("バックアップ") {
                performBackup()
            }
        } message: {
            Text("すべてのデータをCSVファイルでバックアップしますか？")
        }
        .sheet(isPresented: $showingRestoreSheet) {
            RestoreDataSheet()
        }
        .sheet(isPresented: $showingSubscriptionSheet) {
            if subscriptionManager.isSubscribed {
                PremiumManagementView()
            } else {
                PremiumUpgradeView()
            }
        }
        .sheet(isPresented: $showingFeedbackSheet) {
            FeedbackSheet()
        }
        .sheet(isPresented: $showingAboutSheet) {
            AboutSheet()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let shareURL = shareURL {
                ShareSheet(activityItems: [shareURL])
            }
        }
    }
    
    private func performBackup() {
        if let backupURL = backupService.exportAllData() {
            shareURL = backupURL
            showingShareSheet = true
        }
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SettingsRowContentView(
                icon: icon,
                title: title,
                subtitle: subtitle,
                iconColor: iconColor
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsRowContentView: View {
    let icon: String
    let title: String
    let subtitle: String?
    let iconColor: Color
    let showChevron: Bool
    
    init(icon: String, title: String, subtitle: String? = nil, iconColor: Color, showChevron: Bool = true) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: Constants.Spacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
            
            VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.secondaryFallback)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(Constants.Colors.secondaryFallback)
            }
        }
        .padding(.vertical, Constants.Spacing.extraSmall)
    }
}

struct RestoreDataSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var backupService = BackupService()
    @State private var showingDocumentPicker = false
    @State private var showingRestoreAlert = false
    @State private var restoreURL: URL?
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: Constants.Spacing.large) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(Constants.Colors.accentFallback)
                
                VStack(alignment: .center, spacing: Constants.Spacing.small) {
                    Text("データを復元")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("以前にエクスポートしたバックアップフォルダを選択して、データを復元できます。\n\n※ 現在のデータは全て削除されます。")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Constants.Colors.secondaryFallback)
                }
                
                Button(action: {
                    showingDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "folder")
                        Text("バックアップフォルダを選択")
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
                
                Spacer()
            }
            .padding(Constants.Spacing.large)
            .navigationTitle("データ復元")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    restoreURL = url
                    showingRestoreAlert = true
                }
            case .failure(let error):
                print("Failed to select folder: \(error)")
            }
        }
        .alert("データ復元の確認", isPresented: $showingRestoreAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("復元", role: .destructive) {
                performRestore()
            }
        } message: {
            Text("現在のすべてのデータが削除され、選択したバックアップで置き換えられます。この操作は取り消せません。")
        }
    }
    
    private func performRestore() {
        guard let restoreURL = restoreURL else { return }
        
        let success = backupService.importData(from: restoreURL)
        if success {
            dismiss()
        }
    }
}

// プレミアムユーザー向けステータス表示
struct PremiumStatusView: View {
    let subscriptionManager: SubscriptionManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: Constants.Spacing.medium) {
                // アイコン
                ZStack {
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange, .yellow]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                    HStack {
                        Text("プレミアムプラン")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("アクティブ")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                    
                    Text("すべての機能が利用可能")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.secondaryFallback)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(Constants.Colors.secondaryFallback)
            }
            .padding(.vertical, Constants.Spacing.extraSmall)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 無料ユーザー向けアップグレード促進表示
struct FreeUserUpgradeView: View {
    let subscriptionManager: SubscriptionManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: Constants.Spacing.medium) {
                // アイコン
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
                
                VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                    HStack {
                        Text("プレミアムプラン")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("アップグレード")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.orange)
                            .clipShape(Capsule())
                    }
                    
                    Text("無制限のバイク登録/*・広告なし*/")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.secondaryFallback)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("月額¥380〜")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.secondaryFallback)
                }
            }
            .padding(.vertical, Constants.Spacing.extraSmall)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// プレミアムユーザー向け管理画面
struct PremiumManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
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
                            Text("プレミアムプラン")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("アクティブ")
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    // プレミアム特典
                    VStack(spacing: 15) {
                        Text("利用中の特典")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            PremiumFeatureRow(
                                icon: "infinity",
                                title: "無制限のバイク登録",
                                description: "好きなだけバイクを登録できます",
                                iconColor: .blue
                            )
                            // 仮リリースでは広告なしのため一時的にコメントアウト
//                            PremiumFeatureRow(
//                                icon: "eye.slash.fill",
//                                title: "広告なし",
//                                description: "すっきりした画面で快適にご利用いただけます",
//                                iconColor: .green
//                            )
                            
                            PremiumFeatureRow(
                                icon: "star.fill",
                                title: "優先サポート",
                                description: "お問い合わせに優先的に対応いたします",
                                iconColor: .purple
                            )
                            
                            PremiumFeatureRow(
                                icon: "sparkles",
                                title: "新機能アーリーアクセス",
                                description: "新機能を誰よりも早くお試しいただけます",
                                iconColor: .orange
                            )
                        }
                    }
                    
                    // 管理ボタン
                    VStack(spacing: 15) {
                        Button(action: {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("サブスクリプションを管理")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                        }
                        
                        Button("購入履歴を復元") {
                            Task {
                                await subscriptionManager.restorePurchases()
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    // 法的リンク
                    VStack(spacing: 8) {
                        HStack(spacing: 20) {
                            Button("利用規約") {
                                if let url = URL(string: "https://kakiharashingo.github.io/BikeCollectionMemo/terms-of-service.html") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            
                            Button("プライバシーポリシー") {
                                if let url = URL(string: "https://kakiharashingo.github.io/BikeCollectionMemo/privacy-policy.html") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        Text("いつもBikeCollectionMemoをご利用いただき、ありがとうございます！")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(Constants.Spacing.medium)
            }
            .navigationTitle("プレミアムプラン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: Constants.Spacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
            
            VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.secondaryFallback)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
    }
}

struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackType: FeedbackType = .featureRequest
    @State private var subject = ""
    @State private var message = ""
    @State private var deviceInfo = ""
    @State private var showingSendAlert = false
    @State private var sendSuccess = false
    
    enum FeedbackType: String, CaseIterable {
        case featureRequest = "機能要望"
        case bugReport = "バグ報告"
        case general = "一般的なお問い合わせ"
        
        var icon: String {
            switch self {
            case .featureRequest: return "lightbulb"
            case .bugReport: return "exclamationmark.triangle"
            case .general: return "envelope"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("お問い合わせの種類") {
                    Picker("種類", selection: $feedbackType) {
                        ForEach(FeedbackType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // 選択された種類の詳細表示
                    HStack(spacing: Constants.Spacing.small) {
                        Image(systemName: feedbackType.icon)
                            .font(.title3)
                            .foregroundColor(Constants.Colors.accentFallback)
                        
                        Text(feedbackType.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, Constants.Spacing.small)
                    .padding(.horizontal, Constants.Spacing.medium)
                    .background(Constants.Colors.surfaceFallback)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                }
                
                Section("件名") {
                    TextField("簡潔に内容を説明してください", text: $subject)
                }
                
                Section("詳細") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(feedbackPrompt)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $message)
                            .frame(minHeight: 120)
                    }
                }
                
                Section("デバイス情報") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("自動収集されたデバイス情報:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(deviceInfo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Section {
                    Button(action: sendFeedback) {
                        HStack {
                            Image(systemName: "paperplane")
                            Text("送信")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Constants.Colors.primaryFallback, Constants.Colors.accentFallback]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(Constants.CornerRadius.large)
                        .shadow(color: Constants.Colors.primaryFallback.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(subject.isEmpty || message.isEmpty)
                    .buttonStyle(PlainButtonStyle())
                } footer: {
                    Text("お問い合わせは sk.shingo.10@gmail.com に送信されます。通常7営業日以内にご返信いたします。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("お問い合わせ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
            .onAppear {
                setupDeviceInfo()
            }
            .alert("送信完了", isPresented: $showingSendAlert) {
                Button("OK") {
                    if sendSuccess {
                        dismiss()
                    }
                }
            } message: {
                if sendSuccess {
                    Text("お問い合わせを送信しました。ご連絡ありがとうございます。")
                } else {
                    Text("送信に失敗しました。メールアプリが設定されているかご確認ください。")
                }
            }
        }
    }
    
    private var feedbackPrompt: String {
        switch feedbackType {
        case .featureRequest:
            return "どのような機能をお求めですか？具体的にお聞かせください。"
        case .bugReport:
            return "どのような問題が発生しましたか？再現手順も含めて詳しく教えてください。"
        case .general:
            return "ご質問やご意見をお聞かせください。"
        }
    }
    
    private func setupDeviceInfo() {
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        
        deviceInfo = """
        App Version: \(appVersion) (\(buildNumber))
        iOS Version: \(device.systemVersion)
        Device Model: \(device.model)
        Device Name: \(device.name)
        """
    }
    
    private func sendFeedback() {
        let emailSubject = "[\(feedbackType.rawValue)] \(subject)"
        let emailBody = """
        \(message)
        
        ---
        デバイス情報:
        \(deviceInfo)
        """
        
        let encodedSubject = emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoURL = "mailto:sk.shingo.10@gmail.com?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let url = URL(string: mailtoURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    DispatchQueue.main.async {
                        sendSuccess = success
                        showingSendAlert = true
                    }
                }
            } else {
                sendSuccess = false
                showingSendAlert = true
            }
        }
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: Constants.Spacing.large) {
                Image(systemName: "motorcycle")
                    .font(.system(size: 80))
                    .foregroundColor(Constants.Colors.accentFallback)
                
                VStack(alignment: .center, spacing: Constants.Spacing.small) {
                    Text("BikeCollectionMemo")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("バージョン 1.0.0")
                        .foregroundColor(.secondary)
                    
                    Text("愛車の整備記録を簡単に管理")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: Constants.Spacing.small) {
                    Text("© 2025 BikeCollectionMemo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(Constants.Spacing.large)
            .navigationTitle("アプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

struct WebView: UIViewControllerRepresentable {
    let url: String
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let webURL = URL(string: url) ?? URL(string: "https://www.apple.com")!
        return SFSafariViewController(url: webURL)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {}
}

struct HelpSupportView: View {
    @State private var searchText = ""
    @State private var selectedFAQ: FAQ?
    @State private var showingContactSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                // クイックアクション
                Section {
                    Button(action: {
                        showingContactSheet = true
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
                            
                            VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                                Text("お問い合わせ")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("直接サポートにお問い合わせ")
                                    .font(.caption)
                                    .foregroundColor(Constants.Colors.secondaryFallback)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Constants.Colors.secondaryFallback)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // よくある質問
                Section("よくある質問") {
                    ForEach(filteredFAQs, id: \.id) { faq in
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                                Text(faq.answer)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                if let steps = faq.steps {
                                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                                        Text("手順:")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                            HStack(alignment: .top, spacing: Constants.Spacing.small) {
                                                Text("\(index + 1).")
                                                    .font(.caption)
                                                    .foregroundColor(Constants.Colors.accentFallback)
                                                    .fontWeight(.semibold)
                                                
                                                Text(step)
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                    }
                                    .padding(.top, Constants.Spacing.small)
                                    .padding(.horizontal, Constants.Spacing.medium)
                                    .padding(.bottom, Constants.Spacing.small)
                                    .background(Constants.Colors.surfaceFallback.opacity(0.5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                                            .stroke(Constants.Colors.accentFallback.opacity(0.3), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
                                }
                            }
                            .padding(.vertical, Constants.Spacing.small)
                        } label: {
                            HStack {
                                Image(systemName: faq.icon)
                                    .font(.title3)
                                    .foregroundColor(faq.iconColor)
                                    .frame(width: 24)
                                
                                Text(faq.question)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                
                // 基本的な使い方
                Section("基本的な使い方") {
                    ForEach(basicUsageGuides, id: \.id) { guide in
                        NavigationLink(destination: UsageGuideDetailView(guide: guide)) {
                            HStack {
                                Image(systemName: guide.icon)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(guide.iconColor)
                                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
                                
                                VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                                    Text(guide.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(guide.subtitle)
                                        .font(.caption)
                                        .foregroundColor(Constants.Colors.secondaryFallback)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // アプリ情報
                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(Constants.Colors.secondaryFallback)
                    }
                    
                    HStack {
                        Text("ビルドバージョン")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(buildNumber)
                            .foregroundColor(Constants.Colors.secondaryFallback)
                    }
                }
            }
            .navigationTitle("ヘルプ・サポート")
            .searchable(text: $searchText, prompt: "質問を検索")
        }
        .sheet(isPresented: $showingContactSheet) {
            FeedbackSheet()
        }
    }
    
    private var filteredFAQs: [FAQ] {
        if searchText.isEmpty {
            return faqs
        } else {
            return faqs.filter { faq in
                faq.question.localizedCaseInsensitiveContains(searchText) ||
                faq.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}

struct FAQ {
    let id = UUID()
    let question: String
    let answer: String
    let icon: String
    let iconColor: Color
    let steps: [String]?
    
    init(question: String, answer: String, icon: String, iconColor: Color, steps: [String]? = nil) {
        self.question = question
        self.answer = answer
        self.icon = icon
        self.iconColor = iconColor
        self.steps = steps
    }
}

struct UsageGuide {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let content: String
    let steps: [GuideStep]
}

struct GuideStep {
    let title: String
    let description: String
    let icon: String
}

struct UsageGuideDetailView: View {
    let guide: UsageGuide
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                // ヘッダー
                VStack(alignment: .center, spacing: Constants.Spacing.medium) {
                    Image(systemName: guide.icon)
                        .font(.system(size: 60))
                        .foregroundColor(guide.iconColor)
                        .frame(maxWidth: .infinity)
                    
                    VStack(spacing: Constants.Spacing.small) {
                        Text(guide.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                        
                        Text(guide.subtitle)
                            .font(.body)
                            .foregroundColor(Constants.Colors.secondaryFallback)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // 概要
                if !guide.content.isEmpty {
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("概要")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(guide.content)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // ステップ
                if !guide.steps.isEmpty {
                    VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                        Text("手順")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: Constants.Spacing.medium) {
                                ZStack {
                                    Circle()
                                        .fill(guide.iconColor)
                                        .frame(width: 32, height: 32)
                                    
                                    Text("\(index + 1)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                                    HStack {
                                        Image(systemName: step.icon)
                                            .font(.title3)
                                            .foregroundColor(guide.iconColor)
                                        
                                        Text(step.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Text(step.description)
                                        .font(.body)
                                        .foregroundColor(Constants.Colors.secondaryFallback)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                            }
                            .padding(Constants.Spacing.medium)
                            .background(Constants.Colors.surfaceFallback)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                        }
                    }
                }
            }
            .padding(Constants.Spacing.medium)
        }
        .navigationTitle(guide.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// よくある質問データ
private let faqs: [FAQ] = [
    FAQ(
        question: "バイクを登録するにはどうすればいいですか？",
        answer: "バイクリスト画面の右上の「+」ボタンをタップして、必要な情報を入力してください。",
        icon: "motorcycle",
        iconColor: .blue,
        steps: [
            "バイクリスト画面を開く",
            "右上の「+」ボタンをタップ",
            "バイク名、メーカー、モデル、年式を入力",
            "必要に応じて写真を追加",
            "「保存」をタップ"
        ]
    ),
    FAQ(
        question: "整備記録を追加するには？",
        answer: "バイクの詳細画面から整備記録セクションの「+」ボタンをタップして記録を追加できます。",
        icon: "wrench.and.screwdriver",
        iconColor: .orange,
        steps: [
            "バイクの詳細画面を開く",
            "整備記録セクションの「+」ボタンをタップ",
            "整備日、カテゴリ、項目を選択",
            "費用や走行距離を入力",
            "写真やメモを追加（任意）",
            "「保存」をタップ"
        ]
    ),
    FAQ(
        question: "部品メモとは何ですか？",
        answer: "購入予定の部品や交換が必要な部品をメモしておく機能です。予算管理や買い物リストとして活用できます。",
        icon: "gear",
        iconColor: .green,
        steps: [
            "バイクの詳細画面を開く",
            "部品メモセクションの「+」ボタンをタップ",
            "部品名、品番、予算を入力",
            "優先度を設定",
            "「保存」をタップ"
        ]
    ),
    FAQ(
        question: "データをバックアップするには？",
        answer: "設定画面のデータ管理セクションからCSVファイルでバックアップできます。",
        icon: "square.and.arrow.up",
        iconColor: .purple,
        steps: [
            "設定画面を開く",
            "「バックアップ」をタップ",
            "確認ダイアログで「バックアップ」を選択",
            "CSVファイルを保存する場所を選択"
        ]
    ),
    FAQ(
        question: "写真を追加できないのはなぜですか？",
        answer: "写真の追加には、設定でアプリに写真へのアクセス許可を与える必要があります。",
        icon: "photo",
        iconColor: .red,
        steps: [
            "iPhoneの設定アプリを開く",
            "「BikeCollectionMemo」を選択",
            "「写真」をタップ",
            "「すべての写真」または「選択した写真」を選択"
        ]
    ),
    FAQ(
        question: "削除したデータを復元できますか？",
        answer: "一度削除したデータは復元できません。重要なデータは定期的にバックアップすることをお勧めします。",
        icon: "exclamationmark.triangle",
        iconColor: .red
    ),
    FAQ(
        question: "プレミアムプランの特典は何ですか？",
        answer: "プレミアムプランでは、無制限のバイク登録、広告の非表示、将来追加される高度な機能をご利用いただけます。",
        icon: "crown.fill",
        iconColor: .orange
    ),
    FAQ(
        question: "アプリの動作が重いときはどうすればいいですか？",
        answer: "アプリを一度終了して再起動するか、iPhoneを再起動してみてください。問題が続く場合はお問い合わせください。",
        icon: "bolt.slash",
        iconColor: .yellow,
        steps: [
            "アプリスイッチャーを開く（ホームボタンをダブルタップまたは画面下から上にスワイプして一時停止）",
            "BikeCollectionMemoアプリを上にスワイプして終了",
            "ホーム画面からアプリを再起動",
            "問題が続く場合はiPhoneを再起動"
        ]
    )
]

// 基本的な使い方ガイド
private let basicUsageGuides: [UsageGuide] = [
    UsageGuide(
        title: "バイクの登録",
        subtitle: "愛車を登録して記録を開始しましょう",
        icon: "plus.circle.fill",
        iconColor: .blue,
        content: "BikeCollectionMemoを使い始める最初のステップは、愛車の登録です。バイクの基本情報を入力することで、その後の整備記録や部品メモを管理できるようになります。",
        steps: [
            GuideStep(
                title: "バイクリスト画面を開く",
                description: "アプリを起動すると最初に表示される画面です。ここに登録済みのバイクが一覧表示されます。",
                icon: "list.bullet"
            ),
            GuideStep(
                title: "新規登録ボタンをタップ",
                description: "画面右上の「+」ボタンをタップして、新しいバイクの登録画面を開きます。",
                icon: "plus"
            ),
            GuideStep(
                title: "基本情報を入力",
                description: "バイク名、メーカー、モデル、年式などの基本情報を入力します。これらの情報は後から編集することも可能です。",
                icon: "pencil"
            ),
            GuideStep(
                title: "写真を追加（任意）",
                description: "愛車の写真を追加することで、一覧画面でも識別しやすくなります。写真の追加は任意です。",
                icon: "camera"
            ),
            GuideStep(
                title: "保存して完了",
                description: "すべての情報を入力したら「保存」ボタンをタップして登録を完了します。",
                icon: "checkmark.circle"
            )
        ]
    ),
    UsageGuide(
        title: "整備記録の管理",
        subtitle: "メンテナンス履歴を記録しましょう",
        icon: "wrench.and.screwdriver.fill",
        iconColor: .orange,
        content: "整備記録機能では、オイル交換、タイヤ交換、点検などのメンテナンス履歴を詳細に記録できます。写真や費用、走行距離も一緒に記録することで、完全な整備履歴を作成できます。",
        steps: [
            GuideStep(
                title: "バイク詳細画面を開く",
                description: "記録したいバイクの詳細画面を表示します。ここで整備記録セクションを確認できます。",
                icon: "motorcycle"
            ),
            GuideStep(
                title: "整備記録を追加",
                description: "整備記録セクションの「+」ボタンをタップして、新しい記録の追加画面を開きます。",
                icon: "plus"
            ),
            GuideStep(
                title: "整備内容を入力",
                description: "実施日、カテゴリ（エンジン、ブレーキなど）、具体的な項目を選択または入力します。",
                icon: "list.bullet.rectangle"
            ),
            GuideStep(
                title: "詳細情報を記録",
                description: "費用、走行距離、メモを入力します。これらの情報は統計表示や将来の参考に活用されます。",
                icon: "textformat.123"
            ),
            GuideStep(
                title: "写真を追加",
                description: "作業前後の写真や部品の写真を追加することで、視覚的な記録も残せます。複数枚の写真を追加可能です。",
                icon: "photo.on.rectangle"
            )
        ]
    ),
    UsageGuide(
        title: "部品メモの活用",
        subtitle: "購入予定の部品を管理しましょう",
        icon: "gear",
        iconColor: .green,
        content: "部品メモ機能は、購入予定の部品や交換が必要な部品をリスト化して管理する機能です。予算の管理や買い物の際のチェックリストとして活用できます。",
        steps: [
            GuideStep(
                title: "部品メモを追加",
                description: "バイクの詳細画面から部品メモセクションの「+」ボタンをタップして、新しい部品メモを作成します。",
                icon: "plus.rectangle.on.folder"
            ),
            GuideStep(
                title: "部品情報を入力",
                description: "部品名、品番、説明、予算などの情報を入力します。品番を記録しておくことで、購入時の間違いを防げます。",
                icon: "tag"
            ),
            GuideStep(
                title: "優先度を設定",
                description: "「高」「中」「低」の3段階で優先度を設定できます。優先度に応じて色分けされ、重要な部品が一目でわかります。",
                icon: "flag"
            ),
            GuideStep(
                title: "購入状況を管理",
                description: "部品を購入したらチェックマークをつけて完了状態にします。完了した部品は一覧から非表示にすることもできます。",
                icon: "checkmark.square"
            )
        ]
    ),
    UsageGuide(
        title: "データのバックアップ",
        subtitle: "大切なデータを安全に保管しましょう",
        icon: "icloud.and.arrow.up",
        iconColor: .purple,
        content: "BikeCollectionMemoでは、CSVファイル形式でデータをバックアップできます。定期的なバックアップにより、万が一の際にもデータを守ることができます。",
        steps: [
            GuideStep(
                title: "設定画面を開く",
                description: "アプリ内の設定画面に移動します。下部のタブバーから「設定」をタップしてください。",
                icon: "gearshape"
            ),
            GuideStep(
                title: "バックアップを実行",
                description: "データ管理セクションの「バックアップ」をタップして、確認ダイアログで実行を選択します。",
                icon: "square.and.arrow.up"
            ),
            GuideStep(
                title: "保存場所を選択",
                description: "ファイルの保存場所を選択します。iCloudドライブやDropboxなどのクラウドストレージがおすすめです。",
                icon: "folder"
            ),
            GuideStep(
                title: "復元方法",
                description: "復元する際は、設定画面の「復元」からバックアップファイルを選択してください。",
                icon: "square.and.arrow.down"
            )
        ]
    )
]

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                // ヘッダー
                VStack(alignment: .center, spacing: Constants.Spacing.medium) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    VStack(spacing: Constants.Spacing.small) {
                        Text("プライバシーポリシー")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("最終更新日：2025年1月11日")
                            .font(.subheadline)
                            .foregroundColor(Constants.Colors.secondaryFallback)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // 内容
                VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                    PolicySection(
                        title: "1. 情報の収集について",
                        content: "BikeCollectionMemo（以下「本アプリ」）は、お客様のプライバシーを尊重し、個人情報の保護に努めています。本アプリでは、以下の情報を収集する場合があります：\n\n• アプリの使用状況に関する統計情報\n• クラッシュレポート等の技術的な診断情報\n• お問い合わせ時にお客様が提供する情報"
                    )
                    
                    PolicySection(
                        title: "2. 情報の利用目的",
                        content: "収集した情報は以下の目的で利用します：\n\n• アプリの機能向上および新機能の開発\n• 技術的な問題の診断と解決\n• お客様からのお問い合わせへの対応\n• 統計分析によるサービス改善"
                    )
                    
                    PolicySection(
                        title: "3. データの保存について",
                        content: "本アプリで入力されたデータ（バイク情報、整備記録、部品メモなど）は、すべてお客様のデバイス内のローカルストレージに保存されます。これらのデータがインターネット経由で外部サーバーに送信されることはありません。"
                    )
                    
                    PolicySection(
                        title: "4. 第三者への提供",
                        content: "お客様の個人情報を、お客様の同意なく第三者に提供することはありません。ただし、以下の場合を除きます：\n\n• 法令に基づく場合\n• お客様の生命、身体または財産の保護のために必要がある場合\n• 公衆衛生の向上または児童の健全な育成の推進のために特に必要がある場合"
                    )
                    
                    PolicySection(
                        title: "5. 広告について",
                        content: "本アプリでは、第三者の広告サービスを利用する場合があります。これらの広告サービスは、お客様の興味に基づいた広告を表示するために、匿名の利用情報を収集する場合があります。"
                    )
                    
                    PolicySection(
                        title: "6. セキュリティ",
                        content: "お客様の個人情報の安全性を確保するため、適切な技術的・組織的措置を講じています。ただし、インターネット上での情報伝達は完全に安全ではないことをご理解ください。"
                    )
                    
                    PolicySection(
                        title: "7. プライバシーポリシーの変更",
                        content: "本プライバシーポリシーは、法令の変更や業務内容の変更に伴い、予告なく変更する場合があります。変更後のプライバシーポリシーは、本アプリ内に掲載した時点で効力を生じるものとします。"
                    )
                    
                    PolicySection(
                        title: "8. お問い合わせ",
                        content: "本プライバシーポリシーに関するお問い合わせは、アプリ内の「機能要望・お問い合わせ」からご連絡ください。"
                    )
                }
            }
            .padding(Constants.Spacing.medium)
        }
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                // ヘッダー
                VStack(alignment: .center, spacing: Constants.Spacing.medium) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: Constants.Spacing.small) {
                        Text("利用規約")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("最終更新日：2025年1月11日")
                            .font(.subheadline)
                            .foregroundColor(Constants.Colors.secondaryFallback)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // 内容
                VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                    PolicySection(
                        title: "第1条（適用）",
                        content: "本規約は、BikeCollectionMemo（以下「本アプリ」）の利用に関して、本アプリの利用者（以下「ユーザー」）と開発者との間の権利義務関係を定めることを目的とし、ユーザーと開発者との間の本アプリの利用に関わる一切の関係に適用されます。"
                    )
                    
                    PolicySection(
                        title: "第2条（利用登録）",
                        content: "本アプリの利用に際して、特別な登録手続きは必要ありません。本アプリをダウンロードし、使用を開始した時点で、本規約に同意したものとみなします。"
                    )
                    
                    PolicySection(
                        title: "第3条（禁止事項）",
                        content: "ユーザーは、本アプリの利用にあたり、以下の行為をしてはなりません：\n\n• 法令または公序良俗に違反する行為\n• 犯罪行為に関連する行為\n• 本アプリのサーバーまたはネットワークの機能を破壊したり、妨害したりする行為\n• 本アプリのリバースエンジニアリング、逆コンパイル、逆アセンブル\n• その他、開発者が不適切と判断する行為"
                    )
                    
                    PolicySection(
                        title: "第4条（本アプリの提供の停止等）",
                        content: "開発者は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本アプリの全部または一部の提供を停止または中断することができるものとします：\n\n• 本アプリにかかるコンピュータシステムの保守点検または更新を行う場合\n• 地震、落雷、火災、停電または天災などの不可抗力により、本アプリの提供が困難となった場合\n• コンピュータまたは通信回線等が事故により停止した場合\n• その他、開発者が本アプリの提供が困難と判断した場合"
                    )
                    
                    PolicySection(
                        title: "第5条（著作権）",
                        content: "本アプリおよび本アプリに関連する一切の情報についての著作権およびその他の知的財産権は、開発者または正当な権利者に帰属し、ユーザーは無断で複製、譲渡、貸与、翻訳、改変、転載、公衆送信（送信可能化を含む）、伝送、配布、出版、営業使用等をしてはならないものとします。"
                    )
                    
                    PolicySection(
                        title: "第6条（免責事項）",
                        content: "開発者は、本アプリに起因してユーザーに生じたあらゆる損害について、一切の責任を負いません。ただし、本アプリに関する開発者とユーザーとの間の契約（本規約を含む）が消費者契約法に定める消費者契約となる場合、この免責規定は適用されません。"
                    )
                    
                    PolicySection(
                        title: "第7条（サービス内容の変更等）",
                        content: "開発者は、ユーザーに通知することなく、本アプリの内容を変更しまたは本アプリの提供を中止することができるものとし、これによってユーザーに生じた損害について一切の責任を負いません。"
                    )
                    
                    PolicySection(
                        title: "第8条（利用規約の変更）",
                        content: "開発者は、必要と判断した場合には、ユーザーに通知することなくいつでも本規約を変更することができるものとします。なお、本規約の変更後、本アプリの利用を開始した場合には、当該ユーザーは変更後の規約に同意したものとみなします。"
                    )
                    
                    PolicySection(
                        title: "第9条（個人情報の取扱い）",
                        content: "開発者は、本アプリの利用によって取得する個人情報については、開発者の「プライバシーポリシー」に従い適切に取り扱うものとします。"
                    )
                    
                    PolicySection(
                        title: "第10条（準拠法・裁判管轄）",
                        content: "本規約の解釈にあたっては、日本法を準拠法とします。本アプリに関して紛争が生じた場合には、開発者の所在地を管轄する裁判所を専属的合意管轄とします。"
                    )
                }
            }
            .padding(Constants.Spacing.medium)
        }
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
    }
}

#Preview {
    SettingsView()
}
