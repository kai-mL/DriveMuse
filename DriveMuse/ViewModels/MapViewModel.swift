import Foundation
import MapKit
import Combine

/// 地図とPOI検索のビジネスロジックを管理するViewModel
@MainActor
class MapViewModel: ObservableObject {
    @Published var region = Constants.DefaultLocation.defaultRegion
    @Published var selectedMapItem: MKMapItem?
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false
    @Published var error: Error?
    @Published var isLocationPermissionGranted = false
    
    private var searchTask: Task<Void, Never>?
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupLocationObservers()
        // 位置情報の許可をリクエスト
        locationManager.requestLocationPermission()
    }
    
    private func setupLocationObservers() {
        // 位置情報の許可状況を監視
        locationManager.$authorizationStatus
            .sink { [weak self] status in
                self?.handleLocationAuthorizationChange(status)
            }
            .store(in: &cancellables)
        
        // 現在地の更新を監視
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
        
        // 位置情報エラーを監視
        locationManager.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }
    
    private func handleLocationAuthorizationChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationPermissionGranted = true
        case .denied, .restricted:
            isLocationPermissionGranted = false
            error = LocationError.permissionDenied
        case .notDetermined:
            isLocationPermissionGranted = false
        @unknown default:
            isLocationPermissionGranted = false
        }
    }
    
    private func handleLocationUpdate(_ location: CLLocation) {
        // 位置情報が許可されている場合、初回取得時に地図を現在地に移動
        if isLocationPermissionGranted {
            region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
        }
    }
    
    /// POI検索を実行（デバウンス機能付き）
    func searchPOIs(in region: MKCoordinateRegion) {
        // 既存の検索タスクをキャンセル
        searchTask?.cancel()
        
        self.region = region
        
        searchTask = Task {
            // デバウンス用の遅延
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            
            if Task.isCancelled { return }
            
            await performPOISearch(in: region)
        }
    }
    
    /// 実際のPOI検索処理
    private func performPOISearch(in region: MKCoordinateRegion) async {
        isSearching = true
        defer { isSearching = false }
        
        // デバッグ用：検索範囲をログ出力
        #if DEBUG
        print("POI検索開始 - 中心座標: \(region.center.latitude), \(region.center.longitude)")
        print("検索範囲: \(region.span.latitudeDelta) x \(region.span.longitudeDelta)")
        #endif
        
        do {
            let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: Constants.POICategories.tourist)
            
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            if Task.isCancelled { return }
            
            // 中心から近い順に並べ、上位指定件数を取得
            let sortedResults = response.mapItems.sorted { item1, item2 in
                let distance1 = MKMapPoint(item1.placemark.coordinate).distance(to: MKMapPoint(region.center))
                let distance2 = MKMapPoint(item2.placemark.coordinate).distance(to: MKMapPoint(region.center))
                return distance1 < distance2
            }
            
            searchResults = Array(sortedResults.prefix(Constants.Map.maxPOICount))
            error = nil
            
            // デバッグ用：検索結果をログ出力
            #if DEBUG
            print("POI検索完了 - 見つかった件数: \(response.mapItems.count)")
            print("表示する件数: \(searchResults.count)")
            if searchResults.isEmpty {
                print("⚠️ 検索結果が0件です。シミュレータでは観光地データが限られている可能性があります。")
            }
            #endif
            
        } catch {
            if !Task.isCancelled {
                // MKError.placemarkNotFound (error 4) は無視して、単に結果なしとして扱う
                if let mkError = error as? MKError, mkError.code == .placemarkNotFound {
                    searchResults = []
                    self.error = nil // エラーを表示しない
                    #if DEBUG
                    print("ℹ️ POI検索: 結果が見つかりませんでした（MKError.placemarkNotFound）")
                    #endif
                } else {
                    self.error = error
                    searchResults = []
                    #if DEBUG
                    print("❌ POI検索エラー: \(error.localizedDescription)")
                    if let mkError = error as? MKError {
                        print("MKError code: \(mkError.code.rawValue)")
                    }
                    #endif
                }
            }
        }
    }
    
    /// 指定されたマップアイテムを選択
    func selectMapItem(_ mapItem: MKMapItem?) {
        selectedMapItem = mapItem
    }
    
    /// 評価を計算
    func calculateRating(for coordinate: CLLocationCoordinate2D) -> Double {
        POIAnnotation.calculateRating(from: region.center, to: coordinate)
    }
    
    /// 現在地に移動
    func moveToCurrentLocation() {
        guard isLocationPermissionGranted else {
            error = LocationError.permissionDenied
            return
        }
        
        if let currentLocation = locationManager.currentLocation {
            region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
        } else {
            // 現在地が取得されていない場合は、取得をリクエスト
            locationManager.requestLocationPermission()
        }
    }
    
    /// リソースのクリーンアップ
    func cleanup() {
        searchTask?.cancel()
        locationManager.stopLocationUpdates()
        cancellables.removeAll()
    }
}

// MARK: - Search Error
enum SearchError: LocalizedError {
    case noResults
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noResults:
            return "検索結果が見つかりませんでした"
        case .networkError:
            return Constants.Strings.searchError
        }
    }
} 