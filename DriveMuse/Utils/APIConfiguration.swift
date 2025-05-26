import Foundation

/// API設定を管理するクラス
struct APIConfiguration {
    
    // MARK: - Gemini API Configuration
    struct Gemini {
        static let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"
        
        /// APIキーを安全に取得
        static func getAPIKey() -> String? {
            return APIKeyManager.getGeminiAPIKey()
        }
        
        /// APIキーが設定されているかチェック
        static func isAPIKeyConfigured() -> Bool {
            return APIKeyManager.isAPIKeyValid(getAPIKey())
        }
        
        /// Content-Typeヘッダー
        static let contentType = "application/json"
        
        /// APIリクエストのタイムアウト時間
        static let timeoutInterval: TimeInterval = 30.0
    }
    
    // MARK: - Request Models
    struct GeminiRequest: Codable {
        let contents: [Content]
        let generationConfig: GenerationConfig?
        
        struct Content: Codable {
            let parts: [Part]
            
            struct Part: Codable {
                let text: String
            }
        }
        
        struct GenerationConfig: Codable {
            let temperature: Double?
            let topK: Int?
            let topP: Double?
            let maxOutputTokens: Int?
            let stopSequences: [String]?
        }
    }
    
    // MARK: - Response Models
    struct GeminiResponse: Codable {
        let candidates: [Candidate]?
        let promptFeedback: PromptFeedback?
        
        struct Candidate: Codable {
            let content: Content
            let finishReason: String?
            let index: Int?
            let safetyRatings: [SafetyRating]?
            
            struct Content: Codable {
                let parts: [Part]
                
                struct Part: Codable {
                    let text: String
                }
            }
        }
        
        struct PromptFeedback: Codable {
            let safetyRatings: [SafetyRating]?
        }
        
        struct SafetyRating: Codable {
            let category: String
            let probability: String
        }
    }
} 