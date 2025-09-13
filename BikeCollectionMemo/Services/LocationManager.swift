import Foundation
import CoreLocation
import MapKit

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentAccuracy: Double = 0 // メートル
    @Published var lastLocation: CLLocation?

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10メートル移動したら更新
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // 設定アプリへの誘導が必要
            errorMessage = "位置情報の利用が許可されていません。設定アプリで許可してください。"
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }

    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }

        isLoading = true
        errorMessage = nil
        locationManager.startUpdatingLocation()
    }

    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLoading = false
    }

    func getCurrentLocation() async -> CLLocationCoordinate2D? {
        return await withCheckedContinuation { continuation in
            guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
                continuation.resume(returning: nil)
                return
            }

            if let currentLocation = currentLocation {
                continuation.resume(returning: currentLocation)
                return
            }

            // 一回だけ位置情報を取得
            locationManager.requestLocation()

            // タイムアウト処理
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                continuation.resume(returning: self.currentLocation)
            }
        }
    }

    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }

            var address = ""
            if let prefecture = placemark.administrativeArea {
                address += prefecture
            }
            if let city = placemark.locality {
                address += city
            }
            if let subLocality = placemark.subLocality {
                address += subLocality
            }
            if let thoroughfare = placemark.thoroughfare {
                address += thoroughfare
            }

            return address.isEmpty ? nil : address
        } catch {
            print("Reverse geocoding failed: \(error)")
            return nil
        }
    }

    func searchPlaces(query: String, region: MKCoordinateRegion) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            return response.mapItems
        } catch {
            print("Place search failed: \(error)")
            return []
        }
    }

    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.currentLocation = location.coordinate
            self.currentAccuracy = location.horizontalAccuracy
            self.lastLocation = location
            self.isLoading = false
            self.errorMessage = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLoading = false

            if let clError = error as? CLError {
                switch clError.code {
                case .locationUnknown:
                    self.errorMessage = "位置情報を取得できませんでした"
                case .denied:
                    self.errorMessage = "位置情報の利用が拒否されています"
                case .network:
                    self.errorMessage = "ネットワークエラーが発生しました"
                default:
                    self.errorMessage = "位置情報の取得に失敗しました"
                }
            } else {
                self.errorMessage = "位置情報の取得に失敗しました"
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startLocationUpdates()
            case .denied, .restricted:
                self.stopLocationUpdates()
                self.errorMessage = "位置情報の利用が許可されていません"
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}