# BikeCollectionMemo - バイク整備記録アプリ

## 概要
BikeCollectionMemoは、バイクの整備記録を効率的に管理するためのiOSアプリです。個人使用を想定して開発されており、直感的なUI/UXとフラットデザインを採用しています。

## 主要機能

### ✅ 実装完了機能

#### 1. バイク管理
- **車種登録機能**: バイクの基本情報（名前、メーカー、モデル、年式）の登録
- **写真アップロード**: 各バイクに写真を追加・管理
- **バイク詳細画面**: 統計情報、最近の整備記録、部品メモの表示
- **バイクの編集・削除**: 登録済みバイクの情報更新と削除

#### 2. 整備記録管理
- **階層分類システム**: 大項目→中項目→小項目の3段階分類
- **詳細記録**: 日付、費用、走行距離、メモの記録
- **カテゴリー別管理**: エンジン、駆動系、ブレーキ、サスペンション等
- **記録の編集・削除**: 整備記録の更新と削除機能

#### 3. 部品メモ機能
- **購入予定部品管理**: 部品名、品番、予想費用の記録
- **優先度設定**: 高・中・低の3段階優先度
- **購入状況管理**: 購入済み/未購入の状態管理
- **予算管理**: 未購入部品の総予算表示

#### 4. 検索・フィルター機能
- **全文検索**: バイク、整備記録、部品メモの横断検索
- **カテゴリーフィルター**: 整備記録のカテゴリー別フィルタリング
- **優先度フィルター**: 部品メモの優先度別表示
- **購入状態フィルター**: 購入済み/未購入の切り替え

#### 5. データ管理
- **CSVバックアップ**: 全データのCSV形式エクスポート
- **データ復元**: CSVファイルからのデータインポート
- **写真バックアップ**: バイク写真も含めたバックアップ
- **Core Data**: ローカルデータベースによる高速アクセス

#### 6. UI/UX
- **フラットデザイン**: モダンで直感的なインターフェース
- **アニメーション付き起動画面**: 美しいスプラッシュスクリーン
- **レスポンシブデザイン**: 様々な画面サイズに対応
- **ダークモード対応準備**: システムテーマに準拠

#### 7. プライバシー・許可管理
- **オンボーディング**: 初回起動時の案内画面
- **通知許可**: 整備リマインダー用の通知許可
- **トラッキング許可**: iOS 14+ ATT対応
- **許可状態管理**: 各種許可の状態確認と設定案内

### ⏳ 実装予定機能

#### 1. 収益化機能
- **サブスクリプション**: 2台以上のバイク登録には課金
- **GoogleAdMob広告**: 無料版での広告表示（設定で非表示化可能）
- **プレミアム機能**: 広告オフ、無制限バイク登録

#### 2. 法的ページ
- **プライバシーポリシー**: App Store審査用ページ
- **利用規約（EULA）**: エンドユーザーライセンス規約
- **サポートページ**: ヘルプとサポート情報

#### 3. ユーザーサポート
- **機能要望送信**: sk.shingo.10@gmail.com宛の要望送信機能
- **バグレポート**: 問題報告機能

#### 4. 拡張機能（調査段階）
- **メーカーパーツリスト参照**: 各メーカーの公式パーツリストとの連携
- **整備スケジュール管理**: 定期整備のリマインダー機能
- **費用分析**: 整備費用の統計とグラフ表示

## 技術仕様

### アーキテクチャ
- **フレームワーク**: SwiftUI + Core Data
- **最小対応OS**: iOS 15.0+
- **アーキテクチャパターン**: MVVM
- **データ永続化**: Core Data + CloudKit準備

### 主要ライブラリ
- **PhotosUI**: 写真選択機能
- **UniformTypeIdentifiers**: ファイル管理
- **AppTrackingTransparency**: トラッキング許可
- **UserNotifications**: プッシュ通知

### データモデル
#### Bikeエンティティ
```swift
- id: UUID (Primary Key)
- name: String (バイク名)
- manufacturer: String (メーカー)
- model: String (モデル)
- year: Int32 (年式)
- imageData: Data? (写真データ)
- createdAt: Date
- updatedAt: Date
- maintenanceRecords: [MaintenanceRecord] (1対多)
- partsMemos: [PartsMemo] (1対多)
```

#### MaintenanceRecordエンティティ
```swift
- id: UUID (Primary Key)
- date: Date (実施日)
- category: String (大項目)
- subcategory: String (中項目)
- item: String (小項目)
- notes: String (メモ)
- cost: Double (費用)
- mileage: Int32 (走行距離)
- bike: Bike (多対1)
- createdAt: Date
- updatedAt: Date
```

#### PartsMemoエンティティ
```swift
- id: UUID (Primary Key)
- partName: String (部品名)
- partNumber: String (品番)
- description: String (説明)
- estimatedCost: Double (予想費用)
- priority: String (優先度)
- isPurchased: Bool (購入済みフラグ)
- bike: Bike (多対1)
- createdAt: Date
- updatedAt: Date
```

## ファイル構成

```
BikeCollectionMemo/
├── BikeCollectionMemoApp.swift         # アプリエントリーポイント
├── ContentView.swift                   # メインタブビュー
├── PersistenceController.swift         # Core Data管理
├── Models/
│   ├── BikeExtensions.swift           # Core Dataエンティティ拡張
│   └── BikeCollectionMemo.xcdatamodeld # Core Dataモデル
├── ViewModels/
│   └── BikeViewModel.swift            # ビジネスロジック
├── Views/
│   ├── SplashScreenView.swift         # 起動画面
│   ├── PermissionRequestView.swift    # 許可要求画面
│   ├── BikeListView.swift            # バイク一覧
│   ├── BikeDetailView.swift          # バイク詳細
│   ├── AddBikeView.swift             # バイク追加
│   ├── EditBikeView.swift            # バイク編集
│   ├── MaintenanceRecordListView.swift # 整備記録一覧
│   ├── MaintenanceRecordDetailView.swift # 整備記録詳細
│   ├── AddMaintenanceRecordView.swift # 整備記録追加
│   ├── EditMaintenanceRecordView.swift # 整備記録編集
│   ├── BikeMaintenanceHistoryView.swift # バイク別整備履歴
│   ├── PartsListView.swift           # 部品メモ一覧
│   ├── AddPartsView.swift            # 部品メモ追加
│   ├── BikePartsListView.swift       # バイク別部品リスト
│   └── SettingsView.swift            # 設定画面
├── Services/
│   ├── BackupService.swift           # バックアップ・復元
│   └── PermissionManager.swift       # 許可管理
├── Utils/
│   └── Constants.swift               # 定数・設定
└── Documentation/
    ├── README.md                     # このファイル
    └── ImplementationNotes.md        # 実装メモ
```

## セットアップ手順

1. **Xcodeプロジェクトを開く**
   ```
   open BikeCollectionMemo.xcodeproj
   ```

2. **必要な権限を Info.plist に追加**
   ```xml
   <key>NSUserTrackingUsageDescription</key>
   <string>アプリの改善とパーソナライズされた広告配信のために使用されます</string>
   
   <key>NSPhotoLibraryUsageDescription</key>
   <string>バイクの写真を追加するために使用されます</string>
   ```

3. **ビルドして実行**
   - Command + R でビルド・実行
   - シミュレーターまたは実機で動作確認

## 今後の開発予定

### フェーズ2: 収益化機能
- App Store Connect でのIn-App Purchase設定
- StoreKit 2を使用したサブスクリプション実装
- GoogleAdMob SDKの統合

### フェーズ3: クラウド同期
- CloudKitを使用したデータ同期
- 複数デバイス間でのデータ共有

### フェーズ4: 高度な分析機能
- 整備費用の統計とグラフ
- 整備スケジュールの最適化提案
- 機械学習を使用した整備タイミング予測

## 開発者情報
- **開発者**: BikeCollectionMemo Development Team
- **連絡先**: sk.shingo.10@gmail.com
- **リポジトリ**: BikeCollectionMemo
- **ライセンス**: All rights reserved

## 更新履歴
- **v1.0.0** (2025年6月): 初期リリース予定
  - 基本的なバイク管理機能
  - 整備記録管理
  - 部品メモ機能
  - データバックアップ・復元