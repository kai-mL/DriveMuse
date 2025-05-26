import SwiftUI
import MapKit

/// 場所の詳細情報を表示するビュー
struct PlaceDetailView: View {
    let mapItem: MKMapItem
    let onClose: () -> Void
    
    @StateObject private var aiViewModel = PlaceAIViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 上部: 場所名と評価
            headerSection
            
            // 中央: AI説明（簡潔版）
            if !aiViewModel.aiDescription.isEmpty {
                compactAISection
            }
            
            // 下部: アクションボタン
            compactActionButtons
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(Constants.UI.cornerRadius)
        .padding(.horizontal, Constants.UI.padding)
        .frame(maxWidth: .infinity, maxHeight: 120) // 運転中でも見やすい高さに制限
        .accessibilityElement(children: .contain)
        .accessibilityLabel("場所の詳細")
        .onAppear {
            // 少し遅延させてからAI生成を開始（UI描画を優先）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                aiViewModel.generatePlaceDescription(for: mapItem)
            }
        }
        .onDisappear {
            aiViewModel.cleanup()
        }
    }
    
    // MARK: - Subviews
    
    /// ヘッダーセクション（運転中に見やすい）
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(mapItem.name ?? "名前不明")
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                
                // 簡潔なカテゴリ表示
                if let category = mapItem.pointOfInterestCategory {
                    Text(categoryDisplayName(category))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 評価表示（目立つように）
            ratingBadge
        }
    }
    
    /// 評価バッジ
    private var ratingBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .foregroundColor(.orange)
                .font(.caption)
            Text("4.2") // 仮の評価値
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.orange.opacity(0.2))
        .cornerRadius(8)
    }
    
    /// カテゴリ名を日本語表示用に変換
    private func categoryDisplayName(_ category: MKPointOfInterestCategory) -> String {
        switch category {
        case .amusementPark: return "テーマパーク"
        case .aquarium: return "水族館"
        case .beach: return "ビーチ"
        case .museum: return "博物館"
        case .park: return "公園"
        case .restaurant: return "レストラン"
        case .hotel: return "ホテル"
        case .gasStation: return "ガソリンスタンド"
        case .hospital: return "病院"
        case .theater: return "劇場"
        default: return "観光地"
        }
    }
    
    /// コンパクトなAI説明セクション（運転中に適した）
    private var compactAISection: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .foregroundColor(.purple)
                .font(.caption)
            
            if aiViewModel.isGeneratingDescription {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    .scaleEffect(0.6)
                Text("読み込み中...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text(aiViewModel.aiDescription)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(2) // 運転中は2行まで
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(6)
    }
    

    
    /// コンパクトなアクションボタン（運転中に操作しやすい）
    private var compactActionButtons: some View {
        HStack(spacing: 12) {
            // 閉じるボタン（小さく）
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(width: 28, height: 28)
            .background(Color.secondary.opacity(0.2))
            .clipShape(Circle())
            .accessibilityLabel("詳細を閉じる")
            
            Spacer()
            
            // 電話ボタン（利用可能な場合のみ）
            if mapItem.phoneNumber != nil {
                Button(action: { callPhoneNumber(mapItem.phoneNumber!) }) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 32)
                .background(Color.green)
                .cornerRadius(16)
                .accessibilityLabel("電話をかける")
            }
            
            // 道案内ボタン（メイン）
            Button(action: openInMaps) {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("案内")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
            }
            .frame(height: 32)
            .padding(.horizontal, 16)
            .background(Color.accentColor)
            .cornerRadius(16)
            .accessibilityLabel("マップアプリで道案内を開始")
        }
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