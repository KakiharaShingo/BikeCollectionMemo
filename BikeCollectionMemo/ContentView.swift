//
//  ContentView.swift
//  BikeCollectionMemo
//
//  Created by 垣原親伍 on 2025/06/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var selectedTab = 0
    @State private var interstitialTrigger = false
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                BikeListView()
                    .tabItem {
                        Image(systemName: "motorcycle")
                        Text("バイク")
                    }
                    .tag(0)
                
                MaintenanceRecordListView()
                    .tabItem {
                        Image(systemName: "wrench.and.screwdriver")
                        Text("整備記録")
                    }
                    .tag(1)
                
                PartsListView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("部品メモ")
                    }
                    .tag(2)

                CheckInMapView()
                    .tabItem {
                        Image(systemName: "mappin.and.ellipse")
                        Text("チェックイン")
                    }
                    .tag(3)

                LapTimerView()
                    .tabItem {
                        Image(systemName: "stopwatch")
                        Text("ラップタイマー")
                    }
                    .tag(4)

                if settingsViewModel.isRaceRecordEnabled {
                    RaceResultListView()
                        .tabItem {
                            Image(systemName: "flag.checkered")
                            Text("レース記録")
                        }
                        .tag(5)
                }

                SettingsView()
                    .environmentObject(settingsViewModel)
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("設定")
                    }
                    .tag(settingsViewModel.isRaceRecordEnabled ? 6 : 5)
            }
            .accentColor(Constants.Colors.primaryFallback)
            .onChange(of: selectedTab) { _, newTab in
                // タブ切り替え時に時々インタースティシャル広告を表示
                if shouldShowInterstitialOnTabChange() {
                    interstitialTrigger.toggle()
                }
            }
            .onChange(of: settingsViewModel.isRaceRecordEnabled) { _, isEnabled in
                // レース記録機能が無効になった場合、レース記録タブにいる場合は設定タブに移動
                if !isEnabled && selectedTab == 5 {
                    selectedTab = 5 // 設定タブ（レース記録無効時のタグ番号）
                }
            }
            .interstitialAd(trigger: interstitialTrigger)
            
            // バナー広告をタブメニューの直上に表示
            BannerAdView()
        }
    }
    
    private func shouldShowInterstitialOnTabChange() -> Bool {
        // 10回に1回の確率で広告を表示
        return Int.random(in: 1...10) == 1
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
