import SwiftUI
import CoreLocation

struct MapLocationAddView: View {
    let coordinate: CLLocationCoordinate2D
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var checkInManager = CheckInManager.shared

    @State private var locationName = ""
    @State private var selectedCategory = CheckInLocation.LocationCategory.other
    @State private var address = ""
    @State private var isLoading = false
    @State private var isLoadingAddress = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                    // 座標情報表示
                    coordinateInfoSection

                    // 場所名入力
                    locationNameSection

                    // カテゴリ選択
                    categorySection

                    // 住所情報
                    addressSection

                    // 保存ボタン
                    saveButton
                }
                .padding(Constants.Spacing.medium)
            }
            .navigationTitle("新しい場所を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        onComplete()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAddressFromCoordinate()
            }
        }
    }

    // MARK: - Coordinate Info Section
    private var coordinateInfoSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.blue)
                    .font(.title2)

                Text("位置情報")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("緯度:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(coordinate.latitude, specifier: "%.6f")")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("経度:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(coordinate.longitude, specifier: "%.6f")")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding(Constants.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(Color(.systemGray6))
            )
        }
    }

    // MARK: - Location Name Section
    private var locationNameSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack {
                Image(systemName: "text.cursor")
                    .foregroundColor(.green)
                    .font(.title2)

                Text("場所名")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("*")
                    .foregroundColor(.red)
                    .font(.headline)
            }

            TextField("場所名を入力してください", text: $locationName)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
        }
    }

    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.orange)
                    .font(.title2)

                Text("カテゴリ")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Constants.Spacing.small) {
                    ForEach(CheckInLocation.LocationCategory.allCases, id: \.self) { category in
                        CategorySelectionCard(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, Constants.Spacing.small)
            }
            .padding(.horizontal, -Constants.Spacing.small)
        }
    }

    // MARK: - Address Section
    private var addressSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.purple)
                    .font(.title2)

                Text("住所")
                    .font(.headline)
                    .fontWeight(.semibold)

                if isLoadingAddress {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if address.isEmpty && !isLoadingAddress {
                VStack {
                    Text("住所を取得できませんでした")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("再取得") {
                        loadAddressFromCoordinate()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(Constants.Spacing.medium)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                        .fill(Color(.systemGray6))
                )
            } else if !address.isEmpty {
                Text(address)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(Constants.Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                            .fill(Color(.systemGray6))
                    )
            }
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveLocation) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.headline)
                }

                Text(isLoading ? "保存中..." : "場所を追加")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(locationName.isEmpty ? Color.gray : Color.blue)
            )
        }
        .disabled(locationName.isEmpty || isLoading)
        .padding(.top, Constants.Spacing.large)
    }

    // MARK: - Helper Methods
    private func loadAddressFromCoordinate() {
        isLoadingAddress = true

        Task {
            if let fetchedAddress = await locationManager.reverseGeocode(coordinate: coordinate) {
                await MainActor.run {
                    address = fetchedAddress
                    isLoadingAddress = false
                }
            } else {
                await MainActor.run {
                    address = ""
                    isLoadingAddress = false
                }
            }
        }
    }

    private func saveLocation() {
        guard !locationName.isEmpty else { return }

        isLoading = true

        let newLocation = CheckInLocation(
            name: locationName,
            address: address.isEmpty ? nil : address,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            category: selectedCategory,
            isPreset: false
        )

        // 少し遅延を入れて自然な感じにする
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checkInManager.addUserLocation(newLocation)
            isLoading = false
            onComplete()
            dismiss()
        }
    }
}

// MARK: - Supporting Views

struct CategorySelectionCard: View {
    let category: CheckInLocation.LocationCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: category.systemImage)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : Color(category.color))

                Text(category.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, Constants.Spacing.small)
            .padding(.vertical, Constants.Spacing.small)
            .frame(minWidth: 80, minHeight: 70)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(isSelected ? Color(category.color) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .stroke(isSelected ? Color(category.color) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MapLocationAddView(
        coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
    ) {
        print("Location added")
    }
}