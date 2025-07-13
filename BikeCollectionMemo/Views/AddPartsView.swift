import SwiftUI

struct AddPartsView: View {
    let bike: Bike
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PartsMemoViewModel
    
    @State private var partName = ""
    @State private var partNumber = ""
    @State private var description = ""
    @State private var estimatedCost = ""
    @State private var selectedPriority = "中"
    
    private var isFormValid: Bool {
        !partName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("部品名", text: $partName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("品番", text: $partNumber)
                        .textInputAutocapitalization(.never)
                    
                    TextField("予想費用（円）", text: $estimatedCost)
                        .keyboardType(.numberPad)
                    
                    Picker("優先度", selection: $selectedPriority) {
                        ForEach(Constants.PartsPriority.priorities, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priorityColor(for: priority))
                                    .frame(width: 12, height: 12)
                                Text(priority)
                            }
                            .tag(priority)
                        }
                    }
                }
                
                Section("詳細") {
                    TextField("説明・メモ", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("対象バイク") {
                    HStack {
                        Group {
                            if let imageData = bike.imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "motorcycle")
                                    .font(.title3)
                                    .foregroundColor(Constants.Colors.secondaryFallback)
                            }
                        }
                        .frame(width: 40, height: 40)
                        .background(Constants.Colors.surfaceFallback)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bike.wrappedName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            
                            Text("\(bike.wrappedManufacturer) \(bike.wrappedModel)")
                                .font(.caption)
                                .foregroundColor(Constants.Colors.secondaryFallback)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("部品メモを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        savePart()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func priorityColor(for priority: String) -> Color {
        switch priority {
        case "高":
            return .red
        case "中":
            return .orange
        case "低":
            return .green
        default:
            return .gray
        }
    }
    
    private func savePart() {
        let costValue = Double(estimatedCost) ?? 0.0
        
        viewModel.createPartsMemo(
            for: bike,
            partName: partName.trimmingCharacters(in: .whitespacesAndNewlines),
            partNumber: partNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            estimatedCost: costValue,
            priority: selectedPriority
        )
        
        // 関連するバイクオブジェクトを強制的にリフレッシュ
        DispatchQueue.main.async {
            bike.objectWillChange.send()
        }
        
        dismiss()
    }
}

#Preview {
    AddPartsView(
        bike: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is Bike }) as! Bike,
        viewModel: PartsMemoViewModel()
    )
}