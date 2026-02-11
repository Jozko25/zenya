//
//  SupabaseConfig.swift
//  anxiety
//
//  Simplified Supabase configuration for testing
//

import Foundation

struct SupabaseConfig {
    static var url: String {
        return SecureConfig.shared.supabaseURL ?? "https://ejtdmxnaauqkhdgslwyi.supabase.co"
    }
    
    static var anonKey: String {
        return SecureConfig.shared.supabaseAnonKey ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqdGRteG5hYXVxa2hkZ3Nsd3lpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3NTYxODcsImV4cCI6MjA3MjMzMjE4N30.qsRVW72OrGOXEo-a2jDn4XGkcW_axMC7l6kAMXTfNfA"
    }
}

// Simplified HTTP client for Supabase
class SupabaseHTTPClient {
    static let shared = SupabaseHTTPClient()
    
    private let baseURL: String
    private var baseHeaders: [String: String]
    private var authToken: String?
    
    private init() {
        baseURL = SupabaseConfig.url
        baseHeaders = [
            "apikey": SupabaseConfig.anonKey,
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        ]
    }
    
    func setAuthToken(_ token: String?) {
        authToken = token
        debugPrint("🔑 Auth token updated: \(token != nil ? "Set" : "Cleared")")
    }
    
    private var headers: [String: String] {
        var headers = baseHeaders
        headers["Authorization"] = "Bearer \(authToken ?? SupabaseConfig.anonKey)"
        return headers
    }
    
    func post(endpoint: String, data: Data) async throws -> Data {
        let fullEndpoint = endpoint.starts(with: "auth/") ? endpoint : "rest/v1/\(endpoint)"
        guard let url = URL(string: "\(baseURL)/\(fullEndpoint)") else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        debugPrint("📤 POST to: \(fullEndpoint)")
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode >= 400 {
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                // Don't log expected errors (missing tables, duplicates, foreign keys)
                if !errorMessage.contains("PGRST205") && !errorMessage.contains("23505") && !errorMessage.contains("23503") {
                    debugPrint("❌ HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
                throw NSError(domain: "SupabaseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            
            return responseData
        }
        
        return responseData
    }
    
    // Add OAuth-specific method for Google Sign-In
    func signInWithOAuth(provider: String, idToken: String) async throws -> AuthResponse {
        let requestBody: [String: Any] = [
            "provider": provider,
            "id_token": idToken
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        let responseData = try await post(endpoint: "auth/v1/token?grant_type=id_token", data: jsonData)
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: responseData)
        return authResponse
    }
    
    func get(endpoint: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/rest/v1/\(endpoint)") else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        debugPrint("📤 GET from: \(endpoint)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode >= 400 {
                // Silently handle expected errors
                if let responseString = String(data: data, encoding: .utf8),
                   !responseString.contains("PGRST205") && !responseString.contains("23503") {
                    debugPrint("❌ GET \(httpResponse.statusCode)")
                }
            }
        }
        
        return data
    }
    
    func post(endpoint: String, body: [String: Any]) async throws -> Data {
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        return try await post(endpoint: endpoint, data: jsonData)
    }
    
    func delete(endpoint: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/rest/v1/\(endpoint)") else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        debugPrint("📤 DELETE from: \(endpoint)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
            
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode >= 400 {
                debugPrint("❌ DELETE Response Error: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    debugPrint("Error details: \(responseString)")
                }
            }
        }
        
        return data
    }
    
    func patch(endpoint: String, body: [String: Any]) async throws -> Data {
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = jsonData
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        debugPrint("📤 PATCH to: \(endpoint)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode >= 400 {
                debugPrint("❌ PATCH Response Error: \(httpResponse.statusCode)")
                let responseString = String(data: data, encoding: .utf8)
                if let responseString = responseString {
                    debugPrint("Error details: \(responseString)")
                }
                throw NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseString ?? "Unknown error"])
            }
        }
        
        return data
    }
}

// MARK: - Auth Response Models
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let user: AuthUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }
}

struct AuthUser: Codable {
    let id: String
    let email: String?
    let emailConfirmed: String?
    let phone: String?
    let confirmedAt: String?
    let lastSignInAt: String?
    let createdAt: String
    let updatedAt: String
    let identities: [AuthIdentity]?
    let userMetadata: [String: AnyCodable]?
    let appMetadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id, email, phone, identities
        case emailConfirmed = "email_confirmed_at"
        case confirmedAt = "confirmed_at"
        case lastSignInAt = "last_sign_in_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userMetadata = "user_metadata"
        case appMetadata = "app_metadata"
    }
}

struct AuthIdentity: Codable {
    let id: String
    let userId: String
    let provider: String
    let identityData: [String: AnyCodable]?
    let createdAt: String
    let lastSignInAt: String?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, provider
        case userId = "user_id"
        case identityData = "identity_data"
        case createdAt = "created_at"
        case lastSignInAt = "last_sign_in_at"
        case updatedAt = "updated_at"
    }
}

// Helper for dynamic JSON values
struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal.map { $0.value }
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal.mapValues { $0.value }
        } else {
            value = ()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let stringVal as String:
            try container.encode(stringVal)
        default:
            try container.encodeNil()
        }
    }
}
