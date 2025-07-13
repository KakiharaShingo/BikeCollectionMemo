//
//  BikeCollectionMemoApp.swift
//  BikeCollectionMemo
//
//  Created by 垣原親伍 on 2025/06/25.
//

import SwiftUI

@main
struct BikeCollectionMemoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
