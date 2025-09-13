import CoreData
import SwiftUI

class BikeViewModel: ObservableObject {
    private let persistenceController = PersistenceController.shared

    @Published var bikes: [Bike] = []

    init() {
        fetchBikes()
    }
    
    func createBike(name: String, manufacturer: String, model: String, year: Int32, imageData: Data?) {
        let context = persistenceController.container.viewContext
        
        let bike = Bike(context: context)
        bike.id = UUID()
        bike.name = name
        bike.manufacturer = manufacturer
        bike.model = model
        bike.year = year
        bike.imageData = imageData
        bike.createdAt = Date()
        bike.updatedAt = Date()

        saveContext()
        fetchBikes()
    }

    func updateBike(_ bike: Bike, name: String, manufacturer: String, model: String, year: Int32, imageData: Data?) {
        bike.name = name
        bike.manufacturer = manufacturer
        bike.model = model
        bike.year = year
        if let imageData = imageData {
            bike.imageData = imageData
        }
        bike.updatedAt = Date()

        saveContext()
        fetchBikes()
    }
    
    func deleteBike(_ bike: Bike) {
        let context = persistenceController.container.viewContext
        context.delete(bike)
        saveContext()
        fetchBikes()
    }

    func fetchBikes() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Bike> = Bike.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Bike.createdAt, ascending: false)]

        do {
            bikes = try context.fetch(request)
        } catch {
            print("Error fetching bikes: \(error)")
            bikes = []
        }
    }
    
    private func saveContext() {
        persistenceController.save()
        // UI更新を確実にするため通知を送信
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

class MaintenanceRecordViewModel: ObservableObject {
    private let persistenceController = PersistenceController.shared
    
    func createMaintenanceRecord(
        for bike: Bike,
        date: Date,
        category: String,
        subcategory: String,
        item: String,
        notes: String,
        cost: Double,
        mileage: Int32,
        imageDataArray: [Data] = []
    ) {
        let context = persistenceController.container.viewContext
        
        let record = MaintenanceRecord(context: context)
        record.id = UUID()
        record.bike = bike
        record.date = date
        record.category = category
        record.subcategory = subcategory
        record.item = item
        record.notes = notes
        record.cost = cost
        record.mileage = mileage
        record.createdAt = Date()
        record.updatedAt = Date()
        
        // 写真データを個別のPhotoエンティティとして保存
        for (index, imageData) in imageDataArray.enumerated() {
            let photo = Photo(context: context)
            photo.id = UUID()
            photo.imageData = imageData
            photo.createdAt = Date()
            photo.sortOrder = Int16(index)
            photo.maintenanceRecord = record
        }
        
        saveContext()
    }
    
    func updateMaintenanceRecord(
        _ record: MaintenanceRecord,
        date: Date,
        category: String,
        subcategory: String,
        item: String,
        notes: String,
        cost: Double,
        mileage: Int32,
        imageDataArray: [Data] = []
    ) {
        let context = persistenceController.container.viewContext
        
        record.date = date
        record.category = category
        record.subcategory = subcategory
        record.item = item
        record.notes = notes
        record.cost = cost
        record.mileage = mileage
        record.updatedAt = Date()
        
        // 既存の写真を削除
        if let existingPhotos = record.photos as? Set<Photo> {
            for photo in existingPhotos {
                context.delete(photo)
            }
        }
        
        // 新しい写真データを保存
        for (index, imageData) in imageDataArray.enumerated() {
            let photo = Photo(context: context)
            photo.id = UUID()
            photo.imageData = imageData
            photo.createdAt = Date()
            photo.sortOrder = Int16(index)
            photo.maintenanceRecord = record
        }
        
        saveContext()
    }
    
    func deleteMaintenanceRecord(_ record: MaintenanceRecord) {
        let context = persistenceController.container.viewContext
        context.delete(record)
        saveContext()
    }
    
    private func saveContext() {
        persistenceController.save()
        // UI更新を確実にするため通知を送信
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

class PartsMemoViewModel: ObservableObject {
    private let persistenceController = PersistenceController.shared
    
    func createPartsMemo(
        for bike: Bike,
        partName: String,
        partNumber: String,
        description: String,
        estimatedCost: Double,
        priority: String
    ) {
        let context = persistenceController.container.viewContext
        
        let memo = PartsMemo(context: context)
        memo.id = UUID()
        memo.bike = bike
        memo.partName = partName
        memo.partNumber = partNumber
        memo.description_ = description
        memo.estimatedCost = estimatedCost
        memo.priority = priority
        memo.isPurchased = false
        memo.createdAt = Date()
        memo.updatedAt = Date()
        
        saveContext()
    }
    
    func updatePartsMemo(
        _ memo: PartsMemo,
        partName: String,
        partNumber: String,
        description: String,
        estimatedCost: Double,
        priority: String,
        isPurchased: Bool
    ) {
        memo.partName = partName
        memo.partNumber = partNumber
        memo.description_ = description
        memo.estimatedCost = estimatedCost
        memo.priority = priority
        memo.isPurchased = isPurchased
        memo.updatedAt = Date()
        
        saveContext()
    }
    
    func deletePartsMemo(_ memo: PartsMemo) {
        let context = persistenceController.container.viewContext
        context.delete(memo)
        saveContext()
    }
    
    func togglePurchaseStatus(_ memo: PartsMemo) {
        memo.isPurchased.toggle()
        memo.updatedAt = Date()
        saveContext()
    }
    
    private func saveContext() {
        persistenceController.save()
        // UI更新を確実にするため通知を送信
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}