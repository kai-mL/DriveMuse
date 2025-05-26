import SwiftUI
import MapKit

/// UIKitのMKMapViewをSwiftUIで利用するラッパー
struct TouristMapView: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    
    // Coordinatorを生成してDelegateを管理
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MKMapViewの生成と初期設定
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        
        // 地図の初期設定
        setupMapView(mapView)
        
        // 渋谷駅の固定ピンを追加
        addShibuyaStationPin(to: mapView)
        
        return mapView
    }
    
    // regionが変わったときに呼ばれる
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if !uiView.region.isEqual(to: viewModel.region) {
            uiView.setRegion(viewModel.region, animated: true)
        }
        
        // 検索結果のアノテーションを更新
        context.coordinator.updatePOIAnnotations()
    }
    
    // MARK: - Helper Methods
    
    /// 地図の初期設定
    private func setupMapView(_ mapView: MKMapView) {
        mapView.setRegion(viewModel.region, animated: false)
        
        // POIフィルタを設定 (iOS17+)
        let config = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .default)
        config.pointOfInterestFilter = MKPointOfInterestFilter(including: Constants.POICategories.tourist)
        mapView.preferredConfiguration = config
        
        // ユーザーの現在地を表示
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
    }
    
    /// 渋谷駅のピンを追加
    private func addShibuyaStationPin(to mapView: MKMapView) {
        let station = MKPointAnnotation()
        station.coordinate = Constants.DefaultLocation.shibuya
        station.title = Constants.Strings.shibuyaStation
        mapView.addAnnotation(station)
    }
}

// MARK: - Coordinator
extension TouristMapView {
    /// MKMapViewDelegateおよび検索ロジックを管理するCoordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TouristMapView
        weak var mapView: MKMapView?
        
        init(_ parent: TouristMapView) {
            self.parent = parent
            super.init()
        }
        
        // MARK: - MKMapViewDelegate Methods
        
        /// 地図移動完了時の処理
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // ViewModelに新しい地域での検索を依頼（非同期で実行）
            Task { @MainActor in
                parent.viewModel.searchPOIs(in: mapView.region)
            }
        }
        
        /// アノテーションビューの生成
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // ユーザーの現在地は標準のビューを使用
            if annotation is MKUserLocation { return nil }
            
            // 渋谷駅のピン
            if annotation.title == Constants.Strings.shibuyaStation {
                return createStationAnnotationView(for: annotation, in: mapView)
            }
            
            // POIのマーカー
            if annotation is POIAnnotation {
                return createPOIAnnotationView(for: annotation, in: mapView)
            }
            
            return nil
        }
        
        /// アノテーション選択時の処理
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let poi = view.annotation as? POIAnnotation {
                Task { @MainActor in
                    parent.viewModel.selectMapItem(poi.mapItem)
                }
            }
        }
        
        /// アノテーション選択解除時の処理
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            // 必要に応じて処理を追加
        }
        
        // MARK: - Annotation Management
        
        /// POIアノテーションを更新
        func updatePOIAnnotations() {
            guard let mapView = mapView else { return }
            
            // 既存のPOIアノテーションを削除
            let oldPOIAnnotations = mapView.annotations.compactMap { $0 as? POIAnnotation }
            mapView.removeAnnotations(oldPOIAnnotations)
            
            // 新しいPOIアノテーションを追加
            let newAnnotations = parent.viewModel.searchResults.map { mapItem in
                let rating = parent.viewModel.calculateRating(for: mapItem.placemark.coordinate)
                return POIAnnotation(mapItem: mapItem, rating: rating)
            }
            
            mapView.addAnnotations(newAnnotations)
        }
        
        // MARK: - Annotation View Creation
        
        /// 駅のアノテーションビューを作成
        private func createStationAnnotationView(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView {
            let identifier = Constants.Identifiers.stationAnnotation
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            
            if view == nil {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            
            view?.annotation = annotation
            view?.pinTintColor = .red
            view?.canShowCallout = true
            view?.accessibilityLabel = Constants.Strings.shibuyaStation
            
            return view!
        }
        
        /// POIのアノテーションビューを作成
        private func createPOIAnnotationView(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView {
            let identifier = Constants.Identifiers.poiAnnotation
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            
            view?.annotation = annotation
            view?.glyphText = "🍴"
            view?.markerTintColor = .orange
            view?.canShowCallout = true
            
            // アクセシビリティの設定
            if let poi = annotation as? POIAnnotation {
                view?.accessibilityLabel = poi.mapItem.name ?? "観光地"
                view?.accessibilityValue = String(format: "評価 %.1f", poi.rating)
            }
            
            return view!
        }
    }
}

// MARK: - MKCoordinateRegion Extension
extension MKCoordinateRegion {
    /// 2つの地域が等しいかどうかを判定
    func isEqual(to other: MKCoordinateRegion, tolerance: Double = 0.0001) -> Bool {
        return abs(center.latitude - other.center.latitude) < tolerance &&
               abs(center.longitude - other.center.longitude) < tolerance &&
               abs(span.latitudeDelta - other.span.latitudeDelta) < tolerance &&
               abs(span.longitudeDelta - other.span.longitudeDelta) < tolerance
    }
} 