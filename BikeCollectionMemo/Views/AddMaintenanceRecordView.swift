import SwiftUI
import PhotosUI

struct AddMaintenanceRecordView: View {
    let bike: Bike
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MaintenanceRecordViewModel
    
    @State private var selectedDate = Date()
    @State private var selectedCategory = ""
    @State private var selectedSubcategory = ""
    @State private var selectedItem = ""
    @State private var customItem = ""
    @State private var notes = ""
    @State private var cost = ""
    @State private var mileage = ""
    @State private var useCustomItem = false
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imageDataArray: [Data] = []
    @State private var showingImagePicker = false
    
    private var categories: [String] {
        Constants.MaintenanceCategories.getAllCategories()
    }
    
    private var subcategories: [String] {
        guard !selectedCategory.isEmpty else { return [] }
        return Constants.MaintenanceCategories.getSubcategories(for: selectedCategory)
    }
    
    private var items: [String] {
        guard !selectedCategory.isEmpty, !selectedSubcategory.isEmpty else { return [] }
        return Constants.MaintenanceCategories.getItems(for: selectedCategory, subcategory: selectedSubcategory)
    }
    
    private var finalItem: String {
        if useCustomItem {
            return customItem.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return selectedItem
        }
    }
    
    private var isFormValid: Bool {
        !selectedCategory.isEmpty &&
        !selectedSubcategory.isEmpty &&
        !finalItem.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    DatePicker("日付", selection: $selectedDate, displayedComponents: .date)
                    
                    Picker("大項目", selection: $selectedCategory) {
                        Text("選択してください").tag("")
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .onChange(of: selectedCategory) {
                        selectedSubcategory = ""
                        selectedItem = ""
                        useCustomItem = false
                    }
                    
                    if !subcategories.isEmpty {
                        Picker("中項目", selection: $selectedSubcategory) {
                            Text("選択してください").tag("")
                            ForEach(subcategories, id: \.self) { subcategory in
                                Text(subcategory).tag(subcategory)
                            }
                        }
                        .onChange(of: selectedSubcategory) {
                            selectedItem = ""
                            useCustomItem = false
                        }
                    }
                    
                    if !items.isEmpty && !selectedSubcategory.isEmpty {
                        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                            Text("小項目")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if !useCustomItem {
                                Picker("項目を選択", selection: $selectedItem) {
                                    Text("選択してください").tag("")
                                    ForEach(items, id: \.self) { item in
                                        Text(item).tag(item)
                                    }
                                    Text("その他（カスタム入力）").tag("custom")
                                }
                                .onChange(of: selectedItem) { _, newValue in
                                    if newValue == "custom" {
                                        useCustomItem = true
                                        selectedItem = ""
                                    }
                                }
                            }
                            
                            if useCustomItem {
                                HStack {
                                    TextField("カスタム項目を入力", text: $customItem)
                                    
                                    Button("戻る") {
                                        useCustomItem = false
                                        customItem = ""
                                    }
                                    .font(.caption)
                                    .foregroundColor(Constants.Colors.accentFallback)
                                }
                            }
                        }
                    }
                }
                
                Section("詳細情報") {
                    TextField("費用（円）", text: $cost)
                        .keyboardType(.numberPad)
                    
                    TextField("走行距離（km）", text: $mileage)
                        .keyboardType(.numberPad)
                    
                    TextField("メモ", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("写真") {
                    VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                        // 写真一覧表示エリア
                        if !imageDataArray.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Constants.Spacing.small) {
                                    ForEach(Array(imageDataArray.enumerated()), id: \.offset) { index, imageData in
                                        if let uiImage = UIImage(data: imageData) {
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 120, height: 120)
                                                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                                                
                                                Button(action: {
                                                    imageDataArray.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.title3)
                                                        .foregroundColor(.red)
                                                        .background(Color.white)
                                                        .clipShape(Circle())
                                                }
                                                .padding(4)
                                            }
                                        }
                                    }
                                    
                                    // 写真追加ボタン
                                    PhotosPicker(selection: $selectedImages, maxSelectionCount: 10, matching: .images) {
                                        VStack(spacing: Constants.Spacing.small) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 30))
                                                .foregroundColor(Constants.Colors.accentFallback)
                                            
                                            Text("追加")
                                                .font(.caption)
                                                .foregroundColor(Constants.Colors.accentFallback)
                                        }
                                        .frame(width: 120, height: 120)
                                        .background(Constants.Colors.surfaceFallback)
                                        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                                                .stroke(Constants.Colors.accentFallback, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                        )
                                    }
                                }
                                .padding(.horizontal, Constants.Spacing.medium)
                            }
                        } else {
                            // 最初の写真選択ボタン
                            PhotosPicker(selection: $selectedImages, maxSelectionCount: 10, matching: .images) {
                                VStack(spacing: Constants.Spacing.small) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Constants.Colors.accentFallback)
                                    
                                    Text("写真を追加 (最大10枚)")
                                        .font(.subheadline)
                                        .foregroundColor(Constants.Colors.accentFallback)
                                }
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                .background(Constants.Colors.surfaceFallback)
                                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                                        .stroke(Constants.Colors.accentFallback, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("整備記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRecord()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
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
    
    private func saveRecord() {
        let costValue = Double(cost) ?? 0.0
        let mileageValue = Int32(mileage) ?? 0
        
        viewModel.createMaintenanceRecord(
            for: bike,
            date: selectedDate,
            category: selectedCategory,
            subcategory: selectedSubcategory,
            item: finalItem,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            cost: costValue,
            mileage: mileageValue,
            imageDataArray: imageDataArray
        )
        
        // Bikeオブジェクトの変更を明示的に通知
        bike.objectWillChange.send()
        
        dismiss()
    }
}

#Preview {
    AddMaintenanceRecordView(
        bike: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is Bike }) as! Bike,
        viewModel: MaintenanceRecordViewModel()
    )
}