import Foundation
import CoreData

extension Bike {
    
    var wrappedName: String {
        name ?? "Unknown Bike"
    }
    
    var wrappedManufacturer: String {
        manufacturer ?? "Unknown Manufacturer"
    }
    
    var wrappedModel: String {
        model ?? "Unknown Model"
    }
    
    var maintenanceRecordsArray: [MaintenanceRecord] {
        let set = maintenanceRecords as? Set<MaintenanceRecord> ?? []
        return set.sorted {
            $0.date ?? Date.distantPast > $1.date ?? Date.distantPast
        }
    }
    
    var partsMemosArray: [PartsMemo] {
        let set = partsMemos as? Set<PartsMemo> ?? []
        return set.sorted {
            $0.createdAt ?? Date.distantPast > $1.createdAt ?? Date.distantPast
        }
    }
    
    var totalMaintenanceCost: Double {
        maintenanceRecordsArray.reduce(0) { $0 + $1.cost }
    }
    
    var lastMaintenanceDate: Date? {
        maintenanceRecordsArray.first?.date
    }
}

extension MaintenanceRecord {
    
    var wrappedCategory: String {
        category ?? "その他"
    }
    
    var wrappedSubcategory: String {
        subcategory ?? ""
    }
    
    var wrappedItem: String {
        item ?? "未記入"
    }
    
    var wrappedNotes: String {
        notes ?? ""
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date ?? Date())
    }
    
    var costString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: NSNumber(value: cost)) ?? "¥0"
    }
}

extension PartsMemo {
    
    var wrappedPartName: String {
        partName ?? "Unknown Part"
    }
    
    var wrappedPartNumber: String {
        partNumber ?? ""
    }
    
    var wrappedDescription: String {
        description_ ?? ""
    }
    
    var wrappedPriority: String {
        priority ?? "中"
    }
    
    var priorityColor: String {
        switch wrappedPriority {
        case "高":
            return "red"
        case "中":
            return "orange"
        case "低":
            return "green"
        default:
            return "gray"
        }
    }
    
    var estimatedCostString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: NSNumber(value: estimatedCost)) ?? "¥0"
    }
}