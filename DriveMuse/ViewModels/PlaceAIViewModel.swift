import Foundation
import MapKit

/// 場所の詳細情報をAIで生成するViewModel
@MainActor
class PlaceAIViewModel: ObservableObject {
    @Published var aiDescription: String = ""
    @Published var isGeneratingDescription = false
    @Published var error: Error?
    
    private let geminiClient = GeminiAPIClient()
    private var currentTask: Task<Void, Never>?
    private var lastRequestTime: Date = .distantPast
    private let requestCooldown: TimeInterval = 2.0 // 2秒のクールダウン
    
    /// 場所の詳細説明をAIで生成
    func generatePlaceDescription(for mapItem: MKMapItem) {
        // リクエスト頻度制限
        let now = Date()
        if now.timeIntervalSince(lastRequestTime) < requestCooldown {
            return
        }
        lastRequestTime = now
        
        // 既存のタスクをキャンセル
        currentTask?.cancel()
        
        currentTask = Task {
            await performGenerateDescription(for: mapItem)
        }
    }
    
    /// 実際の説明生成処理
    private func performGenerateDescription(for mapItem: MKMapItem) async {
        guard !isGeneratingDescription else { return }
        
        // UI更新はメインスレッドで
        await MainActor.run {
            isGeneratingDescription = true
        }
        
        defer {
            Task { @MainActor in
                isGeneratingDescription = false
            }
        }
        
        do {
            let prompt = createPrompt(for: mapItem)
            
            // API呼び出しはバックグラウンドスレッドで実行
            let description = try await geminiClient.generateContent(prompt: prompt, temperature: 0.7)
            
            if !Task.isCancelled {
                // UI更新はメインスレッドで
                await MainActor.run {
                    aiDescription = description
                    error = nil
                }
            }
            
        } catch {
            if !Task.isCancelled {
                // エラー処理もメインスレッドで
                await MainActor.run {
                    self.error = error
                    aiDescription = ""
                }
            }
        }
    }
    
    /// プロンプトを作成
    private func createPrompt(for mapItem: MKMapItem) -> String {
        let placeName = mapItem.name ?? "不明な場所"
        let category = mapItem.pointOfInterestCategory?.rawValue ?? ""
        
        var locationInfo = "場所名: \(placeName)"
        
        if !category.isEmpty {
            locationInfo += "\nカテゴリ: \(category)"
        }
        
        if let address = formatAddress(mapItem.placemark) {
            locationInfo += "\n住所: \(address)"
        }
        
        return """
        あなたは観光ガイドAIです。以下の場所について、運転中のドライバー向けの非常に簡潔な説明を日本語で生成してください。

        \(locationInfo)

        条件：
        - 2行以内で完結させてください
        - 運転中でも読みやすい短い文章
        - この場所の最も重要な特徴を1つだけ
        - 専門用語は避けて、わかりやすく

        例: 「美しい庭園で有名な歴史ある神社。桜の季節は特に人気です。」
        """
    }
    
    /// 住所をフォーマット
    private func formatAddress(_ placemark: CLPlacemark) -> String? {
        var addressComponents: [String] = []
        
        if let country = placemark.country, country != "日本" {
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
    
    /// リソースのクリーンアップ
    func cleanup() {
        currentTask?.cancel()
    }
    
    /// 説明をクリア
    func clearDescription() {
        aiDescription = ""
        error = nil
        currentTask?.cancel()
    }
} 