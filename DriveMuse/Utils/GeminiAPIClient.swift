import Foundation

/// Gemini APIとの通信を管理するクライアント
class GeminiAPIClient {
    private let session: URLSession
    
    init() {
        // バックグラウンド用のセッション設定
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfiguration.Gemini.timeoutInterval
        config.timeoutIntervalForResource = APIConfiguration.Gemini.timeoutInterval * 2
        self.session = URLSession(configuration: config)
    }
    
    /// Gemini APIに質問を送信して回答を取得
    func generateContent(prompt: String, temperature: Double = 0.7) async throws -> String {
        guard !prompt.isEmpty else {
            throw GeminiError.invalidPrompt
        }
        
        let url = try createURL()
        let request = try createRequest(url: url, prompt: prompt, temperature: temperature)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // HTTPレスポンスをチェック
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw GeminiError.httpError(httpResponse.statusCode)
            }
            
            // レスポンスをパース
            let geminiResponse = try JSONDecoder().decode(APIConfiguration.GeminiResponse.self, from: data)
            
            guard let candidate = geminiResponse.candidates?.first,
                  let part = candidate.content.parts.first else {
                throw GeminiError.noContent
            }
            
            return part.text
            
        } catch let error as GeminiError {
            throw error
        } catch {
            throw GeminiError.networkError(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// URLを作成
    private func createURL() throws -> URL {
        guard let apiKey = APIConfiguration.Gemini.getAPIKey(),
              APIConfiguration.Gemini.isAPIKeyConfigured() else {
            throw GeminiError.apiKeyNotConfigured
        }
        
        var components = URLComponents(string: APIConfiguration.Gemini.baseURL)
        components?.queryItems = [
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw GeminiError.invalidURL
        }
        
        return url
    }
    
    /// リクエストを作成
    private func createRequest(url: URL, prompt: String, temperature: Double) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfiguration.Gemini.contentType, forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = APIConfiguration.Gemini.timeoutInterval
        
        let requestBody = APIConfiguration.GeminiRequest(
            contents: [
                APIConfiguration.GeminiRequest.Content(
                    parts: [
                        APIConfiguration.GeminiRequest.Content.Part(text: prompt)
                    ]
                )
            ],
            generationConfig: APIConfiguration.GeminiRequest.GenerationConfig(
                temperature: temperature,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 1024,
                stopSequences: nil
            )
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw GeminiError.encodingError(error)
        }
        
        return request
    }
}

// MARK: - Error Types
enum GeminiError: LocalizedError {
    case invalidPrompt
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noContent
    case networkError(Error)
    case encodingError(Error)
    case apiKeyNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .invalidPrompt:
            return "プロンプトが無効です"
        case .invalidURL:
            return "APIのURLが無効です"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .httpError(let code):
            return "HTTP エラー: \(code)"
        case .noContent:
            return "AIからの応答がありません"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .encodingError(let error):
            return "データエンコードエラー: \(error.localizedDescription)"
        case .apiKeyNotConfigured:
            return "APIキーが設定されていません。APIKeys.plistファイルを確認してください。"
        }
    }
} 