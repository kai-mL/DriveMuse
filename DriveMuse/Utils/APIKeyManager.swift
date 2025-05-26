import Foundation

/// APIキーを安全に管理するマネージャー
enum APIKeyManager {
    
    /// Gemini APIキーを取得
    static func getGeminiAPIKey() -> String? {
        // まずAPIKeys.plistから取得を試みる
        if let apiKey = loadAPIKeyFromPlist() {
            return apiKey
        }
        
        // フォールバック: Info.plistから取得
        if let apiKey = loadAPIKeyFromInfoPlist() {
            return apiKey
        }
        
        // 開発環境でのみフォールバック値を使用
        #if DEBUG
        print("⚠️ APIキーが見つかりません。APIKeys.plistファイルを確認してください。")
        return nil
        #else
        return nil
        #endif
    }
    
    /// APIKeys.plistからAPIキーを読み込み
    private static func loadAPIKeyFromPlist() -> String? {
        guard let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["GEMINI_API_KEY"] as? String,
              !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY_HERE" else {
            return nil
        }
        return apiKey
    }
    
    /// Info.plistからAPIキーを読み込み（代替手段）
    private static func loadAPIKeyFromInfoPlist() -> String? {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !apiKey.isEmpty else {
            return nil
        }
        return apiKey
    }
    
    /// APIキーが有効かどうかをチェック
    static func isAPIKeyValid(_ apiKey: String?) -> Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty && 
               key != "YOUR_GEMINI_API_KEY_HERE" &&
               key.hasPrefix("AIza") // Gemini APIキーの形式チェック
    }
} 