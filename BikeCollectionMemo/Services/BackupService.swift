import Foundation
import CoreData
import UniformTypeIdentifiers

class BackupService: ObservableObject {
    private let persistenceController = PersistenceController.shared
    
    // MARK: - Export Functions
    
    func exportAllData() -> URL? {
        let context = persistenceController.container.viewContext
        
        // Fetch all data
        let bikeRequest: NSFetchRequest<Bike> = Bike.fetchRequest()
        let maintenanceRequest: NSFetchRequest<MaintenanceRecord> = MaintenanceRecord.fetchRequest()
        let partsRequest: NSFetchRequest<PartsMemo> = PartsMemo.fetchRequest()
        
        do {
            let bikes = try context.fetch(bikeRequest)
            let maintenanceRecords = try context.fetch(maintenanceRequest)
            let partsMemos = try context.fetch(partsRequest)
            
            return createBackupArchive(bikes: bikes, maintenanceRecords: maintenanceRecords, partsMemos: partsMemos)
        } catch {
            print("Failed to fetch data for export: \(error)")
            return nil
        }
    }
    
    private func createBackupArchive(bikes: [Bike], maintenanceRecords: [MaintenanceRecord], partsMemos: [PartsMemo]) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupDirectory = documentsDirectory.appendingPathComponent("BikeBackup_\(dateString())")
        
        do {
            try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
            
            // Export bikes
            let bikesCSV = generateBikesCSV(bikes: bikes)
            let bikesURL = backupDirectory.appendingPathComponent("bikes.csv")
            try bikesCSV.write(to: bikesURL, atomically: true, encoding: .utf8)
            
            // Export maintenance records
            let maintenanceCSV = generateMaintenanceRecordsCSV(records: maintenanceRecords)
            let maintenanceURL = backupDirectory.appendingPathComponent("maintenance_records.csv")
            try maintenanceCSV.write(to: maintenanceURL, atomically: true, encoding: .utf8)
            
            // Export parts memos
            let partsCSV = generatePartsMemosCSV(memos: partsMemos)
            let partsURL = backupDirectory.appendingPathComponent("parts_memos.csv")
            try partsCSV.write(to: partsURL, atomically: true, encoding: .utf8)
            
            // Export bike images
            exportBikeImages(bikes: bikes, to: backupDirectory)
            
            return backupDirectory
        } catch {
            print("Failed to create backup archive: \(error)")
            return nil
        }
    }
    
    private func generateBikesCSV(bikes: [Bike]) -> String {
        var csv = "ID,Name,Manufacturer,Model,Year,HasImage,CreatedAt,UpdatedAt\n"
        
        for bike in bikes {
            let id = bike.id?.uuidString ?? ""
            let name = bike.wrappedName.escapedForCSV()
            let manufacturer = bike.wrappedManufacturer.escapedForCSV()
            let model = bike.wrappedModel.escapedForCSV()
            let year = String(bike.year)
            let hasImage = bike.imageData != nil ? "true" : "false"
            let createdAt = bike.createdAt?.iso8601String() ?? ""
            let updatedAt = bike.updatedAt?.iso8601String() ?? ""
            
            csv += "\(id),\(name),\(manufacturer),\(model),\(year),\(hasImage),\(createdAt),\(updatedAt)\n"
        }
        
        return csv
    }
    
    private func generateMaintenanceRecordsCSV(records: [MaintenanceRecord]) -> String {
        var csv = "ID,BikeID,Date,Category,Subcategory,Item,Notes,Cost,Mileage,CreatedAt,UpdatedAt\n"
        
        for record in records {
            let id = record.id?.uuidString ?? ""
            let bikeId = record.bike?.id?.uuidString ?? ""
            let date = record.date?.iso8601String() ?? ""
            let category = record.wrappedCategory.escapedForCSV()
            let subcategory = record.wrappedSubcategory.escapedForCSV()
            let item = record.wrappedItem.escapedForCSV()
            let notes = record.wrappedNotes.escapedForCSV()
            let cost = String(record.cost)
            let mileage = String(record.mileage)
            let createdAt = record.createdAt?.iso8601String() ?? ""
            let updatedAt = record.updatedAt?.iso8601String() ?? ""
            
            csv += "\(id),\(bikeId),\(date),\(category),\(subcategory),\(item),\(notes),\(cost),\(mileage),\(createdAt),\(updatedAt)\n"
        }
        
        return csv
    }
    
    private func generatePartsMemosCSV(memos: [PartsMemo]) -> String {
        var csv = "ID,BikeID,PartName,PartNumber,Description,EstimatedCost,Priority,IsPurchased,CreatedAt,UpdatedAt\n"
        
        for memo in memos {
            let id = memo.id?.uuidString ?? ""
            let bikeId = memo.bike?.id?.uuidString ?? ""
            let partName = memo.wrappedPartName.escapedForCSV()
            let partNumber = memo.wrappedPartNumber.escapedForCSV()
            let description = memo.wrappedDescription.escapedForCSV()
            let estimatedCost = String(memo.estimatedCost)
            let priority = memo.wrappedPriority.escapedForCSV()
            let isPurchased = memo.isPurchased ? "true" : "false"
            let createdAt = memo.createdAt?.iso8601String() ?? ""
            let updatedAt = memo.updatedAt?.iso8601String() ?? ""
            
            csv += "\(id),\(bikeId),\(partName),\(partNumber),\(description),\(estimatedCost),\(priority),\(isPurchased),\(createdAt),\(updatedAt)\n"
        }
        
        return csv
    }
    
    private func exportBikeImages(bikes: [Bike], to directory: URL) {
        let imagesDirectory = directory.appendingPathComponent("images")
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        
        for bike in bikes {
            guard let imageData = bike.imageData,
                  let bikeId = bike.id?.uuidString else { continue }
            
            let imageURL = imagesDirectory.appendingPathComponent("\(bikeId).jpg")
            try? imageData.write(to: imageURL)
        }
    }
    
    // MARK: - Import Functions
    
    func importData(from directory: URL) -> Bool {
        let context = persistenceController.container.viewContext
        
        do {
            // Clear existing data first
            clearAllData()
            
            // Import bikes
            let bikesURL = directory.appendingPathComponent("bikes.csv")
            if FileManager.default.fileExists(atPath: bikesURL.path) {
                try importBikes(from: bikesURL, context: context)
            }
            
            // Import maintenance records
            let maintenanceURL = directory.appendingPathComponent("maintenance_records.csv")
            if FileManager.default.fileExists(atPath: maintenanceURL.path) {
                try importMaintenanceRecords(from: maintenanceURL, context: context)
            }
            
            // Import parts memos
            let partsURL = directory.appendingPathComponent("parts_memos.csv")
            if FileManager.default.fileExists(atPath: partsURL.path) {
                try importPartsMemos(from: partsURL, context: context)
            }
            
            // Import bike images
            let imagesDirectory = directory.appendingPathComponent("images")
            if FileManager.default.fileExists(atPath: imagesDirectory.path) {
                importBikeImages(from: imagesDirectory, context: context)
            }
            
            // Save context
            try context.save()
            return true
        } catch {
            print("Failed to import data: \(error)")
            return false
        }
    }
    
    private func importBikes(from url: URL, context: NSManagedObjectContext) throws {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        let lines = csvContent.components(separatedBy: .newlines).dropFirst() // Skip header
        
        for line in lines {
            guard !line.isEmpty else { continue }
            let components = line.parseCSVLine()
            guard components.count >= 8 else { continue }
            
            let bike = Bike(context: context)
            bike.id = UUID(uuidString: components[0])
            bike.name = components[1]
            bike.manufacturer = components[2]
            bike.model = components[3]
            bike.year = Int32(components[4]) ?? 0
            bike.createdAt = Date.fromISO8601String(components[6])
            bike.updatedAt = Date.fromISO8601String(components[7])
        }
    }
    
    private func importMaintenanceRecords(from url: URL, context: NSManagedObjectContext) throws {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        let lines = csvContent.components(separatedBy: .newlines).dropFirst()
        
        for line in lines {
            guard !line.isEmpty else { continue }
            let components = line.parseCSVLine()
            guard components.count >= 11 else { continue }
            
            let record = MaintenanceRecord(context: context)
            record.id = UUID(uuidString: components[0])
            record.date = Date.fromISO8601String(components[2])
            record.category = components[3]
            record.subcategory = components[4]
            record.item = components[5]
            record.notes = components[6]
            record.cost = Double(components[7]) ?? 0.0
            record.mileage = Int32(components[8]) ?? 0
            record.createdAt = Date.fromISO8601String(components[9])
            record.updatedAt = Date.fromISO8601String(components[10])
            
            // Link to bike
            if let bikeIdString = components.count > 1 ? components[1] : nil,
               let bikeId = UUID(uuidString: bikeIdString) {
                let bikeRequest: NSFetchRequest<Bike> = Bike.fetchRequest()
                bikeRequest.predicate = NSPredicate(format: "id == %@", bikeId as CVarArg)
                if let bike = try? context.fetch(bikeRequest).first {
                    record.bike = bike
                }
            }
        }
    }
    
    private func importPartsMemos(from url: URL, context: NSManagedObjectContext) throws {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        let lines = csvContent.components(separatedBy: .newlines).dropFirst()
        
        for line in lines {
            guard !line.isEmpty else { continue }
            let components = line.parseCSVLine()
            guard components.count >= 10 else { continue }
            
            let memo = PartsMemo(context: context)
            memo.id = UUID(uuidString: components[0])
            memo.partName = components[2]
            memo.partNumber = components[3]
            memo.description_ = components[4]
            memo.estimatedCost = Double(components[5]) ?? 0.0
            memo.priority = components[6]
            memo.isPurchased = components[7].lowercased() == "true"
            memo.createdAt = Date.fromISO8601String(components[8])
            memo.updatedAt = Date.fromISO8601String(components[9])
            
            // Link to bike
            if let bikeIdString = components.count > 1 ? components[1] : nil,
               let bikeId = UUID(uuidString: bikeIdString) {
                let bikeRequest: NSFetchRequest<Bike> = Bike.fetchRequest()
                bikeRequest.predicate = NSPredicate(format: "id == %@", bikeId as CVarArg)
                if let bike = try? context.fetch(bikeRequest).first {
                    memo.bike = bike
                }
            }
        }
    }
    
    private func importBikeImages(from directory: URL, context: NSManagedObjectContext) {
        let bikeRequest: NSFetchRequest<Bike> = Bike.fetchRequest()
        guard let bikes = try? context.fetch(bikeRequest) else { return }
        
        for bike in bikes {
            guard let bikeId = bike.id?.uuidString else { continue }
            let imageURL = directory.appendingPathComponent("\(bikeId).jpg")
            
            if let imageData = try? Data(contentsOf: imageURL) {
                bike.imageData = imageData
            }
        }
    }
    
    private func clearAllData() {
        let context = persistenceController.container.viewContext
        
        // Delete all entities
        let bikeRequest: NSFetchRequest<NSFetchRequestResult> = Bike.fetchRequest()
        let bikesDeleteRequest = NSBatchDeleteRequest(fetchRequest: bikeRequest)
        
        let maintenanceRequest: NSFetchRequest<NSFetchRequestResult> = MaintenanceRecord.fetchRequest()
        let maintenanceDeleteRequest = NSBatchDeleteRequest(fetchRequest: maintenanceRequest)
        
        let partsRequest: NSFetchRequest<NSFetchRequestResult> = PartsMemo.fetchRequest()
        let partsDeleteRequest = NSBatchDeleteRequest(fetchRequest: partsRequest)
        
        do {
            try context.execute(bikesDeleteRequest)
            try context.execute(maintenanceDeleteRequest)
            try context.execute(partsDeleteRequest)
            try context.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
    
    // MARK: - Helper Functions
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}

// MARK: - Extensions

extension String {
    func escapedForCSV() -> String {
        let needsEscaping = self.contains(",") || self.contains("\"") || self.contains("\n")
        if needsEscaping {
            return "\"\(self.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return self
    }
    
    func parseCSVLine() -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = self.startIndex
        
        while i < self.endIndex {
            let char = self[i]
            
            if char == "\"" {
                if inQuotes {
                    let nextIndex = self.index(after: i)
                    if nextIndex < self.endIndex && self[nextIndex] == "\"" {
                        current += "\""
                        i = nextIndex
                    } else {
                        inQuotes = false
                    }
                } else {
                    inQuotes = true
                }
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current += String(char)
            }
            
            i = self.index(after: i)
        }
        
        result.append(current)
        return result
    }
}

extension Date {
    func iso8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
    
    static func fromISO8601String(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
}