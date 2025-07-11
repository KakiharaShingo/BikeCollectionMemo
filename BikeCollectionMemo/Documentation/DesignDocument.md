# BikeCollectionMemo 設計書

## 1. プロジェクト概要

### 1.1 目的
個人ユーザーがバイクの整備記録を効率的に管理するためのiOSアプリケーションの開発

### 1.2 対象ユーザー
- バイク愛好者
- 個人でバイクメンテナンスを行うユーザー
- 整備記録を体系的に管理したいユーザー

### 1.3 主要価値提案
- 整備記録の体系的管理
- 部品購入計画の効率化
- データのバックアップと安全性
- 直感的で美しいユーザーインターフェース

## 2. システムアーキテクチャ

### 2.1 アーキテクチャ概要
```
┌─────────────────────────────────────────┐
│            SwiftUI Views                │
├─────────────────────────────────────────┤
│            ViewModels (MVVM)            │
├─────────────────────────────────────────┤
│            Services Layer               │
├─────────────────────────────────────────┤
│            Core Data Stack              │
├─────────────────────────────────────────┤
│          Local Storage (SQLite)         │
└─────────────────────────────────────────┘
```

### 2.2 技術スタック
- **UI Framework**: SwiftUI
- **Architecture Pattern**: MVVM (Model-View-ViewModel)
- **Data Persistence**: Core Data
- **Image Handling**: PhotosUI + UIKit
- **File Management**: FileManager + UniformTypeIdentifiers
- **Permissions**: UserNotifications + AppTrackingTransparency

### 2.3 依存関係図
```
BikeCollectionMemoApp
    ├── ContentView (TabView)
    │   ├── BikeListView
    │   ├── MaintenanceRecordListView
    │   ├── PartsListView
    │   └── SettingsView
    ├── PersistenceController
    ├── ViewModels
    │   ├── BikeViewModel
    │   ├── MaintenanceRecordViewModel
    │   └── PartsMemoViewModel
    └── Services
        ├── BackupService
        └── PermissionManager
```

## 3. データモデル設計

### 3.1 エンティティ関係図 (ERD)
```
    Bike (1) ──────────── (n) MaintenanceRecord
     │
     │
     └─────────────────── (n) PartsMemo
```

### 3.2 Bikeエンティティ
```swift
entity Bike {
    id: UUID               // Primary Key
    name: String           // バイク名
    manufacturer: String   // メーカー
    model: String         // モデル
    year: Int32           // 年式
    imageData: Data?      // 写真データ
    createdAt: Date       // 作成日時
    updatedAt: Date       // 更新日時
    
    // Relationships
    maintenanceRecords: [MaintenanceRecord]
    partsMemos: [PartsMemo]
}
```

### 3.3 MaintenanceRecordエンティティ
```swift
entity MaintenanceRecord {
    id: UUID              // Primary Key
    date: Date           // 実施日
    category: String     // 大項目
    subcategory: String  // 中項目
    item: String        // 小項目
    notes: String       // メモ
    cost: Double        // 費用
    mileage: Int32      // 走行距離
    createdAt: Date     // 作成日時
    updatedAt: Date     // 更新日時
    
    // Relationships
    bike: Bike          // 所属バイク
}
```

### 3.4 PartsMemoエンティティ
```swift
entity PartsMemo {
    id: UUID              // Primary Key
    partName: String      // 部品名
    partNumber: String    // 品番
    description: String   // 説明
    estimatedCost: Double // 予想費用
    priority: String      // 優先度 (高/中/低)
    isPurchased: Bool     // 購入済みフラグ
    createdAt: Date      // 作成日時
    updatedAt: Date      // 更新日時
    
    // Relationships
    bike: Bike           // 所属バイク
}
```

## 4. UI/UX設計

### 4.1 デザインシステム

#### 4.1.1 カラーパレット
```swift
Primary: #007AFF (iOS Blue)
Secondary: #6C7B7F (Gray)
Accent: #FF9500 (Orange)
Background: #F2F2F7 (Light Gray)
Surface: #FFFFFF (White)
Error: #FF3B30 (Red)
Success: #34C759 (Green)
Warning: #FF9500 (Orange)
```

#### 4.1.2 タイポグラフィ
```swift
ExtraLarge: 28pt (見出し1)
Large: 24pt (見出し2)
Title: 20pt (見出し3)
Body: 16pt (本文)
Caption: 14pt (補足)
Small: 12pt (注釈)
```

#### 4.1.3 スペーシング
```swift
ExtraSmall: 4pt
Small: 8pt
Medium: 16pt
Large: 24pt
ExtraLarge: 32pt
```

#### 4.1.4 コーナーRadiusとシャドウ
```swift
CornerRadius:
  Small: 8pt
  Medium: 12pt
  Large: 16pt
  ExtraLarge: 24pt

Shadow:
  Color: Black 5% opacity
  Radius: 2pt
  Offset: (0, 1)
```

### 4.2 画面構成

#### 4.2.1 情報アーキテクチャ
```
App Root
├── Splash Screen (初回のみ)
├── Onboarding (初回のみ)
│   ├── Welcome
│   └── Permission Request
└── Main App (TabView)
    ├── バイク (Tab 1)
    │   ├── バイク一覧
    │   ├── バイク詳細
    │   ├── バイク追加
    │   ├── バイク編集
    │   ├── 整備履歴
    │   └── 部品リスト
    ├── 整備記録 (Tab 2)
    │   ├── 記録一覧
    │   ├── 記録詳細
    │   ├── 記録追加
    │   └── 記録編集
    ├── 部品メモ (Tab 3)
    │   └── 部品一覧
    └── 設定 (Tab 4)
        ├── データ管理
        ├── プレミアム機能
        ├── サポート
        └── アプリについて
```

#### 4.2.2 ナビゲーションパターン
- **タブベースナビゲーション**: メイン機能へのアクセス
- **階層ナビゲーション**: 詳細画面への遷移
- **モーダル表示**: 作成・編集画面
- **シート表示**: 設定・フィルター画面

### 4.3 レスポンシブデザイン

#### 4.3.1 画面サイズ対応
```
iPhone SE (375 x 667): コンパクトレイアウト
iPhone 14 (390 x 844): 標準レイアウト
iPhone 14 Plus (428 x 926): 拡張レイアウト
iPhone 14 Pro Max (430 x 932): 最大レイアウト
```

#### 4.3.2 セーフエリア対応
- StatusBar回避
- HomeIndicator回避
- DynamicIsland対応（Pro機種）

## 5. 機能設計

### 5.1 バイク管理機能

#### 5.1.1 ユースケース
1. **バイク登録**
   - 基本情報入力（名前、メーカー、モデル、年式）
   - 写真アップロード
   - 登録完了

2. **バイク一覧表示**
   - カード形式での表示
   - 検索機能
   - 統計情報表示

3. **バイク詳細表示**
   - 基本情報
   - 整備統計
   - 最近の整備記録
   - 部品メモ

4. **バイク編集**
   - 情報の更新
   - 写真の変更
   - 削除

#### 5.1.2 ビジネスルール
- バイク名は必須
- 写真は1枚まで
- 削除時は関連データも削除

### 5.2 整備記録管理機能

#### 5.2.1 階層分類システム
```
大項目 (Category)
├── エンジン
│   ├── オイル (中項目)
│   │   ├── エンジンオイル交換 (小項目)
│   │   ├── オイルフィルター交換
│   │   └── オイルレベル点検
│   ├── 冷却系
│   │   ├── クーラント交換
│   │   └── ラジエーター清掃
│   └── 燃料系
├── 駆動系
├── ブレーキ
├── サスペンション
├── タイヤ・ホイール
├── 電装系
└── 外装・その他
```

#### 5.2.2 データ検証
```swift
// 必須フィールド
- category: String (必須)
- subcategory: String (必須)
- item: String (必須)
- date: Date (必須)

// オプションフィールド
- cost: Double (0以上)
- mileage: Int32 (0以上)
- notes: String (最大1000文字)
```

### 5.3 部品メモ機能

#### 5.3.1 優先度システム
```swift
enum Priority: String, CaseIterable {
    case high = "高"    // Red
    case medium = "中"  // Orange  
    case low = "低"     // Green
}
```

#### 5.3.2 フィルタリング機能
- 購入状態別（未購入/購入済み/すべて）
- 優先度別
- バイク別
- 検索（部品名、品番、説明）

### 5.4 検索機能

#### 5.4.1 検索対象
```swift
// バイク検索
- name, manufacturer, model

// 整備記録検索  
- category, subcategory, item, notes

// 部品メモ検索
- partName, partNumber, description
```

#### 5.4.2 検索アルゴリズム
- 部分文字列マッチング
- 大文字小文字の区別なし
- 複数フィールドのOR検索

### 5.5 データバックアップ・復元機能

#### 5.5.1 エクスポート仕様
```
BackupFolder/
├── bikes.csv
├── maintenance_records.csv
├── parts_memos.csv
└── images/
    ├── {bike_id_1}.jpg
    ├── {bike_id_2}.jpg
    └── ...
```

#### 5.5.2 CSVフォーマット
```csv
# bikes.csv
ID,Name,Manufacturer,Model,Year,HasImage,CreatedAt,UpdatedAt

# maintenance_records.csv  
ID,BikeID,Date,Category,Subcategory,Item,Notes,Cost,Mileage,CreatedAt,UpdatedAt

# parts_memos.csv
ID,BikeID,PartName,PartNumber,Description,EstimatedCost,Priority,IsPurchased,CreatedAt,UpdatedAt
```

## 6. セキュリティ設計

### 6.1 データ保護

#### 6.1.1 暗号化
- Core Data: SQLiteファイルの暗号化
- 写真データ: Core Data Binary型での保存
- バックアップ: ユーザー責任（将来的にZIP暗号化検討）

#### 6.1.2 アクセス制御
- App Sandbox: システム標準のサンドボックス
- データアクセス: アプリ内のみ
- 外部共有: ユーザー明示的操作のみ

### 6.2 プライバシー

#### 6.2.1 データ収集
```
収集するデータ:
- バイク情報（ユーザー入力）
- 整備記録（ユーザー入力）
- 部品メモ（ユーザー入力）
- 写真（ユーザー選択）

収集しないデータ:
- 位置情報
- 連絡先
- カレンダー
- 個人識別子（IDFA使用時は同意後のみ）
```

#### 6.2.2 許可管理
```swift
通知許可:
- 目的: 整備リマインダー
- タイミング: オンボーディング時
- 必須性: 任意

トラッキング許可 (iOS 14+):
- 目的: アプリ改善、広告パーソナライゼーション
- タイミング: オンボーディング時
- 必須性: 任意
```

## 7. パフォーマンス設計

### 7.1 レスポンス目標

#### 7.1.1 画面遷移
```
画面表示: < 500ms
データ読み込み: < 1000ms  
検索実行: < 200ms
保存操作: < 500ms
```

#### 7.1.2 メモリ使用量
```
基本動作: < 50MB
写真含む: < 100MB
大量データ: < 150MB
```

### 7.2 最適化戦略

#### 7.2.1 Core Data最適化
```swift
// FetchRequest最適化
- fetchLimit: 適切な制限
- sortDescriptors: インデックス活用
- predicate: 効率的なフィルタリング
- batchSize: メモリ効率

// リレーション最適化
- faultingを活用した遅延読み込み
- NSFetchedResultsControllerの活用
```

#### 7.2.2 UI最適化
```swift
// SwiftUI最適化
- LazyVStack: 大量データ対応
- @State最小化: 不要な再描画防止
- GeometryReader使用最小化: レイアウト効率
- AsyncImage: 画像遅延読み込み
```

## 8. エラーハンドリング設計

### 8.1 エラー分類

#### 8.1.1 データエラー
```swift
enum DataError: Error {
    case invalidInput(String)
    case saveFailure(Error)
    case fetchFailure(Error)
    case deleteFailure(Error)
}
```

#### 8.1.2 ファイルエラー
```swift
enum FileError: Error {
    case exportFailure(Error)
    case importFailure(Error)
    case csvParseError(String)
    case imageLoadError(Error)
}
```

### 8.2 エラー表示戦略

#### 8.2.1 ユーザー向けメッセージ
```
データ保存エラー: 「保存に失敗しました。もう一度お試しください。」
ネットワークエラー: 「通信に失敗しました。接続を確認してください。」
ファイルエラー: 「ファイルの読み込みに失敗しました。」
```

#### 8.2.2 表示方法
- Alert: 重要なエラー
- Toast: 軽微なエラー
- インライン: 入力検証エラー

## 9. テスト設計

### 9.1 テスト戦略

#### 9.1.1 テストピラミッド
```
E2E Tests (少数)
├── 主要ユーザーフロー
└── 統合テスト

Integration Tests (中程度)  
├── ViewModelとCore Data
├── サービス間連携
└── API統合

Unit Tests (多数)
├── ビジネスロジック
├── データ変換
├── バリデーション
└── ユーティリティ
```

#### 9.1.2 テスト対象優先度
```
高優先度:
- データ保存・読み込み
- 検索機能
- バックアップ・復元
- 計算ロジック

中優先度:
- UI表示ロジック
- 入力検証
- エラーハンドリング

低優先度:
- アニメーション
- デザイン詳細
```

### 9.2 テストデータ

#### 9.2.1 サンプルデータ
```swift
// テスト用バイクデータ
let testBikes = [
    Bike(name: "CBR600RR", manufacturer: "Honda", model: "CBR600RR", year: 2020),
    Bike(name: "YZF-R6", manufacturer: "Yamaha", model: "YZF-R6", year: 2019),
    Bike(name: "GSX-R750", manufacturer: "Suzuki", model: "GSX-R750", year: 2021)
]

// テスト用整備記録
let testRecords = [
    MaintenanceRecord(category: "エンジン", subcategory: "オイル", item: "オイル交換", cost: 3000),
    MaintenanceRecord(category: "ブレーキ", subcategory: "パッド", item: "パッド交換", cost: 8000)
]
```

## 10. 品質保証

### 10.1 コード品質

#### 10.1.1 静的解析
- SwiftLint: コーディング規約チェック
- Xcode Analyzer: 潜在的バグ検出
- Code Coverage: テストカバレッジ測定

#### 10.1.2 コードレビュー
- プルリクエストベース
- チェックリスト活用
- セキュリティ観点の確認

### 10.2 リリース前チェック

#### 10.2.1 機能テスト
```
□ 基本機能動作確認
□ エラーケース動作確認  
□ パフォーマンス測定
□ メモリリークチェック
□ クラッシュテスト
```

#### 10.2.2 デバイステスト
```
□ iPhone SE (第3世代)
□ iPhone 14
□ iPhone 14 Pro Max
□ 各iOS バージョン (15.0, 16.0, 17.0)
```

## 11. 運用・保守設計

### 11.1 ログ設計

#### 11.1.1 ログレベル
```swift
enum LogLevel {
    case debug   // 開発時のみ
    case info    // 一般情報
    case warning // 警告
    case error   // エラー
}
```

#### 11.1.2 ログ出力先
- Development: Console.app
- Production: OSログシステム
- 外部送信: なし（プライバシー保護）

### 11.2 更新戦略

#### 11.2.1 バージョニング
```
Major.Minor.Patch (例: 1.2.3)
- Major: 破壊的変更
- Minor: 新機能追加
- Patch: バグフィックス
```

#### 11.2.2 データマイグレーション
```swift
// Core Data Migration
- Lightweight Migration: 軽微な変更
- Custom Migration: 複雑な変更
- Version Management: .xcdatamodeld複数版
```

## 12. 将来拡張設計

### 12.1 スケーラビリティ

#### 12.1.1 アーキテクチャ拡張性
```
現在: Local-First Architecture
将来: Cloud-Sync Architecture
    ├── CloudKit Integration
    ├── Real-time Sync
    └── Conflict Resolution
```

#### 12.1.2 機能拡張性
```
Phase 2:
- サブスクリプション機能
- 広告システム
- プッシュ通知

Phase 3:
- ソーシャル機能
- データ分析
- AI推奨機能
```

### 12.2 技術的負債対策

#### 12.2.1 コード健全性
- 定期的なリファクタリング
- 技術スタック更新
- パフォーマンス監視

#### 12.2.2 依存関係管理
- 最小限の外部依存
- バージョン固定
- セキュリティ更新追跡

この設計書は開発の進行に応じて継続的に更新され、最新の実装状況を反映するものとします。