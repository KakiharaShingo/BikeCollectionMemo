import Foundation

class SettingsViewModel: ObservableObject {
    @Published var isRaceRecordEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isRaceRecordEnabled, forKey: Constants.SettingsKeys.raceRecordEnabled)
        }
    }
    
    @Published var isDebugModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDebugModeEnabled, forKey: Constants.SettingsKeys.debugModeEnabled)
        }
    }
    
    @Published var isDebugPremiumEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDebugPremiumEnabled, forKey: Constants.SettingsKeys.debugPremiumEnabled)
            // デバッグプレミアム状態が変更されたらSubscriptionManagerに通知
            NotificationCenter.default.post(name: .debugPremiumStatusChanged, object: nil)
        }
    }
    
    init() {
        // デフォルトはオン
        self.isRaceRecordEnabled = UserDefaults.standard.object(forKey: Constants.SettingsKeys.raceRecordEnabled) as? Bool ?? true
        self.isDebugModeEnabled = UserDefaults.standard.object(forKey: Constants.SettingsKeys.debugModeEnabled) as? Bool ?? false
        self.isDebugPremiumEnabled = UserDefaults.standard.object(forKey: Constants.SettingsKeys.debugPremiumEnabled) as? Bool ?? false
    }
}

extension Notification.Name {
    static let debugPremiumStatusChanged = Notification.Name("debugPremiumStatusChanged")
}