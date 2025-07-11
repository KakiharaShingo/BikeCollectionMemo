import SwiftUI
import PhotosUI

struct AddBikeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var bikeViewModel: BikeViewModel
    
    @State private var name = ""
    @State private var manufacturer = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingImagePicker = false
    
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
                    VStack(alignment: .center, spacing: Constants.Spacing.medium) {
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
                                VStack(alignment: .center, spacing: Constants.Spacing.small) {
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
                        
                        if selectedImageData != nil {
                            Button("写真を変更") {
                                showingImagePicker = true
                            }
                            .foregroundColor(Constants.Colors.accentFallback)
                        }
                    }
                }
            }
            .navigationTitle("バイクを追加")
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
        .onChange(of: selectedPhoto) { oldPhoto, newPhoto in
            Task {
                await loadSelectedPhoto(newPhoto)
            }
        }
    }
    
    private func saveBike() {
        bikeViewModel.createBike(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            manufacturer: manufacturer.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines),
            year: Int32(year),
            imageData: selectedImageData
        )
        
        dismiss()
    }
    
    @MainActor
    private func loadSelectedPhoto(_ photo: PhotosPickerItem?) async {
        guard let photo = photo else { return }
        
        do {
            if let data = try await photo.loadTransferable(type: Data.self) {
                selectedImageData = data
            }
        } catch {
            print("Failed to load photo: \(error)")
        }
    }
}

#Preview {
    AddBikeView(bikeViewModel: BikeViewModel())
}