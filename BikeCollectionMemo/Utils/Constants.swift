import SwiftUI

struct Constants {
    // 整備記録のカテゴリー定義
    struct MaintenanceCategories {
        static let categories = [
            "エンジン": [
                "オイル": ["エンジンオイル交換", "オイルフィルター交換", "オイルレベル点検"],
                "冷却系": ["クーラント交換", "ラジエーター清掃", "サーモスタット交換"],
                "燃料系": ["燃料フィルター交換", "インジェクター清掃", "燃料ポンプ点検"],
                "点火系": ["スパークプラグ交換", "イグニッションコイル交換", "点火時期調整"]
            ],
            "駆動系": [
                "チェーン": ["チェーン交換", "チェーン清掃・給油", "チェーン張り調整"],
                "スプロケット": ["フロントスプロケット交換", "リアスプロケット交換", "スプロケット点検"],
                "クラッチ": ["クラッチ調整", "クラッチプレート交換", "クラッチワイヤー交換"]
            ],
            "ブレーキ": [
                "ブレーキパッド": ["フロントパッド交換", "リアパッド交換", "パッド残量点検"],
                "ブレーキフルード": ["ブレーキフルード交換", "エア抜き", "フルード量点検"],
                "ブレーキディスク": ["ローター点検", "ローター交換", "ディスク清掃"]
            ],
            "サスペンション": [
                "フロント": ["フロントフォークオイル交換", "フォークシール交換", "スプリング交換"],
                "リア": ["リアショック交換", "リアショック調整", "スプリング調整"]
            ],
            "タイヤ・ホイール": [
                "タイヤ": ["フロントタイヤ交換", "リアタイヤ交換", "タイヤ空気圧調整"],
                "ホイール": ["ホイールバランス調整", "ホイール清掃", "ベアリング交換"]
            ],
            "電装系": [
                "バッテリー": ["バッテリー交換", "バッテリー充電", "バッテリー点検"],
                "ライト": ["ヘッドライト交換", "テールライト交換", "ウインカー交換"],
                "その他": ["ホーン点検", "メーター点検", "配線点検"]
            ],
            "外装・その他": [
                "清掃": ["洗車", "ワックス", "チェーン清掃"],
                "点検": ["定期点検", "車検", "保険更新"],
                "修理": ["転倒修理", "傷修理", "その他修理"]
            ]
        ]
        
        static func getAllCategories() -> [String] {
            return Array(categories.keys).sorted()
        }
        
        static func getSubcategories(for category: String) -> [String] {
            guard let subcategories = categories[category] else { return [] }
            return Array(subcategories.keys).sorted()
        }
        
        static func getItems(for category: String, subcategory: String) -> [String] {
            return categories[category]?[subcategory] ?? []
        }
    }
    
    // 部品の優先度
    struct PartsPriority {
        static let priorities = ["高", "中", "低"]
    }
    
    // カラーテーマ
    struct Colors {
        static let primary = Color("Primary")
        static let secondary = Color("Secondary")
        static let accent = Color("Accent")
        static let background = Color("Background")
        static let surface = Color("Surface")
        static let onPrimary = Color("OnPrimary")
        static let onSecondary = Color("OnSecondary")
        static let onBackground = Color("OnBackground")
        static let onSurface = Color("OnSurface")
        static let error = Color("Error")
        static let success = Color("Success")
        static let warning = Color("Warning")
        
        // システムカラーのフォールバック
        static let primaryFallback = Color.blue
        static let secondaryFallback = Color.gray
        static let accentFallback = Color.orange
        static let backgroundFallback = Color(.systemBackground)
        static let surfaceFallback = Color(.systemGray6)
    }
    
    // フォントサイズ
    struct FontSizes {
        static let extraLarge: CGFloat = 28
        static let large: CGFloat = 24
        static let title: CGFloat = 20
        static let body: CGFloat = 16
        static let caption: CGFloat = 14
        static let small: CGFloat = 12
    }
    
    // スペーシング
    struct Spacing {
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    // コーナーRadius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    // 設定のキー
    struct SettingsKeys {
        static let raceRecordEnabled = "raceRecordEnabled"
        static let debugModeEnabled = "debugModeEnabled"
        static let debugPremiumEnabled = "debugPremiumEnabled"
    }
    
    // 開発設定
    struct Development {
        // 本番リリース時にfalseに変更
        static let showDeveloperSettings = true
    }
}