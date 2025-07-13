import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // サンプルデータの作成
        let sampleBike = Bike(context: viewContext)
        sampleBike.id = UUID()
        sampleBike.name = "サンプルバイク"
        sampleBike.manufacturer = "Honda"
        sampleBike.model = "CBR600RR"
        sampleBike.year = 2020
        sampleBike.createdAt = Date()
        sampleBike.updatedAt = Date()
        
        let sampleRecord = MaintenanceRecord(context: viewContext)
        sampleRecord.id = UUID()
        sampleRecord.date = Date()
        sampleRecord.category = "エンジン"
        sampleRecord.subcategory = "オイル"
        sampleRecord.item = "エンジンオイル交換"
        sampleRecord.notes = "10W-40 4L交換"
        sampleRecord.cost = 3000
        sampleRecord.mileage = 10000
        sampleRecord.bike = sampleBike
        sampleRecord.createdAt = Date()
        sampleRecord.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Preview data creation error: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BikeCollectionMemo")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
                // In production, handle this more gracefully
                // For now, just log the error and continue
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}