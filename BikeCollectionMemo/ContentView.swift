//
//  ContentView.swift
//  BikeCollectionMemo
//
//  Created by 垣原親伍 on 2025/06/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    @State private var interstitialTrigger = false
    
    var body: some View {
        AdSupportedView {
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
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("設定")
                    }
                    .tag(3)
            }
            .accentColor(Constants.Colors.primaryFallback)
            .onChange(of: selectedTab) { newTab in
                // タブ切り替え時に時々インタースティシャル広告を表示
                if shouldShowInterstitialOnTabChange() {
                    interstitialTrigger.toggle()
                }
            }
            .interstitialAd(trigger: interstitialTrigger)
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
