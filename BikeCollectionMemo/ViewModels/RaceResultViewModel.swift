import CoreData
import SwiftUI

class RaceResultViewModel: ObservableObject {
    private let persistenceController = PersistenceController.shared
    
    func createRaceResult(
        raceName: String,
        raceDate: Date,
        track: String,
        category: String,
        position: Int32,
        totalParticipants: Int32,
        bestLapTime: String,
        totalTime: String,
        weather: String,
        temperature: String,
        notes: String,
        bikeName: String,
        imageDataArray: [Data] = []
    ) {
        let context = persistenceController.container.viewContext
        
        let raceResult = RaceResult(context: context)
        raceResult.id = UUID()
        raceResult.raceName = raceName
        raceResult.raceDate = raceDate
        raceResult.track = track
        raceResult.category = category
        raceResult.position = position
        raceResult.totalParticipants = totalParticipants
        raceResult.bestLapTime = bestLapTime
        raceResult.totalTime = totalTime
        raceResult.weather = weather
        raceResult.temperature = temperature
        raceResult.notes = notes
        raceResult.bikeName = bikeName
        raceResult.createdAt = Date()
        raceResult.updatedAt = Date()
        
        // 写真データを個別のRacePhotoエンティティとして保存
        for (index, imageData) in imageDataArray.enumerated() {
            let photo = RacePhoto(context: context)
            photo.id = UUID()
            photo.imageData = imageData
            photo.createdAt = Date()
            photo.sortOrder = Int16(index)
            photo.raceResult = raceResult
        }
        
        saveContext()
    }
    
    func updateRaceResult(
        _ raceResult: RaceResult,
        raceName: String,
        raceDate: Date,
        track: String,
        category: String,
        position: Int32,
        totalParticipants: Int32,
        bestLapTime: String,
        totalTime: String,
        weather: String,
        temperature: String,
        notes: String,
        bikeName: String,
        imageDataArray: [Data] = []
    ) {
        let context = raceResult.managedObjectContext ?? persistenceController.container.viewContext
        raceResult.raceName = raceName
        raceResult.raceDate = raceDate
        raceResult.track = track
        raceResult.category = category
        raceResult.position = position
        raceResult.totalParticipants = totalParticipants
        raceResult.bestLapTime = bestLapTime
        raceResult.totalTime = totalTime
        raceResult.weather = weather
        raceResult.temperature = temperature
        raceResult.notes = notes
        raceResult.bikeName = bikeName
        raceResult.updatedAt = Date()
        
        // 既存の写真を削除
        if let existingPhotos = raceResult.photos as? Set<RacePhoto> {
            for photo in existingPhotos {
                context.delete(photo)
            }
        }
        
        // 新しい写真データを保存
        for (index, imageData) in imageDataArray.enumerated() {
            let photo = RacePhoto(context: context)
            photo.id = UUID()
            photo.imageData = imageData
            photo.createdAt = Date()
            photo.sortOrder = Int16(index)
            photo.raceResult = raceResult
        }
        
        saveContext()
    }
    
    func deleteRaceResult(_ raceResult: RaceResult) {
        let context = raceResult.managedObjectContext ?? persistenceController.container.viewContext
        context.delete(raceResult)
        
        do {
            try context.save()
            print("RaceResult deleted successfully")
        } catch {
            print("Failed to delete RaceResult: \(error)")
        }
    }
    
    private func saveContext() {
        let context = persistenceController.container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("RaceResult saved successfully")
            } catch {
                print("Failed to save RaceResult: \(error)")
            }
        }
    }
}

// MARK: - Extensions

extension RaceResultViewModel {
    var raceCategories: [String] {
        return [
            "モトクロス（MX）",
            "クロスカントリー（XC）",
            "エンデューロ",
            "ハードエンデューロ",
            "トライアル",
            "グラスレーシング",
            "2ストローク",
            "4ストローク",
            "オープンクラス",
            "ビギナークラス",
            "エキスパートクラス",
            "その他"
        ]
    }
    
    var weatherConditions: [String] {
        return [
            "晴れ",
            "曇り",
            "雨",
            "小雨",
            "豪雨",
            "霧",
            "風強",
            "その他"
        ]
    }
    
    var popularTracks: [String] {
        return [
            "スポーツランドSUGO",
            "ツインリンクもてぎ",
            "HSR九州",
            "オフロードヴィレッジ",
            "成田MXパーク",
            "富士見パノラマリゾート",
            "西日本サーキット",
            "九州トレールパーク",
            "八ヶ岳オフロードパーク",
            "ウッズ下市",
            "福島県のエンデューロコース",
            "関東近県エンデューロコース",
            "ローカルコース",
            "その他"
        ]
    }
    
    func formatPosition(_ position: Int32, totalParticipants: Int32) -> String {
        if position == 0 || totalParticipants == 0 {
            return "DNF"
        }
        return "\(position)位 / \(totalParticipants)台"
    }
    
    func getPositionColor(_ position: Int32, totalParticipants: Int32) -> Color {
        if position == 0 || totalParticipants == 0 {
            return .gray
        }
        
        let percentage = Double(position) / Double(totalParticipants)
        if position <= 3 {
            return .yellow // 表彰台
        } else if percentage <= 0.3 {
            return .green // 上位30%
        } else if percentage <= 0.6 {
            return .blue // 中位
        } else {
            return .red // 下位
        }
    }
}