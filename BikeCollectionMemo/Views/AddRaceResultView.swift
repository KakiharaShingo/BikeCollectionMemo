import SwiftUI
import PhotosUI
import CoreData

struct AddRaceResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = RaceResultViewModel()
    
    @State private var raceName = ""
    @State private var raceDate = Date()
    @State private var track = ""
    @State private var category = ""
    @State private var position = ""
    @State private var totalParticipants = ""
    @State private var bestLapTime = ""
    @State private var totalTime = ""
    @State private var weather = ""
    @State private var temperature = ""
    @State private var notes = ""
    @State private var bikeName = ""
    @State private var customTrack = ""
    @State private var customCategory = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imageDataArray: [Data] = []
    @State private var showingImagePicker = false
    
    private var finalTrack: String {
        track == "その他" ? customTrack : track
    }
    
    private var finalCategory: String {
        category == "その他" ? customCategory : category
    }
    
    private var isFormValid: Bool {
        !raceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !finalTrack.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !finalCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("レース名", text: $raceName)
                    DatePicker("開催日", selection: $raceDate, displayedComponents: .date)
                    
                    Picker("コース", selection: $track) {
                        Text("選択してください").tag("")
                        ForEach(viewModel.popularTracks, id: \.self) { track in
                            Text(track).tag(track)
                        }
                    }
                    
                    if track == "その他" {
                        TextField("コース名を入力", text: $customTrack)
                    }
                    
                    Picker("カテゴリー", selection: $category) {
                        Text("選択してください").tag("")
                        ForEach(viewModel.raceCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    if category == "その他" {
                        TextField("カテゴリー名を入力", text: $customCategory)
                    }
                }
                
                Section("結果") {
                    HStack {
                        TextField("順位", text: $position)
                            .keyboardType(.numberPad)
                        Text("位")
                        Text("/")
                        TextField("総台数", text: $totalParticipants)
                            .keyboardType(.numberPad)
                        Text("台")
                    }
                    
                    TextField("ベストラップタイム（例：12:34.56）", text: $bestLapTime)
                    TextField("総合タイム（例：2:45:23）", text: $totalTime)
                }
                
                Section("コンディション") {
                    Picker("天候", selection: $weather) {
                        Text("選択してください").tag("")
                        ForEach(viewModel.weatherConditions, id: \.self) { weather in
                            Text(weather).tag(weather)
                        }
                    }
                    
                    TextField("気温（例：25℃）", text: $temperature)
                }
                
                Section("その他") {
                    TextField("使用バイク", text: $bikeName)
                    
                    TextField("メモ・感想", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("写真") {
                    // 写真選択ボタン
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text("写真を追加")
                            Spacer()
                            if !selectedImages.isEmpty {
                                Text("\(selectedImages.count)枚選択中")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    // 選択済み写真表示
                    if !imageDataArray.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Constants.Spacing.small) {
                                ForEach(Array(imageDataArray.enumerated()), id: \.offset) { index, imageData in
                                    if let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
                                            .overlay(
                                                Button(action: {
                                                    imageDataArray.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .background(Color.white.clipShape(Circle()))
                                                }
                                                .offset(x: 8, y: -8),
                                                alignment: .topTrailing
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, Constants.Spacing.small)
                        }
                    }
                }
            }
            .navigationTitle("レース記録追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRaceResult()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedImages, maxSelectionCount: 10, matching: .images)
        .onChange(of: selectedImages) {
            Task {
                var newImageDataArray: [Data] = []
                for selectedImage in selectedImages {
                    if let data = try? await selectedImage.loadTransferable(type: Data.self) {
                        newImageDataArray.append(data)
                    }
                }
                DispatchQueue.main.async {
                    self.imageDataArray.append(contentsOf: newImageDataArray)
                    self.selectedImages.removeAll()
                }
            }
        }
    }
    
    private func saveRaceResult() {
        let positionValue = Int32(position) ?? 0
        let totalParticipantsValue = Int32(totalParticipants) ?? 0
        
        viewModel.createRaceResult(
            raceName: raceName.trimmingCharacters(in: .whitespacesAndNewlines),
            raceDate: raceDate,
            track: finalTrack.trimmingCharacters(in: .whitespacesAndNewlines),
            category: finalCategory.trimmingCharacters(in: .whitespacesAndNewlines),
            position: positionValue,
            totalParticipants: totalParticipantsValue,
            bestLapTime: bestLapTime.trimmingCharacters(in: .whitespacesAndNewlines),
            totalTime: totalTime.trimmingCharacters(in: .whitespacesAndNewlines),
            weather: weather,
            temperature: temperature.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            bikeName: bikeName.trimmingCharacters(in: .whitespacesAndNewlines),
            imageDataArray: imageDataArray
        )
        
        dismiss()
    }
}

#Preview {
    AddRaceResultView()
}