import SwiftUI
import CoreData

struct CheckInFormView: View {
    let location: CheckInLocation
    @Environment(\.dismiss) private var dismiss
    @StateObject private var checkInManager = CheckInManager.shared
    @StateObject private var locationManager = LocationManager.shared

    // フォーム入力値
    @State private var selectedBike: Bike?
    @State private var memo = ""
    @State private var selectedWeather: WeatherCondition?
    @State private var companions: [String] = []
    @State private var newCompanion = ""

    // 状態管理
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    @State private var bikes: [Bike] = []

    // Core Data
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Bike.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Bike.name, ascending: true)]
    ) private var fetchedBikes: FetchedResults<Bike>

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                    // 場所情報
                    locationInfoSection

                    // バイク選択
                    bikeSelectionSection

                    // 天気選択
                    weatherSelectionSection

                    // メモ入力
                    memoSection

                    // 同行者入力
                    companionsSection

                    // チェックインボタン
                    checkInButton
                }
                .padding(Constants.Spacing.medium)
            }
            .navigationTitle("チェックイン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupBikes()
            }
            .alert("チェックイン完了", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("\(location.name)にチェックインしました！")
            }
        }
    }

    // MARK: - Location Info Section
    private var locationInfoSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack {
                Image(systemName: location.category.systemImage)
                    .foregroundColor(Color(location.category.color))
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(location.name)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(location.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if let address = location.address {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }

            // 距離表示
            if let currentLocation = locationManager.currentLocation {
                let distance = locationManager.calculateDistance(
                    from: currentLocation,
                    to: location.coordinate
                )

                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text("現在地から \(locationManager.formatDistance(distance))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }

            // 過去の訪問回数
            let visitCount = checkInManager.getCheckInCount(for: location.id)
            if visitCount > 0 {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Text("過去に\(visitCount)回訪問")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(Constants.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Bike Selection Section
    private var bikeSelectionSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("使用バイク")
                .font(.headline)

            if bikes.isEmpty {
                Text("バイクが登録されていません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(Constants.Spacing.medium)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Constants.Spacing.small) {
                        // バイクなしオプション
                        BikeSelectionCard(
                            bikeName: "記録しない",
                            bikeModel: "",
                            isSelected: selectedBike == nil
                        ) {
                            selectedBike = nil
                        }

                        // バイクリスト
                        ForEach(bikes, id: \.objectID) { bike in
                            BikeSelectionCard(
                                bikeName: bike.name ?? "名前なし",
                                bikeModel: bike.model ?? "",
                                isSelected: selectedBike?.objectID == bike.objectID
                            ) {
                                selectedBike = bike
                            }
                        }
                    }
                    .padding(.horizontal, Constants.Spacing.small)
                }
                .padding(.horizontal, -Constants.Spacing.small)
            }
        }
    }

    // MARK: - Weather Selection Section
    private var weatherSelectionSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("天気")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Constants.Spacing.small) {
                    ForEach(WeatherCondition.allCases, id: \.self) { weather in
                        WeatherSelectionCard(
                            weather: weather,
                            isSelected: selectedWeather == weather
                        ) {
                            selectedWeather = selectedWeather == weather ? nil : weather
                        }
                    }
                }
                .padding(.horizontal, Constants.Spacing.small)
            }
            .padding(.horizontal, -Constants.Spacing.small)
        }
    }

    // MARK: - Memo Section
    private var memoSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("メモ")
                .font(.headline)

            TextEditor(text: $memo)
                .frame(minHeight: 100)
                .padding(Constants.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                        .stroke(Color.secondary.opacity(0.3))
                )
                .overlay(
                    // プレースホルダー
                    Group {
                        if memo.isEmpty {
                            VStack {
                                HStack {
                                    Text("思い出やコメントを記録...")
                                        .foregroundColor(.secondary)
                                        .padding(.leading, Constants.Spacing.small + 4)
                                        .padding(.top, Constants.Spacing.small + 8)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                )
        }
    }

    // MARK: - Companions Section
    private var companionsSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("同行者")
                .font(.headline)

            // 新しい同行者追加
            HStack {
                TextField("同行者名を入力", text: $newCompanion)
                    .textFieldStyle(.roundedBorder)

                Button("追加") {
                    addCompanion()
                }
                .disabled(newCompanion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // 同行者リスト
            if !companions.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100))
                ], spacing: Constants.Spacing.small) {
                    ForEach(companions.indices, id: \.self) { index in
                        CompanionChip(
                            name: companions[index]
                        ) {
                            companions.remove(at: index)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Check In Button
    private var checkInButton: some View {
        Button(action: submitCheckIn) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.headline)
                }

                Text(isSubmitting ? "チェックイン中..." : "チェックインする")
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
        .disabled(isSubmitting)
        .padding(.top, Constants.Spacing.large)
    }

    // MARK: - Helper Methods
    private func setupBikes() {
        bikes = Array(fetchedBikes)
    }

    private func addCompanion() {
        let trimmedName = newCompanion.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty && !companions.contains(trimmedName) {
            companions.append(trimmedName)
            newCompanion = ""
        }
    }

    private func submitCheckIn() {
        isSubmitting = true

        let record = CheckInRecord(
            location: location,
            bikeId: selectedBike?.id?.uuidString,
            bikeName: selectedBike?.name,
            memo: memo.isEmpty ? nil : memo,
            weather: selectedWeather?.rawValue,
            companions: companions
        )

        // 少し遅延を入れて自然な感じにする
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkInManager.addCheckInRecord(record)
            isSubmitting = false
            showingSuccess = true
        }
    }
}

// MARK: - Supporting Views

struct BikeSelectionCard: View {
    let bikeName: String
    let bikeModel: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bikeName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)

                if !bikeModel.isEmpty {
                    Text(bikeModel)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, Constants.Spacing.medium)
            .padding(.vertical, Constants.Spacing.small)
            .frame(minWidth: 100)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct WeatherSelectionCard: View {
    let weather: WeatherCondition
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: weather.systemImage)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(weather.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding(Constants.Spacing.small)
            .frame(minWidth: 60)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

struct CompanionChip: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.caption)
                .foregroundColor(.primary)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Constants.Spacing.small)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                .fill(Color(.systemGray5))
        )
    }
}

#Preview {
    CheckInFormView(location: CheckInLocation.presetLocations[0])
}