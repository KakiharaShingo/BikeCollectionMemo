import SwiftUI

struct MaintenanceRecordDetailView: View {
    let record: MaintenanceRecord
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MaintenanceRecordViewModel()
    
    @State private var showingEditRecord = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.large) {
                // ヘッダーセクション
                HeaderSection(record: record)
                
                // 詳細情報セクション
                DetailSection(record: record)
                
                // メモセクション
                if !record.wrappedNotes.isEmpty {
                    NotesSection(record: record)
                }
                
                // 写真セクション
                if let photos = record.photos as? Set<Photo>, !photos.isEmpty {
                    PhotosSection(photos: Array(photos).sorted { $0.sortOrder < $1.sortOrder })
                }
                
                // バイク情報セクション
                if let bike = record.bike {
                    RelatedBikeInfoSection(bike: bike)
                }
            }
            .padding(Constants.Spacing.medium)
        }
        .navigationTitle("整備記録")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingEditRecord = true
                    }) {
                        Label("編集", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Constants.Colors.primaryFallback)
                }
            }
        }
        .sheet(isPresented: $showingEditRecord) {
            EditMaintenanceRecordView(record: record, viewModel: viewModel)
        }
        .alert("整備記録を削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                deleteRecord()
            }
        } message: {
            Text("この整備記録を削除します。この操作は取り消せません。")
        }
    }
    
    private func deleteRecord() {
        viewModel.deleteMaintenanceRecord(record)
        dismiss()
    }
}

struct HeaderSection: View {
    let record: MaintenanceRecord
    
    var body: some View {
        VStack(spacing: Constants.Spacing.medium) {
            // カテゴリーアイコン
            Image(systemName: categoryIcon(for: record.wrappedCategory))
                .font(.system(size: 50))
                .foregroundColor(Constants.Colors.accentFallback)
                .frame(width: 80, height: 80)
                .background(Constants.Colors.surfaceFallback)
                .clipShape(Circle())
            
            VStack(spacing: Constants.Spacing.small) {
                Text(record.wrappedCategory)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if !record.wrappedSubcategory.isEmpty {
                    Text(record.wrappedSubcategory)
                        .font(.title3)
                        .foregroundColor(Constants.Colors.secondaryFallback)
                }
                
                Text(record.wrappedItem)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "エンジン":
            return "cpu.fill"
        case "駆動系":
            return "gearshape.fill"
        case "ブレーキ":
            return "stop.circle.fill"
        case "サスペンション":
            return "arrow.up.and.down.circle.fill"
        case "タイヤ・ホイール":
            return "circle.fill"
        case "電装系":
            return "bolt.fill"
        case "外装・その他":
            return "star.fill"
        default:
            return "wrench.and.screwdriver"
        }
    }
}

struct DetailSection: View {
    let record: MaintenanceRecord
    
    var body: some View {
        VStack(spacing: Constants.Spacing.medium) {
            // 日付と費用
            HStack {
                DetailCard(
                    title: "実施日",
                    value: record.dateString,
                    icon: "calendar",
                    color: Constants.Colors.primaryFallback
                )
                
                DetailCard(
                    title: "費用",
                    value: record.costString,
                    icon: "yensign.circle",
                    color: .blue
                )
            }
            
            // 走行距離
            if record.mileage > 0 {
                DetailCard(
                    title: "走行距離",
                    value: "\(record.mileage)km",
                    icon: "speedometer",
                    color: .blue
                )
            }
        }
    }
}

struct DetailCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Constants.Spacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Constants.Colors.secondaryFallback)
        }
        .frame(maxWidth: .infinity)
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
    }
}

struct NotesSection: View {
    let record: MaintenanceRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(Constants.Colors.accentFallback)
                
                Text("メモ")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(record.wrappedNotes)
                .font(.body)
                .foregroundColor(.primary)
                .padding(Constants.Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Constants.Colors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
        }
    }
}

struct RelatedBikeInfoSection: View {
    let bike: Bike
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack {
                Image(systemName: "motorcycle")
                    .foregroundColor(Constants.Colors.accentFallback)
                
                Text("対象バイク")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            NavigationLink(destination: BikeDetailView(bike: bike)) {
                HStack(spacing: Constants.Spacing.medium) {
                    Group {
                        if let imageData = bike.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: "motorcycle")
                                .font(.title)
                                .foregroundColor(Constants.Colors.secondaryFallback)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .background(Constants.Colors.surfaceFallback)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
                    
                    VStack(alignment: .leading, spacing: Constants.Spacing.extraSmall) {
                        Text(bike.wrappedName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("\(bike.wrappedManufacturer) \(bike.wrappedModel)")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.secondaryFallback)
                        
                        Text("\(bike.year)年")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.secondaryFallback)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.secondaryFallback)
                }
                .padding(Constants.Spacing.medium)
                .background(Constants.Colors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct PhotosSection: View {
    let photos: [Photo]
    @State private var selectedPhoto: Photo?
    @State private var showingFullScreen = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack {
                Image(systemName: "photo")
                    .foregroundColor(Constants.Colors.accentFallback)
                
                Text("写真 (\(photos.count)枚)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Constants.Spacing.medium) {
                    ForEach(photos, id: \.id) { photo in
                        if let imageData = photo.imageData, let uiImage = UIImage(data: imageData) {
                            Button(action: {
                                selectedPhoto = photo
                                showingFullScreen = true
                            }) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                                            .stroke(Constants.Colors.primaryFallback.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, Constants.Spacing.medium)
            }
        }
        .sheet(isPresented: $showingFullScreen) {
            if let selectedPhoto = selectedPhoto,
               let imageData = selectedPhoto.imageData,
               let _ = UIImage(data: imageData) {
                PhotoGalleryView(photos: photos, selectedPhoto: selectedPhoto)
            }
        }
    }
}

struct PhotoGalleryView: View {
    let photos: [Photo]
    let selectedPhoto: Photo
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    
    init(photos: [Photo], selectedPhoto: Photo) {
        self.photos = photos
        self.selectedPhoto = selectedPhoto
        self._currentIndex = State(initialValue: photos.firstIndex(where: { $0.id == selectedPhoto.id }) ?? 0)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 写真ページャー
                TabView(selection: $currentIndex) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        if let imageData = photo.imageData, let uiImage = UIImage(data: imageData) {
                            ZoomableImageView(image: uiImage)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .background(Color.black)
                
                // 写真カウンター
                Text("\(currentIndex + 1) / \(photos.count)")
                    .foregroundColor(.white)
                    .padding()
            }
            .background(Color.black)
            .navigationTitle("写真")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZoomableImageView(image: image)
                .background(Color.black)
                .navigationTitle("写真")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完了") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                }
        }
    }
}

struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        let imageView = UIImageView(image: image)
        
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        guard let imageView = uiView.subviews.first as? UIImageView else { return }
        
        imageView.image = image
        imageView.frame = uiView.bounds
        uiView.contentSize = imageView.bounds.size
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }
    }
}

#Preview {
    NavigationView {
        MaintenanceRecordDetailView(
            record: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is MaintenanceRecord }) as! MaintenanceRecord
        )
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}