import SwiftUI
import MapKit

struct MapLocationPickerView: View {
    let initialLocation: CLLocationCoordinate2D?
    let onLocationSelected: (CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager.shared

    @State private var region: MKCoordinateRegion
    @State private var mapPosition: MapCameraPosition
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var isDragging = false

    init(initialLocation: CLLocationCoordinate2D? = nil, onLocationSelected: @escaping (CLLocationCoordinate2D) -> Void) {
        self.initialLocation = initialLocation
        self.onLocationSelected = onLocationSelected

        // 初期位置を設定（提供されている場合はその位置、なければ東京）
        let center = initialLocation ?? CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        let initialRegion = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        self._region = State(initialValue: initialRegion)
        self._mapPosition = State(initialValue: .region(initialRegion))
        self._selectedCoordinate = State(initialValue: initialLocation)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // メインのマップ
                Map(position: $mapPosition)
                    .onAppear {
                        setupInitialLocation()
                    }
                    .onMapCameraChange(frequency: .continuous) { context in
                        region = context.region
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { _ in
                                isDragging = true
                            }
                            .onEnded { _ in
                                isDragging = false
                                // ドラッグ終了時に中央の座標を選択座標として設定
                                selectedCoordinate = region.center
                            }
                    )

                // 中央の固定ピン
                VStack {
                    Spacer()
                    Image(systemName: "mappin")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                    Spacer()
                }

                // 座標情報とボタン
                VStack {
                    Spacer()

                    VStack(spacing: Constants.Spacing.medium) {
                        // 座標情報表示
                        coordinateInfoCard

                        // アクションボタン群
                        actionButtons
                    }
                    .padding(Constants.Spacing.medium)
                }

                // 現在位置ボタン
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: Constants.Spacing.small) {
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
                    }
                    Spacer()
                }
            }
            .navigationTitle("場所を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Coordinate Info Card
    private var coordinateInfoCard: some View {
        VStack(spacing: Constants.Spacing.small) {
            HStack {
                Image(systemName: "location.circle")
                    .foregroundColor(.blue)
                    .font(.title3)

                Text("選択中の位置")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()
            }

            if let coordinate = selectedCoordinate ?? (isValidCoordinate(region.center) ? region.center : nil) {
                VStack(spacing: 4) {
                    HStack {
                        Text("緯度:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(coordinate.latitude, specifier: "%.6f")")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }

                    HStack {
                        Text("経度:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(coordinate.longitude, specifier: "%.6f")")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            }
        }
        .padding(Constants.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: Constants.Spacing.medium) {
            // マップタイプ切り替えボタン
            Button(action: {
                // マップタイプ切り替え（標準/衛星）
            }) {
                HStack {
                    Image(systemName: "map")
                        .font(.subheadline)
                    Text("地図")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, Constants.Spacing.medium)
                .padding(.vertical, Constants.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
            }

            // 位置確定ボタン
            Button(action: confirmLocation) {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                    Text("この位置を選択")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, Constants.Spacing.medium)
                .padding(.vertical, Constants.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                        .fill(Color.green)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                )
            }
        }
    }

    // MARK: - Helper Methods
    private func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude != 0.0 || coordinate.longitude != 0.0
    }

    private func setupInitialLocation() {
        if let initialLocation = initialLocation {
            // 初期位置が提供されている場合はその位置を使用
            let newRegion = MKCoordinateRegion(
                center: initialLocation,
                span: region.span
            )
            mapPosition = .region(newRegion)
            region = newRegion
            selectedCoordinate = initialLocation
        } else if let currentLocation = locationManager.currentLocation {
            // 現在位置が利用可能な場合はその位置を使用
            withAnimation(.easeInOut(duration: 1.0)) {
                let newRegion = MKCoordinateRegion(
                    center: currentLocation,
                    span: region.span
                )
                mapPosition = .region(newRegion)
                region = newRegion
                selectedCoordinate = currentLocation
            }
        }
        // どちらもない場合は東京をデフォルトとして使用（初期化時に設定済み）
    }

    private func centerOnCurrentLocation() {
        if let currentLocation = locationManager.currentLocation {
            withAnimation(.easeInOut(duration: 1.0)) {
                let newRegion = MKCoordinateRegion(
                    center: currentLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                mapPosition = .region(newRegion)
                region = newRegion
                selectedCoordinate = currentLocation
            }
        } else {
            // 位置情報が利用できない場合は許可を求める
            locationManager.requestLocationPermission()
            locationManager.startLocationUpdates()
        }
    }

    private func confirmLocation() {
        let coordinate = selectedCoordinate ?? region.center
        onLocationSelected(coordinate)
        dismiss()
    }
}

// MARK: - Map Location Picker with Instructions
struct MapLocationPickerWithInstructions: View {
    let initialLocation: CLLocationCoordinate2D?
    let onLocationSelected: (CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingPicker = false

    var body: some View {
        NavigationView {
            VStack(spacing: Constants.Spacing.large) {
                // 説明セクション
                instructionsSection

                // プレビューマップ
                previewMapSection

                // アクションボタン
                actionButton

                Spacer()
            }
            .padding(Constants.Spacing.medium)
            .navigationTitle("マップから位置を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPicker) {
                MapLocationPickerView(initialLocation: initialLocation) { coordinate in
                    onLocationSelected(coordinate)
                }
            }
        }
    }

    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            HStack {
                Image(systemName: "map.circle")
                    .font(.title)
                    .foregroundColor(.blue)

                Text("マップから位置を選択")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                InstructionRow(
                    icon: "1.circle.fill",
                    color: .blue,
                    text: "マップを表示して目的の場所を探します"
                )

                InstructionRow(
                    icon: "2.circle.fill",
                    color: .blue,
                    text: "ドラッグして赤いピンを目的の位置に合わせます"
                )

                InstructionRow(
                    icon: "3.circle.fill",
                    color: .blue,
                    text: "「この位置を選択」で位置を確定します"
                )
            }
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

    // MARK: - Preview Map Section
    private var previewMapSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("現在の表示エリア")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ZStack {
                // 簡易マップ表示
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            Image(systemName: "map")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)

                            Text("マップを開いて位置を選択")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )

                // 中央のピンアイコン
                Image(systemName: "mappin")
                    .font(.title)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: { showingPicker = true }) {
            HStack {
                Image(systemName: "map")
                    .font(.headline)

                Text("マップを開く")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(Color.blue)
            )
        }
    }
}

// MARK: - Supporting Views
struct InstructionRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Constants.Spacing.small) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

#Preview {
    MapLocationPickerView { coordinate in
        print("Selected: \(coordinate)")
    }
}