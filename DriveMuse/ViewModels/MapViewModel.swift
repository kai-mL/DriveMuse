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
    
    private var searchTask: Task<Void, Never>?
    private let locationManager = LocationManager()
    
    init() {
        // 位置情報の許可をリクエスト
        locationManager.requestLocationPermission()
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
            
        } catch {
            if !Task.isCancelled {
                self.error = error
                searchResults = []
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
        if let currentLocation = locationManager.currentLocation {
            region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
        }
    }
    
    /// リソースのクリーンアップ
    func cleanup() {
        searchTask?.cancel()
        locationManager.stopLocationUpdates()
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