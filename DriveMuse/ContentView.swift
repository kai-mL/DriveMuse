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
            
            // 現在地ボタン
            VStack {
                HStack {
                    Spacer()
                    currentLocationButton
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
            withAnimation {
                viewModel.moveToCurrentLocation()
            }
        }) {
            Image(systemName: "location.fill")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 44, height: 44)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .accessibilityLabel("現在地に移動")
        .accessibilityHint("現在の位置を地図の中心に表示します")
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
