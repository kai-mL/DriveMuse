import SwiftUI  // SwiftUIフレームワークをインポート
import MapKit   // MapKitフレームワークをインポート

// UIKitのMKMapViewをSwiftUIで利用するラッパー
struct TouristMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion  // 地図の表示範囲をバインディング

    // Coordinatorを生成してDelegateを管理
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MKMapViewの生成と初期設定
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator              // Delegateを設定
        context.coordinator.mapView = mapView               // CoordinatorにmapViewを渡す

        // 地図の中心座標とズーム範囲を設定
        mapView.setRegion(region, animated: false)

        // 観光地のみを表示するPOIフィルタを設定 (iOS17+)
        let config = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .default)
        let touristCategories: [MKPointOfInterestCategory] = [
            .amusementPark, .aquarium, .beach, .campground,
            .castle, .fairground, .fortress, .nationalMonument,
            .nationalPark, .planetarium, .spa, .zoo
        ]
        config.pointOfInterestFilter = MKPointOfInterestFilter(including: touristCategories)
        mapView.preferredConfiguration = config              // フィルタを適用

        // 渋谷駅の固定ピンを追加
        let station = MKPointAnnotation()
        station.coordinate = CLLocationCoordinate2D(latitude: 35.6585, longitude: 139.7013)
        station.title = "渋谷駅"
        mapView.addAnnotation(station)

        // 初回の飲食店検索を実行
        context.coordinator.searchRestaurants()

        return mapView
    }

    // regionが変わったときに呼ばれる
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
    }

    // MKMapViewDelegateおよび検索ロジックを管理するCoordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TouristMapView
        weak var mapView: MKMapView?

        init(_ parent: TouristMapView) {
            self.parent = parent
        }

        // 地図移動完了時に飲食店検索を実行
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region     // SwiftUIの状態を更新
            searchRestaurants()
        }

        // 飲食店を検索してピンを追加
        func searchRestaurants() {
            guard let mapView = mapView else { return }

            // 既存の飲食店アノテーションを削除 (subtitleが「評価:」で始まるもの)
            let oldAnnotations = mapView.annotations.filter {
                $0.subtitle??.hasPrefix("評価:") ?? false
            }
            mapView.removeAnnotations(oldAnnotations)

            // MKLocalSearchで「レストラン」を検索
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "レストラン"
            request.region = mapView.region
            MKLocalSearch(request: request).start { response, error in
                guard let items = response?.mapItems else { return }

                // 中心から近い順に並べ、上位5件を表示
                let results = items.sorted {
                    let p1 = MKMapPoint($0.placemark.coordinate)
                    let p2 = MKMapPoint($1.placemark.coordinate)
                    let center = MKMapPoint(mapView.centerCoordinate)
                    return p1.distance(to: center) < p2.distance(to: center)
                }.prefix(5)

                for item in results {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = item.placemark.coordinate
                    annotation.title = item.name
                    // 評価軸: 中心からの距離で仮算出 (5段階)
                    let dist = MKMapPoint(mapView.centerCoordinate)
                        .distance(to: MKMapPoint(item.placemark.coordinate))
                    let rating = max(1.0, 5.0 - dist / 1000.0)
                    annotation.subtitle = String(format: "評価: %.1f ⭐️", rating)
                    mapView.addAnnotation(annotation)
                }
            }
        }

        // カスタムアノテーションビューを返す
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if annotation.title == "渋谷駅" {
                // 駅は赤いピン
                let id = "station"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKPinAnnotationView
                if view == nil {
                    view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
                    view?.pinTintColor = .red
                    view?.canShowCallout = true
                } else {
                    view?.annotation = annotation
                }
                return view
            } else {
                // 飲食店はオレンジ色のマーカーにフォークアイコン
                let id = "restaurant"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
                    view?.glyphText = "🍴"
                    view?.markerTintColor = .orange
                    view?.canShowCallout = true
                } else {
                    view?.annotation = annotation
                }
                return view
            }
        }
    }
}

// メインのSwiftUIビュー
struct ContentView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6585, longitude: 139.7013),
        latitudinalMeters: 1000, longitudinalMeters: 1000
    )

    var body: some View {
        TouristMapView(region: $region)  // 地図ビューを表示
            .ignoresSafeArea()           // フルスクリーン表示
            .task {
                // 位置情報の利用許可をリクエスト
                let manager = CLLocationManager()
                manager.requestWhenInUseAuthorization()
            }
    }
}
