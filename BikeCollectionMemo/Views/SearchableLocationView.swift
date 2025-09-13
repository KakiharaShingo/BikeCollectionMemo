import SwiftUI
import MapKit

struct SearchableLocationView: View {
    let onLocationSelected: ((CLLocationCoordinate2D, String) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var checkInManager = CheckInManager.shared

    init(onLocationSelected: ((CLLocationCoordinate2D, String) -> Void)? = nil) {
        self.onLocationSelected = onLocationSelected
    }

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedLocation: CheckInLocation?
    @State private var showingCheckInForm = false
    @State private var isSearching = false
    @State private var showingAddLocation = false
    @State private var showingMapPicker = false
    @State private var showingMapLocationAdd = false
    @State private var selectedCoordinateForAdd: CLLocationCoordinate2D?

    // フィルター用
    @State private var selectedCategory: CheckInLocation.LocationCategory?
    @State private var showingCategoryFilter = false

    var filteredPresetLocations: [CheckInLocation] {
        var locations = CheckInLocation.presetLocations + checkInManager.userLocations

        if let category = selectedCategory {
            locations = locations.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            locations = locations.filter { location in
                location.name.localizedCaseInsensitiveContains(searchText) ||
                (location.address?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                location.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        return locations
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー
                searchBar

                // カテゴリフィルター
                if selectedCategory != nil {
                    categoryFilterChip
                }

                // メインコンテンツ
                ScrollView {
                    LazyVStack(spacing: Constants.Spacing.medium) {
                        // プリセット・ユーザー場所
                        if !filteredPresetLocations.isEmpty {
                            presetLocationsSection
                        }

                        // 検索結果
                        if !searchResults.isEmpty {
                            searchResultsSection
                        }

                        // 空の状態
                        if filteredPresetLocations.isEmpty && searchResults.isEmpty && !searchText.isEmpty {
                            emptySearchState
                        }

                        // 新規場所追加
                        addNewLocationSection
                    }
                    .padding(Constants.Spacing.medium)
                }
            }
            .navigationTitle("場所を検索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCategoryFilter = true }) {
                        Image(systemName: selectedCategory != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(selectedCategory != nil ? .blue : .primary)
                    }
                }
            }
            .sheet(isPresented: $showingCheckInForm) {
                if let location = selectedLocation {
                    CheckInFormView(location: location)
                }
            }
            .sheet(isPresented: $showingCategoryFilter) {
                CategoryFilterView(selectedCategory: $selectedCategory)
            }
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView()
            }
            .sheet(isPresented: $showingMapPicker) {
                MapLocationPickerWithInstructions(
                    initialLocation: locationManager.currentLocation
                ) { coordinate in
                    // マップで選択された座標を保存して詳細入力画面を表示
                    selectedCoordinateForAdd = coordinate
                    showingMapLocationAdd = true
                }
            }
            .sheet(isPresented: $showingMapLocationAdd) {
                if let coordinate = selectedCoordinateForAdd {
                    MapLocationAddView(coordinate: coordinate) {
                        // 場所追加完了後のクリーンアップ
                        selectedCoordinateForAdd = nil
                    }
                }
            }
            .onChange(of: searchText) { _, newValue in
                searchForLocations(query: newValue)
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("場所名や住所で検索", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.medium)
            .padding(.vertical, Constants.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(Constants.Spacing.medium)
    }

    // MARK: - Category Filter Chip
    private var categoryFilterChip: some View {
        HStack {
            HStack(spacing: Constants.Spacing.small) {
                Image(systemName: selectedCategory?.systemImage ?? "")
                    .foregroundColor(Color(selectedCategory?.color ?? "gray"))

                Text(selectedCategory?.rawValue ?? "")
                    .font(.caption)
                    .fontWeight(.medium)

                Button(action: { selectedCategory = nil }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, Constants.Spacing.small)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )

            Spacer()
        }
        .padding(.horizontal, Constants.Spacing.medium)
        .padding(.bottom, Constants.Spacing.small)
    }

    // MARK: - Preset Locations Section
    private var presetLocationsSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("登録済みの場所")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, Constants.Spacing.small)

            ForEach(filteredPresetLocations) { location in
                LocationSearchRow(
                    location: location,
                    distance: distanceToLocation(location),
                    onTap: {
                        selectedLocation = location
                        showingCheckInForm = true
                    },
                    onShowOnMap: onLocationSelected != nil ? {
                        onLocationSelected?(location.coordinate, location.name)
                        dismiss()
                    } : nil
                )
            }
        }
    }

    // MARK: - Search Results Section
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack {
                Text("検索結果")
                    .font(.headline)
                    .fontWeight(.semibold)

                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Spacer()
            }
            .padding(.horizontal, Constants.Spacing.small)

            ForEach(searchResults, id: \.self) { mapItem in
                MapItemSearchRow(
                    mapItem: mapItem,
                    onTap: {
                        createLocationFromMapItem(mapItem)
                    },
                    onShowOnMap: onLocationSelected != nil ? {
                        onLocationSelected?(mapItem.placemark.coordinate, mapItem.name ?? "検索結果")
                        dismiss()
                    } : nil
                )
            }
        }
    }

    // MARK: - Empty Search State
    private var emptySearchState: some View {
        VStack(spacing: Constants.Spacing.medium) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            VStack(spacing: Constants.Spacing.small) {
                Text("検索結果が見つかりません")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("別のキーワードで検索してみてください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Constants.Spacing.extraLarge)
    }

    // MARK: - Add New Location Section
    private var addNewLocationSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("新しい場所を追加")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, Constants.Spacing.small)

            VStack(spacing: Constants.Spacing.small) {
                // マップから追加
                Button(action: {
                    showingMapPicker = true
                }) {
                    HStack {
                        Image(systemName: "map")
                            .font(.title2)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("マップから追加")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Text("マップ上で位置を選択して追加")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(Constants.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                // 現在地から追加（従来の方法）
                Button(action: {
                    showingAddLocation = true
                }) {
                    HStack {
                        Image(systemName: "location")
                            .font(.title2)
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("現在地から追加")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Text("GPS位置情報を使用して追加")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(Constants.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                            .fill(Color(.systemGray6))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helper Methods
    private func searchForLocations(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        Task {
            // 現在地周辺で検索（位置情報がない場合は東京駅を中心に）
            let center = locationManager.currentLocation ?? CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
            let region = MKCoordinateRegion(
                center: center,
                latitudinalMeters: 50000, // 50km範囲
                longitudinalMeters: 50000
            )

            let results = await locationManager.searchPlaces(query: query, region: region)

            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        }
    }

    private func distanceToLocation(_ location: CheckInLocation) -> String? {
        guard let currentLocation = locationManager.currentLocation else { return nil }

        let distance = locationManager.calculateDistance(
            from: currentLocation,
            to: location.coordinate
        )

        return locationManager.formatDistance(distance)
    }

    private func createLocationFromMapItem(_ mapItem: MKMapItem) {
        let newLocation = CheckInLocation(
            name: mapItem.name ?? "不明な場所",
            address: mapItem.placemark.title,
            latitude: mapItem.placemark.coordinate.latitude,
            longitude: mapItem.placemark.coordinate.longitude,
            category: .other, // デフォルトはその他
            isPreset: false
        )

        selectedLocation = newLocation
        showingCheckInForm = true
    }
}

// MARK: - Supporting Views

struct LocationSearchRow: View {
    let location: CheckInLocation
    let distance: String?
    let onTap: () -> Void
    let onShowOnMap: (() -> Void)?

    init(location: CheckInLocation, distance: String?, onTap: @escaping () -> Void, onShowOnMap: (() -> Void)? = nil) {
        self.location = location
        self.distance = distance
        self.onTap = onTap
        self.onShowOnMap = onShowOnMap
    }

    var body: some View {
        HStack(spacing: Constants.Spacing.medium) {
            // カテゴリアイコン
            Image(systemName: location.category.systemImage)
                .foregroundColor(Color(location.category.color))
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack {
                    Text(location.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let distance = distance {
                        Text("• \(distance)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let address = location.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // アクションボタン群
            HStack(spacing: Constants.Spacing.small) {
                // マップで表示ボタン
                if let onShowOnMap = onShowOnMap {
                    Button(action: onShowOnMap) {
                        Image(systemName: "map")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }

                // チェックインボタン
                Button(action: onTap) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.green.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Constants.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct MapItemSearchRow: View {
    let mapItem: MKMapItem
    let onTap: () -> Void
    let onShowOnMap: (() -> Void)?

    init(mapItem: MKMapItem, onTap: @escaping () -> Void, onShowOnMap: (() -> Void)? = nil) {
        self.mapItem = mapItem
        self.onTap = onTap
        self.onShowOnMap = onShowOnMap
    }

    var body: some View {
        HStack(spacing: Constants.Spacing.medium) {
            Image(systemName: "mappin")
                .foregroundColor(.blue)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(mapItem.name ?? "不明な場所")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if let title = mapItem.placemark.title {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // アクションボタン群
            HStack(spacing: Constants.Spacing.small) {
                // マップで表示ボタン
                if let onShowOnMap = onShowOnMap {
                    Button(action: onShowOnMap) {
                        Image(systemName: "map")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }

                // チェックインボタン
                Button(action: onTap) {
                    Image(systemName: "plus.circle")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.green.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Constants.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct CategoryFilterView: View {
    @Binding var selectedCategory: CheckInLocation.LocationCategory?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("カテゴリフィルター") {
                    Button(action: {
                        selectedCategory = nil
                        dismiss()
                    }) {
                        HStack {
                            Text("すべて")
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    ForEach(CheckInLocation.LocationCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: category.systemImage)
                                    .foregroundColor(Color(category.color))

                                Text(category.rawValue)
                                    .foregroundColor(.primary)

                                Spacer()

                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("カテゴリ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SearchableLocationView()
}