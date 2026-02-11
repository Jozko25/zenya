//
//  SecureConfig.swift
//  anxiety
//
//  Secure configuration management for API keys
//  Loads keys from APIKeys.plist (never committed to git)
//

import Foundation

class SecureConfig {
    static let shared = SecureConfig()
    
    private var apiKeys: [String: Any] = [:]
    
    private init() {
        loadAPIKeys()
    }
    
    private func loadAPIKeys() {
        // Try to load from APIKeys.plist
        if let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            apiKeys = dict
            debugPrint("✅ API keys loaded from APIKeys.plist")
            return
        }
        
        // Fallback: Check environment variables (for CI/CD)
        if let weatherKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] {
            apiKeys["OpenWeather_API_Key"] = weatherKey
        }
        
        if let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            apiKeys["OpenAI_API_Key"] = openAIKey
        }
        
        if !apiKeys.isEmpty {
            debugPrint("✅ API keys loaded from environment variables")
            return
        }
        
        debugPrint("⚠️ No API keys configuration found. Using fallback modes.")
    }
    
    /// Get OpenWeather API key
    var openWeatherAPIKey: String? {
        guard let key = apiKeys["OpenWeather_API_Key"] as? String else { return nil }
        return key.isEmpty || key.contains("YOUR_") ? nil : key
    }
    
    /// Get OpenAI API key
    var openAIAPIKey: String? {
        guard let key = apiKeys["OpenAI_API_Key"] as? String else { return nil }
        return key.isEmpty || key.contains("YOUR_") ? nil : key
    }
    
    /// Get Supabase URL
    var supabaseURL: String? {
        guard let url = apiKeys["Supabase_URL"] as? String else { return nil }
        return url.isEmpty || url.contains("YOUR_") ? nil : url
    }
    
    /// Get Supabase Anon Key
    var supabaseAnonKey: String? {
        guard let key = apiKeys["Supabase_Anon_Key"] as? String else { return nil }
        return key.isEmpty || key.contains("YOUR_") ? nil : key
    }
    
    /// Check if weather API key is configured
    var hasOpenWeatherKey: Bool {
        return openWeatherAPIKey != nil
    }
    
    /// Check if OpenAI API key is configured
    var hasOpenAIKey: Bool {
        return openAIAPIKey != nil
    }
    
    /// Check if Supabase is configured
    var hasSupabaseConfig: Bool {
        return supabaseURL != nil && supabaseAnonKey != nil
    }
    
    /// Get any API key by key name
    func value(forKey key: String) -> String? {
        guard let value = apiKeys[key] as? String else { return nil }
        return value.isEmpty || value.contains("YOUR_") ? nil : value
    }
}
