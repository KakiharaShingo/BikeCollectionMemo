import SwiftUI
import CoreLocation

struct CourseSelectionView: View {
    let onStart: (TimingCourse, Bike?) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var lapTimerManager = LapTimerManager.shared
    @StateObject private var bikeViewModel = BikeViewModel()
    @StateObject private var locationManager = LocationManager.shared

    @State private var selectedCourse: TimingCourse?
    @State private var selectedBike: Bike?
    @State private var showingCustomCourseCreation = false
    @State private var showingLocationPicker = false
    @State private var showingGpsAccuracyAlert = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                // コース選択セクション
                courseSelectionSection

                // バイク選択セクション
                bikeSelectionSection

                // 開始ボタン
                startButton

                Spacer()
            }
            .padding(Constants.Spacing.medium)
            .navigationTitle("コース選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新規作成") {
                        showingCustomCourseCreation = true
                    }
                    .font(.subheadline)
                }
            }
            .sheet(isPresented: $showingCustomCourseCreation) {
                CustomCourseCreationView()
            }
        }
    }

    // MARK: - Course Selection Section
    private var courseSelectionSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            HStack {
                Image(systemName: "map")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("コースを選択")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("*")
                    .foregroundColor(.red)
                    .font(.headline)
            }

            ScrollView {
                LazyVStack(spacing: Constants.Spacing.small) {
                    ForEach(lapTimerManager.getSavedCourses(), id: \.id) { course in
                        CourseSelectionCard(
                            course: course,
                            isSelected: selectedCourse?.id == course.id
                        ) {
                            selectedCourse = course
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
        }
    }

    // MARK: - Bike Selection Section
    private var bikeSelectionSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            HStack {
                Image(systemName: "bicycle")
                    .font(.title2)
                    .foregroundColor(.green)

                Text("バイクを選択（任意）")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Constants.Spacing.small) {
                    // バイクなしオプション
                    CourseBikeSelectionCard(
                        bike: nil,
                        isSelected: selectedBike == nil
                    ) {
                        selectedBike = nil
                    }

                    ForEach(bikeViewModel.bikes, id: \.id) { bike in
                        CourseBikeSelectionCard(
                            bike: bike,
                            isSelected: selectedBike?.id == bike.id
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

    // MARK: - Start Button
    private var startButton: some View {
        VStack(spacing: Constants.Spacing.medium) {
            // コース選択なしで開始するボタン
            Button(action: {
                startWithoutCourse()
            }) {
                HStack {
                    Image(systemName: "play.circle")
                        .font(.headline)

                    Text("フリーモードで開始")
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
            
            // コース選択ありで開始するボタン
            Button(action: {
                guard let course = selectedCourse else { return }
                startWithCourse(course)
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.headline)

                    Text("コースモードで開始")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                        .fill(selectedCourse != nil ? Color.green : Color.gray)
                )
            }
            .disabled(selectedCourse == nil)
        }
        .padding(.top, Constants.Spacing.large)
        .alert("GPS精度が低いです", isPresented: $showingGpsAccuracyAlert) {
            Button("続行") {
                guard let course = selectedCourse else { return }
                onStart(course, selectedBike)
                dismiss()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("現在のGPS精度は\(String(format: "%.0f", lapTimerManager.gpsAccuracy))メートルです。精度が低いと正確な計測ができません。屋外で計測を開始することをお勧めします。")
        }
    }
    
    private func startWithoutCourse() {
        // GPS精度を確認
        if !lapTimerManager.checkGpsAccuracy() {
            showingGpsAccuracyAlert = true
            return
        }
        
        // フリーモード用の仮想コースを作成
        let freeModeCourse = TimingCourse(
            name: "フリーモード",
            startFinishLine: CLLocationCoordinate2D(latitude: 0, longitude: 0), // ダミー座標
            toleranceRadius: 0, // 自動ラップ検出を無効化
            expectedLapDistance: nil,
            isPreset: false
        )
        
        onStart(freeModeCourse, selectedBike)
        dismiss()
    }
    
    private func startWithCourse(_ course: TimingCourse) {
        // GPS精度を確認
        if !lapTimerManager.checkGpsAccuracy() {
            showingGpsAccuracyAlert = true
            return
        }
        
        onStart(course, selectedBike)
        dismiss()
    }
}

// MARK: - Course Selection Card
struct CourseSelectionCard: View {
    let course: TimingCourse
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Constants.Spacing.medium) {
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    HStack {
                        Text(course.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        if course.isPreset {
                            Text("公式")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue)
                                )
                        }

                        Spacer()
                    }

                    if let expectedDistance = course.expectedLapDistance {
                        Text("推定ラップ: \(expectedDistance.distanceString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("許容範囲: \(Int(course.toleranceRadius))m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .green : .gray)
            }
            .padding(Constants.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Course Bike Selection Card
struct CourseBikeSelectionCard: View {
    let bike: Bike?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Constants.Spacing.small) {
                Image(systemName: bike != nil ? "bicycle" : "questionmark")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : (bike != nil ? .green : .gray))

                Text(bike?.name ?? "選択なし")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(Constants.Spacing.medium)
            .frame(minWidth: 100, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(isSelected ? Color.green : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Course Creation View
struct CustomCourseCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var lapTimerManager = LapTimerManager.shared
    @StateObject private var locationManager = LocationManager.shared

    @State private var courseName = ""
    @State private var toleranceRadius: Double = 30.0
    @State private var expectedDistance = ""
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var showingLocationPicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                    // コース名
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        HStack {
                            Text("コース名")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("*")
                                .foregroundColor(.red)
                        }

                        TextField("コース名を入力", text: $courseName)
                            .textFieldStyle(.roundedBorder)
                    }

                    // スタート/フィニッシュライン
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        HStack {
                            Text("スタート/フィニッシュライン")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("*")
                                .foregroundColor(.red)
                        }

                        Button(action: {
                            showingLocationPicker = true
                        }) {
                            HStack {
                                Image(systemName: selectedLocation != nil ? "checkmark.circle" : "location")
                                    .foregroundColor(selectedLocation != nil ? .green : .blue)

                                Text(selectedLocation != nil ? "位置が選択されました" : "位置を選択")
                                    .foregroundColor(selectedLocation != nil ? .green : .blue)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                                    .fill(Color(.systemGray6))
                            )
                        }

                        if let location = selectedLocation {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("緯度: \(location.latitude, specifier: "%.6f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("経度: \(location.longitude, specifier: "%.6f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // 許容範囲
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("許容範囲 (\(Int(toleranceRadius))m)")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Slider(value: $toleranceRadius, in: 10...100, step: 5)
                            .accentColor(.blue)

                        HStack {
                            Text("10m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("100m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // 推定ラップ距離（任意）
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("推定ラップ距離（任意）")
                            .font(.headline)
                            .fontWeight(.semibold)

                        TextField("例: 5800", text: $expectedDistance)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)

                        Text("メートル単位で入力してください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // 保存ボタン
                    Button(action: saveCourse) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .font(.headline)

                            Text("コースを作成")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                                .fill(canSave ? Color.blue : Color.gray)
                        )
                    }
                    .disabled(!canSave)
                    .padding(.top, Constants.Spacing.large)
                }
                .padding(Constants.Spacing.medium)
            }
            .navigationTitle("新しいコース")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                MapLocationPickerView(
                    initialLocation: locationManager.currentLocation,
                    onLocationSelected: { coordinate in
                        selectedLocation = coordinate
                    }
                )
            }
        }
    }

    private var canSave: Bool {
        !courseName.isEmpty && selectedLocation != nil
    }

    private func saveCourse() {
        guard let location = selectedLocation else { return }

        let expectedDistanceValue = Double(expectedDistance)

        let newCourse = TimingCourse(
            name: courseName,
            startFinishLine: location,
            toleranceRadius: toleranceRadius,
            expectedLapDistance: expectedDistanceValue,
            isPreset: false
        )

        lapTimerManager.saveCustomCourse(newCourse)
        dismiss()
    }
}

#Preview {
    CourseSelectionView { course, bike in
        print("Selected course: \(course.name), bike: \(bike?.name ?? "None")")
    }
}