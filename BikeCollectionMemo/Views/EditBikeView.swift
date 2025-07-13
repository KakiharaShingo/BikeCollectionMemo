import SwiftUI
import PhotosUI

struct EditBikeView: View {
    let bike: Bike
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var bikeViewModel: BikeViewModel
    
    @State private var name: String
    @State private var manufacturer: String
    @State private var model: String
    @State private var year: Int
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingImagePicker = false
    @State private var hasChangedImage = false
    
    init(bike: Bike, bikeViewModel: BikeViewModel) {
        self.bike = bike
        self.bikeViewModel = bikeViewModel
        self._name = State(initialValue: bike.wrappedName)
        self._manufacturer = State(initialValue: bike.wrappedManufacturer)
        self._model = State(initialValue: bike.wrappedModel)
        self._year = State(initialValue: Int(bike.year))
        self._selectedImageData = State(initialValue: bike.imageData)
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !manufacturer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("バイク名", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("メーカー", text: $manufacturer)
                        .textInputAutocapitalization(.words)
                    
                    TextField("モデル", text: $model)
                        .textInputAutocapitalization(.words)
                    
                    Picker("年式", selection: $year) {
                        ForEach(1980...Calendar.current.component(.year, from: Date()) + 1, id: \.self) { year in
                            Text("\(year)年").tag(year)
                        }
                    }
                }
                
                Section("写真") {
                    VStack(spacing: Constants.Spacing.medium) {
                        if let selectedImageData = selectedImageData,
                           let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                                .onTapGesture {
                                    showingImagePicker = true
                                }
                        } else {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                VStack(spacing: Constants.Spacing.small) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(Constants.Colors.secondaryFallback)
                                    
                                    Text("写真を追加")
                                        .font(.body)
                                        .foregroundColor(Constants.Colors.secondaryFallback)
                                }
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                .background(Constants.Colors.surfaceFallback)
                                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        HStack {
                            if selectedImageData != nil {
                                Button("写真を変更") {
                                    showingImagePicker = true
                                }
                                .foregroundColor(Constants.Colors.accentFallback)
                                
                                Button("写真を削除") {
                                    selectedImageData = nil
                                    hasChangedImage = true
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("バイクを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveBike()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, newPhoto in
            Task {
                await loadSelectedPhoto(newPhoto)
            }
        }
    }
    
    private func saveBike() {
        let imageData = hasChangedImage ? selectedImageData : (selectedImageData != bike.imageData ? selectedImageData : nil)
        
        bikeViewModel.updateBike(
            bike,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            manufacturer: manufacturer.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines),
            year: Int32(year),
            imageData: imageData
        )
        
        dismiss()
    }
    
    @MainActor
    private func loadSelectedPhoto(_ photo: PhotosPickerItem?) async {
        guard let photo = photo else { return }
        
        do {
            if let data = try await photo.loadTransferable(type: Data.self) {
                selectedImageData = data
                hasChangedImage = true
            }
        } catch {
            print("Failed to load photo: \(error)")
        }
    }
}

#Preview {
    EditBikeView(
        bike: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is Bike }) as! Bike,
        bikeViewModel: BikeViewModel()
    )
}