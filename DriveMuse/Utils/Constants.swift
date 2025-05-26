import Foundation
import MapKit
import CoreLocation

struct Constants {
    
    // MARK: - Default Locations
    struct DefaultLocation {
        static let shibuya = CLLocationCoordinate2D(latitude: 35.6585, longitude: 139.7013)
        static let tokyo = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503) // 東京駅
        static let defaultRegion = MKCoordinateRegion(
            center: tokyo, // より観光地の多い東京駅周辺に変更
            latitudinalMeters: 2000, // 検索範囲を少し広げる
            longitudinalMeters: 2000
        )
    }
    
    // MARK: - Map Configuration
    struct Map {
        static let maxPOICount = 10
        static let distanceForRating: Double = 2000.0
        static let animationDuration: Double = 0.3
    }
    
    // MARK: - POI Categories
    struct POICategories {
        static let tourist: [MKPointOfInterestCategory] = [
            .amusementPark, .aquarium, .beach, .campground,
            .castle, .fairground, .fortress, .nationalMonument,
            .nationalPark, .planetarium, .spa, .zoo,
            .museum, .library, .movieTheater,
            .park, .stadium, .theater
        ]
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let detailViewHeight: CGFloat = 200
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
    }
    
    // MARK: - Identifiers
    struct Identifiers {
        static let stationAnnotation = "station"
        static let poiAnnotation = "poi"
        static let ratingPrefix = "評価:"
    }
    
    // MARK: - Localized Strings
    struct Strings {
        static let shibuyaStation = "渋谷駅"
        static let close = "閉じる"
        static let phone = "電話"
        static let rating = "評価"
        static let starSymbol = "⭐️"
        static let locationPermissionError = "位置情報の許可が必要です。設定アプリから許可してください。"
        static let searchError = "検索でエラーが発生しました"
        static let locationUnavailable = "現在地を取得できません。しばらく時間をおいて再度お試しください。"
    }
} 