import Foundation
import MapKit

/// POI の詳細を保持するカスタムアノテーション
class POIAnnotation: MKPointAnnotation {
    let mapItem: MKMapItem
    let rating: Double
    
    init(mapItem: MKMapItem, rating: Double = 0.0) {
        self.mapItem = mapItem
        self.rating = rating
        super.init()
        self.coordinate = mapItem.placemark.coordinate
        self.title = mapItem.name
        self.subtitle = String(format: "\(Constants.Strings.rating): %.1f \(Constants.Strings.starSymbol)", rating)
    }
    
    /// 中心座標からの距離に基づいて評価を計算
    static func calculateRating(from center: CLLocationCoordinate2D, to coordinate: CLLocationCoordinate2D) -> Double {
        let distance = MKMapPoint(center).distance(to: MKMapPoint(coordinate))
        return max(1.0, 5.0 - distance / Constants.Map.distanceForRating)
    }
} 