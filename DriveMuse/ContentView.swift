import SwiftUI
import MapKit

/// メインのSwiftUIビュー
struct ContentView: View {
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        ZStack {
            // メインのマップビュー
            TouristMapView(viewModel: viewModel)
                .ignoresSafeArea()
            
            // 現在地ボタンと状態表示
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        currentLocationButton
                        if !viewModel.isLocationPermissionGranted {
                            locationPermissionPrompt
                        }
                    }
                }
                Spacer()
            }
            .padding()
            
            // 場所の詳細ビュー
            if let selectedMapItem = viewModel.selectedMapItem {
                VStack {
                    Spacer()
                    PlaceDetailView(mapItem: selectedMapItem) {
                        viewModel.selectMapItem(nil)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: Constants.Map.animationDuration), value: viewModel.selectedMapItem)
            }
            
            // エラー表示
            if let error = viewModel.error {
                VStack {
                    errorBanner(error)
                    Spacer()
                }
                .transition(.move(edge: .top))
                .animation(.easeInOut, value: viewModel.error != nil)
            }
            
            // ローディングインジケータ
            if viewModel.isSearching {
                VStack {
                    HStack {
                        Spacer()
                        loadingIndicator
                        Spacer()
                    }
                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeInOut, value: viewModel.isSearching)
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    // MARK: - Subviews
    
    /// 現在地ボタン
    private var currentLocationButton: some View {
        Button(action: {
            if viewModel.isLocationPermissionGranted {
                withAnimation {
                    viewModel.moveToCurrentLocation()
                }
            } else {
                // 設定アプリを開く
                openLocationSettings()
            }
        }) {
            Image(systemName: viewModel.isLocationPermissionGranted ? "location.fill" : "location.slash")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 44, height: 44)
                .background(viewModel.isLocationPermissionGranted ? Color.accentColor : Color.red)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .accessibilityLabel(viewModel.isLocationPermissionGranted ? "現在地に移動" : "位置情報を有効にする")
        .accessibilityHint(viewModel.isLocationPermissionGranted ? "現在の位置を地図の中心に表示します" : "設定アプリを開いて位置情報を有効にします")
    }
    
    /// 位置情報許可プロンプト
    private var locationPermissionPrompt: some View {
        Text("位置情報を\n許可してください")
            .font(.caption2)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.red.opacity(0.8))
            .cornerRadius(8)
    }
    
    /// 位置情報設定を開く
    private func openLocationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /// ローディングインジケータ
    private var loadingIndicator: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            
            Text("検索中...")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.top, 8)
    }
    
    /// エラーバナー
    private func errorBanner(_ error: Error) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Button("閉じる") {
                viewModel.error = nil
            }
            .font(.caption)
            .foregroundColor(.accentColor)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
