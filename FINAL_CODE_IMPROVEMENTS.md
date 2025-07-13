# 審査提出前の最終コード改善推奨

## 1. Info.plist の権限説明追加

### 写真アクセス許可の説明
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>バイクの写真や整備記録の写真を保存・表示するために写真ライブラリへのアクセスが必要です。</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>撮影した写真をバイクの記録として保存するために写真ライブラリへのアクセスが必要です。</string>
```

### ATT（App Tracking Transparency）
```xml
<key>NSUserTrackingUsageDescription</key>
<string>広告をパーソナライズして、より関連性の高い広告を表示するために使用されます。</string>
```

## 2. エラーハンドリングの強化

### Core Data エラー対策
```swift
// PersistenceController.swift に追加
extension PersistenceController {
    static func handleCoreDataError(_ error: Error) {
        print("Core Data error: \(error)")
        // 本番環境ではクラッシュレポートサービスに送信
        #if DEBUG
        fatalError("Core Data error: \(error)")
        #endif
    }
}
```

### ネットワークエラー対策（AdMob用）
```swift
// AdMobManager.swift の改善
func handleAdLoadError(_ error: Error) {
    print("Ad load error: \(error)")
    // エラーは表示せず、サイレントに処理
    DispatchQueue.main.async {
        // UIは更新しない（ユーザーには影響させない）
    }
}
```

## 3. パフォーマンス最適化

### 画像の最適化
```swift
// 写真保存時の圧縮処理
extension UIImage {
    func compressedForStorage() -> Data? {
        // 1MB以下に圧縮
        var compression: CGFloat = 0.8
        var data = self.jpegData(compressionQuality: compression)
        
        while let imageData = data, imageData.count > 1_000_000 && compression > 0.1 {
            compression -= 0.1
            data = self.jpegData(compressionQuality: compression)
        }
        
        return data
    }
}
```

### メモリ使用量の最適化
```swift
// 大きな画像の表示時
struct OptimizedImageView: View {
    let imageData: Data
    
    var body: some View {
        if let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onAppear {
                    // 画像サイズをビューサイズに最適化
                }
        }
    }
}
```

## 4. セキュリティ強化

### デバッグ情報の除去
```swift
// Constants.swift での本番環境設定
struct Constants {
    static let isProduction = true // リリース時はtrue
    
    static func debugPrint(_ message: String) {
        #if DEBUG
        if !isProduction {
            print(message)
        }
        #endif
    }
}
```

### API キーの保護
```swift
// AdMobManager.swift でのキー管理
struct AdMobConfiguration {
    #if DEBUG
    static let adUnitID = "ca-app-pub-3940256099942544/2934735716" // テスト用
    #else
    static let adUnitID = "ca-app-pub-YOUR-ACTUAL-ID/XXXXXXX" // 本番用
    #endif
}
```

## 5. ユーザビリティ改善

### ロード状態の明確化
```swift
// 全体的なロード状態管理
class AppStateManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func showError(_ message: String) {
        errorMessage = message
        // 3秒後に自動でクリア
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.errorMessage = nil
        }
    }
}
```

### アクセシビリティ対応
```swift
// 画像にアクセシビリティラベル追加
Image(systemName: "motorcycle")
    .accessibilityLabel("バイクアイコン")
    .accessibilityHint("バイクの情報を表示")
```

## 6. 審査対策の具体的修正

### サブスクリプション表示の改善
```swift
// より明確な価格表示
struct PriceDisplayView: View {
    let product: Product
    
    var pricePerMonth: String {
        if product.id.contains("yearly") {
            let monthlyPrice = product.price / 12
            return String(format: "月額換算 ¥%.0f", monthlyPrice.doubleValue)
        }
        return ""
    }
    
    var body: some View {
        VStack {
            Text(product.displayPrice)
            if !pricePerMonth.isEmpty {
                Text(pricePerMonth)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

### 無料版制限の明確化
```swift
// より親切な制限説明
struct FreePlanLimitView: View {
    let currentBikeCount: Int
    let maxBikes: Int
    
    var body: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
            
            Text("無料プランでは\(maxBikes)台まで登録できます（現在: \(currentBikeCount)台）")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}
```

## 7. 最終チェック項目

### ビルド設定
- [ ] Release構成でビルド
- [ ] デバッグシンボルの除去
- [ ] Bitcode有効化
- [ ] 最新iOSバージョンでのテスト

### 機能テスト
- [ ] 新規インストール時の動作確認
- [ ] データ移行の動作確認
- [ ] 購入・復元機能の動作確認
- [ ] 写真権限の適切な処理
- [ ] 広告表示の適切な処理

### メタデータ最終確認
- [ ] App Store Connect情報入力完了
- [ ] スクリーンショット準備完了
- [ ] アプリアイコン設定完了
- [ ] 年齢制限設定確認

## 8. 想定リジェクト対策

### Guideline 2.1 - Performance
- 十分なテスト実行
- メモリリーク対策
- クラッシュ対策の実装

### Guideline 3.1.2 - Business
- サブスクリプション価値の明確化
- 無料版機能の充実

### Guideline 5.1.1 - Privacy
- プライバシーポリシーの網羅性
- 権限要求の適切な説明

---

**注意**: 本番環境用のAdMob広告IDは別途App Store Connect登録後に設定してください。