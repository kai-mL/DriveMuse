import SwiftUI
import MapKit

/// 場所の詳細情報を表示するビュー
struct PlaceDetailView: View {
    let mapItem: MKMapItem
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.UI.padding) {
            // 場所名
            placeName
            
            // 連絡先情報
            contactInfo
            
            // アクションボタン
            actionButtons
        }
        .padding(Constants.UI.padding)
        .background(.ultraThinMaterial)
        .cornerRadius(Constants.UI.cornerRadius)
        .padding(Constants.UI.padding)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("場所の詳細")
    }
    
    // MARK: - Subviews
    
    private var placeName: some View {
        Text(mapItem.name ?? "名前不明")
            .font(.headline)
            .fontWeight(.semibold)
            .accessibilityAddTraits(.isHeader)
    }
    
    @ViewBuilder
    private var contactInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let phone = mapItem.phoneNumber {
                contactRow(icon: "phone", text: "\(Constants.Strings.phone): \(phone)")
                    .onTapGesture {
                        callPhoneNumber(phone)
                    }
            }
            
            if let url = mapItem.url {
                contactRow(icon: "globe", text: url.absoluteString)
                    .lineLimit(1)
                    .onTapGesture {
                        openURL(url)
                    }
            }
            
            if let address = formatAddress() {
                contactRow(icon: "location", text: address)
            }
        }
    }
    
    private func contactRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
    
    private var actionButtons: some View {
        HStack {
            // 閉じるボタン
            Button(Constants.Strings.close) {
                onClose()
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("詳細を閉じる")
            
            Spacer()
            
            // 道案内ボタン
            Button("道案内") {
                openInMaps()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("マップアプリで道案内を開始")
        }
        .padding(.top)
    }
    
    // MARK: - Helper Methods
    
    /// 住所をフォーマット
    private func formatAddress() -> String? {
        let placemark = mapItem.placemark
        var addressComponents: [String] = []
        
        if let country = placemark.country {
            addressComponents.append(country)
        }
        if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
        }
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        if let thoroughfare = placemark.thoroughfare {
            addressComponents.append(thoroughfare)
        }
        
        return addressComponents.isEmpty ? nil : addressComponents.joined(separator: ", ")
    }
    
    /// 電話番号に発信
    private func callPhoneNumber(_ phoneNumber: String) {
        let cleanedNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel:\(cleanedNumber)") {
            UIApplication.shared.open(url)
        }
    }
    
    /// URLを開く
    private func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
    
    /// マップアプリで開く
    private func openInMaps() {
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
} 