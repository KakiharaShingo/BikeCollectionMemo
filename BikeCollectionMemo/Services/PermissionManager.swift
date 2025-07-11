import Foundation
import UIKit
import UserNotifications
import AppTrackingTransparency
import AdSupport

class PermissionManager: ObservableObject {
    @Published var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var hasRequestedPermissions = false
    
    init() {
        checkCurrentStatuses()
    }
    
    // MARK: - Permission Status Check
    
    func checkCurrentStatuses() {
        trackingStatus = ATTrackingManager.trackingAuthorizationStatus
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Request Permissions
    
    func requestPermissions() async {
        hasRequestedPermissions = true
        
        // まず通知許可を要求
        await requestNotificationPermission()
        
        // iOS 14以降でトラッキング許可を要求
        if #available(iOS 14, *) {
            await requestTrackingPermission()
        }
    }
    
    @MainActor
    private func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            if granted {
                notificationStatus = .authorized
                // 通知許可が得られた場合、リモート通知の登録も行う
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                notificationStatus = .denied
            }
        } catch {
            print("Notification permission request failed: \(error)")
            notificationStatus = .denied
        }
    }
    
    @MainActor
    private func requestTrackingPermission() async {
        if #available(iOS 14, *) {
            let status = await ATTrackingManager.requestTrackingAuthorization()
            trackingStatus = status
            
            switch status {
            case .authorized:
                print("Tracking authorized")
                // 広告識別子が利用可能
                let idfa = ASIdentifierManager.shared().advertisingIdentifier
                print("IDFA: \(idfa)")
            case .denied:
                print("Tracking denied")
            case .notDetermined:
                print("Tracking not determined")
            case .restricted:
                print("Tracking restricted")
            @unknown default:
                print("Unknown tracking status")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    var trackingStatusString: String {
        switch trackingStatus {
        case .authorized:
            return "許可"
        case .denied:
            return "拒否"
        case .notDetermined:
            return "未決定"
        case .restricted:
            return "制限"
        @unknown default:
            return "不明"
        }
    }
    
    var notificationStatusString: String {
        switch notificationStatus {
        case .authorized:
            return "許可"
        case .denied:
            return "拒否"
        case .notDetermined:
            return "未決定"
        case .provisional:
            return "暫定許可"
        case .ephemeral:
            return "一時許可"
        @unknown default:
            return "不明"
        }
    }
    
    var shouldShowPermissionRequest: Bool {
        return !hasRequestedPermissions && 
               (trackingStatus == .notDetermined || notificationStatus == .notDetermined)
    }
    
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - UserDefaults Extension for Permission Tracking

extension UserDefaults {
    private enum Keys {
        static let hasRequestedPermissions = "hasRequestedPermissions"
        static let permissionRequestDate = "permissionRequestDate"
    }
    
    var hasRequestedPermissions: Bool {
        get { bool(forKey: Keys.hasRequestedPermissions) }
        set { set(newValue, forKey: Keys.hasRequestedPermissions) }
    }
    
    var permissionRequestDate: Date? {
        get { object(forKey: Keys.permissionRequestDate) as? Date }
        set { set(newValue, forKey: Keys.permissionRequestDate) }
    }
}