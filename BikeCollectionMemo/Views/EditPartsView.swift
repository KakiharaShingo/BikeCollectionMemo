import SwiftUI

struct EditPartsView: View {
    let partsMemo: PartsMemo
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PartsMemoViewModel
    
    @State private var partName = ""
    @State private var partNumber = ""
    @State private var description = ""
    @State private var estimatedCost = ""
    @State private var selectedPriority = "中"
    @State private var isPurchased = false
    
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
                    
                    Toggle("購入済み", isOn: $isPurchased)
                }
                
                Section("詳細") {
                    TextField("説明・メモ", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("対象バイク") {
                    HStack {
                        Group {
                            if let imageData = partsMemo.bike?.imageData, let uiImage = UIImage(data: imageData) {
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
                            Text(partsMemo.bike?.wrappedName ?? "")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            
                            Text("\(partsMemo.bike?.wrappedManufacturer ?? "") \(partsMemo.bike?.wrappedModel ?? "")")
                                .font(.caption)
                                .foregroundColor(Constants.Colors.secondaryFallback)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("部品メモを編集")
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
        .onAppear {
            loadPartData()
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
    
    private func loadPartData() {
        partName = partsMemo.wrappedPartName
        partNumber = partsMemo.wrappedPartNumber
        description = partsMemo.wrappedDescription
        estimatedCost = partsMemo.estimatedCost > 0 ? String(Int(partsMemo.estimatedCost)) : ""
        selectedPriority = partsMemo.wrappedPriority
        isPurchased = partsMemo.isPurchased
    }
    
    private func savePart() {
        let costValue = Double(estimatedCost) ?? 0.0
        
        viewModel.updatePartsMemo(
            partsMemo,
            partName: partName.trimmingCharacters(in: .whitespacesAndNewlines),
            partNumber: partNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            estimatedCost: costValue,
            priority: selectedPriority,
            isPurchased: isPurchased
        )
        
        // 関連するバイクオブジェクトを強制的にリフレッシュ
        if let bike = partsMemo.bike {
            DispatchQueue.main.async {
                bike.objectWillChange.send()
            }
        }
        
        dismiss()
    }
}

#Preview {
    EditPartsView(
        partsMemo: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is PartsMemo }) as! PartsMemo,
        viewModel: PartsMemoViewModel()
    )
}