import SwiftUI
import MapKit

struct CheckInMapView: View {
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var checkInManager = CheckInManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), // 東京
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedLocation: CheckInLocation?
    @State private var showingCheckInForm = false
    @State private var showingLocationPermissionAlert = false
    @State private var showingSearchView = false
    @State private var searchedLocation: (coordinate: CLLocationCoordinate2D, name: String)?
    @State private var tempLocationForAdd: CLLocationCoordinate2D?
    @State private var showingAddLocationFromMap = false

    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: allLocations) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        LocationPinView(location: location) {
                            selectedLocation = location
                            showingCheckInForm = true
                        }
                    }
                }
                .overlay(
                    // 検索結果のピンを表示
                    Group {
                        if let searchedLocation = searchedLocation {
                            Map(coordinateRegion: .constant(region), annotationItems: [SearchedLocationItem(coordinate: searchedLocation.coordinate, name: searchedLocation.name)]) { item in
                                MapAnnotation(coordinate: item.coordinate) {
                                    SearchedLocationPinView(name: item.name) {
                                        // 検索された場所をチェックイン場所として設定
                                        let newLocation = CheckInLocation(
                                            name: item.name,
                                            address: nil,
                                            latitude: item.coordinate.latitude,
                                            longitude: item.coordinate.longitude,
                                            category: .other,
                                            isPreset: false
                                        )
                                        selectedLocation = newLocation
                                        showingCheckInForm = true
                                    }
                                }
                            }
                            .allowsHitTesting(false)
                            .background(Color.clear)
                        }
                    }
                )
                .overlay(
                    // 新規追加用の一時ピンを表示
                    Group {
                        if let tempLocation = tempLocationForAdd {
                            Map(coordinateRegion: .constant(region), annotationItems: [TempLocationItem(coordinate: tempLocation)]) { item in
                                MapAnnotation(coordinate: item.coordinate) {
                                    TempLocationPinView {
                                        showingAddLocationFromMap = true
                                    }
                                }
                            }
                            .allowsHitTesting(true)
                            .background(Color.clear)
                        }
                    }
                )
                .onTapGesture { location in
                    // 一時ピン以外の場所をタップした場合、一時ピンをクリア
                    if tempLocationForAdd != nil {
                        withAnimation(.easeOut(duration: 0.3)) {
                            tempLocationForAdd = nil
                        }
                    }
                }
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                        .onEnded { value in
                            switch value {
                            case .second(true, let drag):
                                if let dragLocation = drag?.location {
                                    let coordinate = coordinateFromScreenPoint(dragLocation)
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        tempLocationForAdd = coordinate
                                    }
                                }
                            default:
                                break
                            }
                        }
                )
                .onAppear {
                    setupMap()
                }
                .onChange(of: locationManager.currentLocation) { _, newLocation in
                    if let location = newLocation {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            region.center = location
                        }
                    }
                }

                // フローティングアクションボタン群
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: Constants.Spacing.small) {
                            // 検索ボタン
                            Button(action: { showingSearchView = true }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white)
                                    .font(.title2)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }

                            // 現在位置ボタン
                            Button(action: centerOnCurrentLocation) {
                                Image(systemName: "location")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                        .padding(.trailing, Constants.Spacing.medium)
                        .padding(.bottom, 100) // タブバーの上に配置
                    }
                }

                // ガイダンスメッセージ
                VStack {
                    // 位置情報エラー時のガイダンス
                    if let errorMessage = locationManager.errorMessage {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("位置情報を利用できません")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)

                                Text("🔍 検索ボタンから場所を探してチェックインできます")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(Constants.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )

                            Spacer()
                        }
                        .padding(.horizontal, Constants.Spacing.medium)
                        .padding(.top, Constants.Spacing.medium)
                    }

                    // 長押しヒント（位置情報エラーがない場合、または検索画面が表示されていない場合）
                    if locationManager.errorMessage == nil && tempLocationForAdd == nil {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("💡 ヒント")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)

                                Text("マップを長押しして新しい場所を追加できます")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(Constants.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )

                            Spacer()
                        }
                        .padding(.horizontal, Constants.Spacing.medium)
                        .padding(.top, Constants.Spacing.medium)
                    }

                    Spacer()
                }
            }
            .navigationTitle("チェックイン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("履歴") {
                        CheckInHistoryView()
                    }
                }
            }
            .sheet(isPresented: $showingCheckInForm) {
                if let location = selectedLocation {
                    CheckInFormView(location: location)
                }
            }
            .sheet(isPresented: $showingSearchView) {
                SearchableLocationView { coordinate, locationName in
                    // 検索結果の場所にマップを移動
                    withAnimation(.easeInOut(duration: 1.0)) {
                        region.center = coordinate
                        region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    }
                    // 検索された場所を表示用に保存
                    searchedLocation = (coordinate: coordinate, name: locationName)

                    // 5秒後に検索結果のピンを自動で消す
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            searchedLocation = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddLocationFromMap) {
                if let coordinate = tempLocationForAdd {
                    MapLocationAddView(coordinate: coordinate) {
                        // 場所追加完了後に一時ピンをクリア
                        tempLocationForAdd = nil
                    }
                }
            }
            .alert("位置情報の利用", isPresented: $showingLocationPermissionAlert) {
                Button("設定を開く") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("位置情報を利用するには、設定アプリで位置情報の利用を許可してください。")
            }
        }
    }

    private var allLocations: [CheckInLocation] {
        var locations = CheckInLocation.presetLocations
        locations.append(contentsOf: checkInManager.userLocations)
        return locations
    }

    private func setupMap() {
        // 位置情報の許可は任意にする（エラーアラートは表示しない）
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestLocationPermission()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startLocationUpdates()
        }
        // 位置情報が拒否されている場合は、検索ボタンの使用を促すメッセージを表示
    }

    private func centerOnCurrentLocation() {
        if let currentLocation = locationManager.currentLocation {
            withAnimation(.easeInOut(duration: 1.0)) {
                region.center = currentLocation
                region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            }
        } else {
            // 位置情報がない場合は許可を求める
            locationManager.requestLocationPermission()
            locationManager.startLocationUpdates()
        }
    }

    private func coordinateFromScreenPoint(_ point: CGPoint) -> CLLocationCoordinate2D {
        // 簡単な近似計算（実際のMapKitの座標変換はより複雑）
        let mapWidth = UIScreen.main.bounds.width
        let mapHeight = UIScreen.main.bounds.height

        let xRatio = point.x / mapWidth
        let yRatio = point.y / mapHeight

        let longitudeDelta = region.span.longitudeDelta
        let latitudeDelta = region.span.latitudeDelta

        let longitude = region.center.longitude + (xRatio - 0.5) * longitudeDelta
        let latitude = region.center.latitude - (yRatio - 0.5) * latitudeDelta

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct LocationPinView: View {
    let location: CheckInLocation
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            Button(action: onTap) {
                ZStack {
                    Circle()
                        .fill(Color(location.category.color))
                        .frame(width: 30, height: 30)
                        .shadow(radius: 2)

                    Image(systemName: location.category.systemImage)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
            }

            Text(location.name)
                .font(.caption2)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.9))
                )
                .shadow(radius: 1)
        }
    }
}

// MARK: - Add Location View
struct AddLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var checkInManager = CheckInManager.shared
    @State private var locationName = ""
    @State private var selectedCategory = CheckInLocation.LocationCategory.other
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var address = ""
    @State private var isLoading = false
    @State private var showingMapPicker = false

    var body: some View {
        NavigationView {
            Form {
                Section("場所の情報") {
                    TextField("場所名", text: $locationName)

                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(CheckInLocation.LocationCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.systemImage)
                                    .foregroundColor(Color(category.color))
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("位置情報") {
                    VStack(spacing: Constants.Spacing.small) {
                        HStack {
                            Button("現在地を取得") {
                                getCurrentLocationAndAddress()
                            }
                            .disabled(isLoading)

                            Spacer()

                            Button("マップから選択") {
                                showingMapPicker = true
                            }
                            .foregroundColor(.blue)

                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }

                    if !address.isEmpty {
                        VStack(alignment: .leading) {
                            Text("住所")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(address)
                                .font(.footnote)
                        }
                    }

                    if let coordinate = coordinate {
                        VStack(alignment: .leading) {
                            Text("座標")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("緯度: \(coordinate.latitude, specifier: "%.6f")")
                                .font(.footnote)
                            Text("経度: \(coordinate.longitude, specifier: "%.6f")")
                                .font(.footnote)
                        }
                    }
                }
            }
            .navigationTitle("場所を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveLocation()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingMapPicker) {
                MapLocationPickerView(initialLocation: locationManager.currentLocation) { selectedCoordinate in
                    coordinate = selectedCoordinate
                    loadAddressFromCoordinate(selectedCoordinate)
                }
            }
        }
    }

    private var canSave: Bool {
        !locationName.isEmpty && coordinate != nil
    }

    private func getCurrentLocationAndAddress() {
        isLoading = true

        Task {
            if let location = await locationManager.getCurrentLocation() {
                coordinate = location
                if let addressString = await locationManager.reverseGeocode(coordinate: location) {
                    await MainActor.run {
                        address = addressString
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func loadAddressFromCoordinate(_ selectedCoordinate: CLLocationCoordinate2D) {
        isLoading = true

        Task {
            if let addressString = await locationManager.reverseGeocode(coordinate: selectedCoordinate) {
                await MainActor.run {
                    address = addressString
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    address = ""
                    isLoading = false
                }
            }
        }
    }

    private func saveLocation() {
        guard let coordinate = coordinate else { return }

        let newLocation = CheckInLocation(
            name: locationName,
            address: address.isEmpty ? nil : address,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            category: selectedCategory,
            isPreset: false
        )

        checkInManager.addUserLocation(newLocation)
        dismiss()
    }
}

// MARK: - Supporting Views and Models

struct SearchedLocationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
}

struct TempLocationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct SearchedLocationPinView: View {
    let name: String
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            Button(action: onTap) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 32, height: 32)
                        .shadow(radius: 3)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )

                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
                .scaleEffect(1.1) // 少し大きくして目立たせる
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: true)
            }

            Text(name)
                .font(.caption2)
                .foregroundColor(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red.opacity(0.9))
                )
                .foregroundColor(.white)
                .shadow(radius: 2)
        }
    }
}

struct TempLocationPinView: View {
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            Button(action: onTap) {
                ZStack {
                    // 外側の脈動するリング
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)

                    // メインのピン
                    Circle()
                        .fill(Color.green)
                        .frame(width: 32, height: 32)
                        .shadow(radius: 4)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )

                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
                .scaleEffect(1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: true)
            }

            Text("タップして追加")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.9))
                )
                .shadow(radius: 2)
        }
    }
}

#Preview {
    CheckInMapView()
}