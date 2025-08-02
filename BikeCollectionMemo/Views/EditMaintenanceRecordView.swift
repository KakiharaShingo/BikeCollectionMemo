import SwiftUI
import PhotosUI

struct EditMaintenanceRecordView: View {
    let record: MaintenanceRecord
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MaintenanceRecordViewModel
    
    @State private var selectedDate: Date
    @State private var selectedCategory: String
    @State private var selectedSubcategory: String
    @State private var selectedItem: String
    @State private var customItem = ""
    @State private var notes: String
    @State private var cost: String
    @State private var mileage: String
    @State private var useCustomItem = false
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imageDataArray: [Data] = []
    
    init(record: MaintenanceRecord, viewModel: MaintenanceRecordViewModel) {
        self.record = record
        self.viewModel = viewModel
        self._selectedDate = State(initialValue: record.date ?? Date())
        self._selectedCategory = State(initialValue: record.wrappedCategory)
        self._selectedSubcategory = State(initialValue: record.wrappedSubcategory)
        self._selectedItem = State(initialValue: record.wrappedItem)
        self._notes = State(initialValue: record.wrappedNotes)
        self._cost = State(initialValue: record.cost > 0 ? String(Int(record.cost)) : "")
        self._mileage = State(initialValue: record.mileage > 0 ? String(record.mileage) : "")
        // 既存の写真データを読み込み
        if let photos = record.photos as? Set<Photo> {
            let sortedPhotos = Array(photos).sorted { $0.sortOrder < $1.sortOrder }
            let existingImageData = sortedPhotos.compactMap { $0.imageData }
            self._imageDataArray = State(initialValue: existingImageData)
        } else {
            self._imageDataArray = State(initialValue: [])
        }
        
        // カスタム項目かどうかを判定
        let categories = Constants.MaintenanceCategories.categories
        let items = categories[record.wrappedCategory]?[record.wrappedSubcategory] ?? []
        self._useCustomItem = State(initialValue: !items.contains(record.wrappedItem) && !record.wrappedItem.isEmpty)
        if !items.contains(record.wrappedItem) && !record.wrappedItem.isEmpty {
            self._customItem = State(initialValue: record.wrappedItem)
        }
    }
    
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
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .onChange(of: selectedCategory) { oldValue, newValue in
                        if newValue != oldValue {
                            selectedSubcategory = ""
                            selectedItem = ""
                            useCustomItem = false
                        }
                    }
                    
                    if !subcategories.isEmpty {
                        Picker("中項目", selection: $selectedSubcategory) {
                            ForEach(subcategories, id: \.self) { subcategory in
                                Text(subcategory).tag(subcategory)
                            }
                        }
                        .onChange(of: selectedSubcategory) { oldValue, newValue in
                            if newValue != oldValue {
                                selectedItem = ""
                                useCustomItem = false
                            }
                        }
                    }
                    
                    if !items.isEmpty && !selectedSubcategory.isEmpty {
                        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                            Text("小項目")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if !useCustomItem {
                                Picker("項目を選択", selection: $selectedItem) {
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
                        .frame(minHeight: 120)
                        .lineLimit(nil)
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
            .navigationTitle("整備記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        updateRecord()
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
    
    private func updateRecord() {
        let costValue = Double(cost) ?? 0.0
        let mileageValue = Int32(mileage) ?? 0
        
        viewModel.updateMaintenanceRecord(
            record,
            date: selectedDate,
            category: selectedCategory,
            subcategory: selectedSubcategory,
            item: finalItem,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            cost: costValue,
            mileage: mileageValue,
            imageDataArray: imageDataArray
        )
        
        dismiss()
    }
}

#Preview {
    EditMaintenanceRecordView(
        record: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is MaintenanceRecord }) as! MaintenanceRecord,
        viewModel: MaintenanceRecordViewModel()
    )
}