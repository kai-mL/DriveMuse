
import SwiftUI
import MapKit

struct ContentView: View {
    
    @State private var region = MKCoordinateRegion(
            //Mapの中心の緯度経度
            center: CLLocationCoordinate2D(latitude: 35.6585,
                                           longitude: 139.7013),
            //緯度の表示領域(m)
            latitudinalMeters: 750,
            //経度の表示領域(m)
            longitudinalMeters: 750
    )
    var body: some View {
        Map(coordinateRegion: $region,
            //Mapの操作の指定
            interactionModes: .pan,
            //現在地の表示
            showsUserLocation: true,
            //現在地の追従
            userTrackingMode: .constant(MapUserTrackingMode.follow)
        )
        .task(){
            //位置情報へのアクセスを要求
            let manager = CLLocationManager()
            manager.requestWhenInUseAuthorization()
        }
    }
}
