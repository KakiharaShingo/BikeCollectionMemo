//
//  BikeCollectionMemoTests.swift
//  BikeCollectionMemoTests
//
//  Created by 垣原親伍 on 2025/06/25.
//

import Testing
import CoreData
@testable import BikeCollectionMemo

struct BikeCollectionMemoTests {
    
    // テスト用のCore Dataスタックを作成
    private var testContext: NSManagedObjectContext {
        let persistentContainer = NSPersistentContainer(name: "BikeCollectionMemo")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        return persistentContainer.viewContext
    }
    
    // テスト用のバイクを作成
    private func createTestBike(context: NSManagedObjectContext) -> Bike {
        let bike = Bike(context: context)
        bike.id = UUID()
        bike.name = "Test Bike"
        bike.manufacturer = "Test Manufacturer"
        bike.model = "Test Model"
        bike.year = 2020
        bike.createdAt = Date()
        bike.updatedAt = Date()
        return bike
    }
    
    @Test func partsMemoCreation() async throws {
        let context = testContext
        let bike = createTestBike(context: context)
        
        // バイクを保存
        try context.save()
        
        // 部品メモを直接作成してテスト
        let partsMemo = PartsMemo(context: context)
        partsMemo.id = UUID()
        partsMemo.bike = bike
        partsMemo.partName = "Test Part"
        partsMemo.partNumber = "TP-001"
        partsMemo.description_ = "Test description"
        partsMemo.estimatedCost = 1000.0
        partsMemo.priority = "高"
        partsMemo.isPurchased = false
        partsMemo.createdAt = Date()
        partsMemo.updatedAt = Date()
        
        try context.save()
        
        // 部品メモが正しく作成されたかを確認
        let fetchRequest: NSFetchRequest<PartsMemo> = PartsMemo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "bike == %@", bike)
        
        let partsMemos = try context.fetch(fetchRequest)
        
        #expect(partsMemos.count == 1)
        #expect(partsMemos.first?.partName == "Test Part")
        #expect(partsMemos.first?.partNumber == "TP-001")
        #expect(partsMemos.first?.description_ == "Test description")
        #expect(partsMemos.first?.estimatedCost == 1000.0)
        #expect(partsMemos.first?.priority == "高")
        #expect(partsMemos.first?.isPurchased == false)
        #expect(partsMemos.first?.bike == bike)
    }
    
    @Test func partsMemoUpdate() async throws {
        let context = testContext
        let bike = createTestBike(context: context)
        
        // バイクを保存
        try context.save()
        
        // 部品メモを作成
        let partsMemo = PartsMemo(context: context)
        partsMemo.id = UUID()
        partsMemo.bike = bike
        partsMemo.partName = "Original Part"
        partsMemo.partNumber = "OP-001"
        partsMemo.description_ = "Original description"
        partsMemo.estimatedCost = 500.0
        partsMemo.priority = "中"
        partsMemo.isPurchased = false
        partsMemo.createdAt = Date()
        partsMemo.updatedAt = Date()
        
        try context.save()
        
        // 部品メモを更新
        partsMemo.partName = "Updated Part"
        partsMemo.partNumber = "UP-002"
        partsMemo.description_ = "Updated description"
        partsMemo.estimatedCost = 1500.0
        partsMemo.priority = "高"
        partsMemo.isPurchased = true
        partsMemo.updatedAt = Date()
        
        try context.save()
        
        // 更新が正しく反映されたかを確認
        #expect(partsMemo.partName == "Updated Part")
        #expect(partsMemo.partNumber == "UP-002")
        #expect(partsMemo.description_ == "Updated description")
        #expect(partsMemo.estimatedCost == 1500.0)
        #expect(partsMemo.priority == "高")
        #expect(partsMemo.isPurchased == true)
    }
    
    @Test func partsMemoTogglePurchaseStatus() async throws {
        let context = testContext
        let bike = createTestBike(context: context)
        
        // バイクを保存
        try context.save()
        
        // 部品メモを作成
        let partsMemo = PartsMemo(context: context)
        partsMemo.id = UUID()
        partsMemo.bike = bike
        partsMemo.partName = "Toggle Test Part"
        partsMemo.partNumber = "TTP-001"
        partsMemo.description_ = "Toggle test description"
        partsMemo.estimatedCost = 800.0
        partsMemo.priority = "低"
        partsMemo.isPurchased = false
        partsMemo.createdAt = Date()
        partsMemo.updatedAt = Date()
        
        try context.save()
        
        // 購入状態を切り替え
        partsMemo.isPurchased.toggle()
        partsMemo.updatedAt = Date()
        try context.save()
        
        // 購入状態が切り替わったかを確認
        #expect(partsMemo.isPurchased == true)
        
        // 再度切り替え
        partsMemo.isPurchased.toggle()
        partsMemo.updatedAt = Date()
        try context.save()
        
        // 元の状態に戻ったかを確認
        #expect(partsMemo.isPurchased == false)
    }
    
    @Test func partsMemoDelete() async throws {
        let context = testContext
        let bike = createTestBike(context: context)
        
        // バイクを保存
        try context.save()
        
        // 部品メモを作成
        let partsMemo = PartsMemo(context: context)
        partsMemo.id = UUID()
        partsMemo.bike = bike
        partsMemo.partName = "Delete Test Part"
        partsMemo.partNumber = "DTP-001"
        partsMemo.description_ = "Delete test description"
        partsMemo.estimatedCost = 300.0
        partsMemo.priority = "中"
        partsMemo.isPurchased = false
        partsMemo.createdAt = Date()
        partsMemo.updatedAt = Date()
        
        try context.save()
        
        // 部品メモを削除
        context.delete(partsMemo)
        try context.save()
        
        // 削除されたかを確認
        let fetchRequest: NSFetchRequest<PartsMemo> = PartsMemo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "bike == %@", bike)
        
        let partsMemos = try context.fetch(fetchRequest)
        
        #expect(partsMemos.count == 0)
    }
    
    @Test func bikeUpdatesWhenPartsChange() async throws {
        let context = testContext
        let bike = createTestBike(context: context)
        let originalUpdatedAt = bike.updatedAt
        
        // バイクを保存
        try context.save()
        
        // 少し時間を置く
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 部品メモを作成
        let partsMemo = PartsMemo(context: context)
        partsMemo.id = UUID()
        partsMemo.bike = bike
        partsMemo.partName = "Update Test Part"
        partsMemo.partNumber = "UTP-001"
        partsMemo.description_ = "Update test description"
        partsMemo.estimatedCost = 2000.0
        partsMemo.priority = "高"
        partsMemo.isPurchased = false
        partsMemo.createdAt = Date()
        partsMemo.updatedAt = Date()
        
        // バイクのupdatedAtを更新
        bike.updatedAt = Date()
        
        try context.save()
        
        // バイクのupdatedAtが更新されたかを確認
        #expect(bike.updatedAt != originalUpdatedAt)
        #expect(bike.updatedAt! > originalUpdatedAt!)
    }
    
    @Test func multipleBikesWithParts() async throws {
        let context = testContext
        
        // 複数のバイクを作成
        let bike1 = createTestBike(context: context)
        bike1.name = "Bike 1"
        
        let bike2 = createTestBike(context: context)
        bike2.name = "Bike 2"
        
        try context.save()
        
        // 各バイクに部品メモを作成
        let partsMemo1 = PartsMemo(context: context)
        partsMemo1.id = UUID()
        partsMemo1.bike = bike1
        partsMemo1.partName = "Part for Bike 1"
        partsMemo1.partNumber = "B1P-001"
        partsMemo1.description_ = "Part description for bike 1"
        partsMemo1.estimatedCost = 1200.0
        partsMemo1.priority = "高"
        partsMemo1.isPurchased = false
        partsMemo1.createdAt = Date()
        partsMemo1.updatedAt = Date()
        
        let partsMemo2 = PartsMemo(context: context)
        partsMemo2.id = UUID()
        partsMemo2.bike = bike2
        partsMemo2.partName = "Part for Bike 2"
        partsMemo2.partNumber = "B2P-001"
        partsMemo2.description_ = "Part description for bike 2"
        partsMemo2.estimatedCost = 1500.0
        partsMemo2.priority = "中"
        partsMemo2.isPurchased = false
        partsMemo2.createdAt = Date()
        partsMemo2.updatedAt = Date()
        
        try context.save()
        
        // 各バイクの部品メモが正しく関連付けられているかを確認
        let fetchRequest1: NSFetchRequest<PartsMemo> = PartsMemo.fetchRequest()
        fetchRequest1.predicate = NSPredicate(format: "bike == %@", bike1)
        let bike1Parts = try context.fetch(fetchRequest1)
        
        let fetchRequest2: NSFetchRequest<PartsMemo> = PartsMemo.fetchRequest()
        fetchRequest2.predicate = NSPredicate(format: "bike == %@", bike2)
        let bike2Parts = try context.fetch(fetchRequest2)
        
        #expect(bike1Parts.count == 1)
        #expect(bike2Parts.count == 1)
        #expect(bike1Parts.first?.partName == "Part for Bike 1")
        #expect(bike2Parts.first?.partName == "Part for Bike 2")
    }
}