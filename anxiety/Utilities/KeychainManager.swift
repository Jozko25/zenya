import Foundation
import Security

enum KeychainError: Error {
    case duplicateItem
    case itemNotFound
    case invalidData
    case unexpectedStatus(OSStatus)
}

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.anxiety.zenya"
    
    private init() {}
    
    func save(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try update(data, forKey: key)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func save(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(data, forKey: key)
    }
    
    func save<T: Codable>(_ object: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try save(data, forKey: key)
    }
    
    func load(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    func loadString(forKey key: String) throws -> String {
        let data = try load(forKey: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }
    
    func load<T: Codable>(forKey key: String, as type: T.Type) throws -> T {
        let data = try load(forKey: key)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
    
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func exists(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func update(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

class SecureStorage {
    static let shared = SecureStorage()
    private let keychain = KeychainManager.shared
    
    private init() {
        migrateFromUserDefaults()
    }
    
    var deviceUserId: UUID {
        get {
            if let storedId = try? keychain.loadString(forKey: "device_user_id"),
               let uuid = UUID(uuidString: storedId) {
                return uuid
            }
            
            let newId = UUID()
            try? keychain.save(newId.uuidString, forKey: "device_user_id")
            #if DEBUG
            debugPrint("📱 Generated new device UUID: \(newId)")
            #endif
            return newId
        }
    }
    
    var hasActiveSubscription: Bool {
        get {
            (try? keychain.loadString(forKey: "has_active_subscription")) == "true"
        }
        set {
            try? keychain.save(newValue ? "true" : "false", forKey: "has_active_subscription")
        }
    }
    
    var subscriptionPlan: String? {
        get {
            try? keychain.loadString(forKey: "subscription_plan")
        }
        set {
            if let value = newValue {
                try? keychain.save(value, forKey: "subscription_plan")
            } else {
                try? keychain.delete(forKey: "subscription_plan")
            }
        }
    }
    
    var subscriptionExpiresAt: String? {
        get {
            try? keychain.loadString(forKey: "subscription_expires_at")
        }
        set {
            if let value = newValue {
                try? keychain.save(value, forKey: "subscription_expires_at")
            } else {
                try? keychain.delete(forKey: "subscription_expires_at")
            }
        }
    }
    
    var userName: String? {
        get {
            try? keychain.loadString(forKey: "user_name")
        }
        set {
            if let value = newValue {
                try? keychain.save(value, forKey: "user_name")
            } else {
                try? keychain.delete(forKey: "user_name")
            }
        }
    }
    
    var hasCompletedOnboarding: Bool {
        get {
            (try? keychain.loadString(forKey: "has_completed_onboarding")) == "true"
        }
        set {
            try? keychain.save(newValue ? "true" : "false", forKey: "has_completed_onboarding")
        }
    }
    
    private func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard
        
        if let deviceId = defaults.string(forKey: "device_user_id"),
           !keychain.exists(forKey: "device_user_id") {
            try? keychain.save(deviceId, forKey: "device_user_id")
            defaults.removeObject(forKey: "device_user_id")
        }
        
        if defaults.object(forKey: "has_active_subscription") != nil,
           !keychain.exists(forKey: "has_active_subscription") {
            let value = defaults.bool(forKey: "has_active_subscription")
            try? keychain.save(value ? "true" : "false", forKey: "has_active_subscription")
            defaults.removeObject(forKey: "has_active_subscription")
        }
        
        if let userName = defaults.string(forKey: "user_name"),
           !keychain.exists(forKey: "user_name") {
            try? keychain.save(userName, forKey: "user_name")
            defaults.removeObject(forKey: "user_name")
        }
        
        if defaults.object(forKey: "has_completed_onboarding") != nil,
           !keychain.exists(forKey: "has_completed_onboarding") {
            let value = defaults.bool(forKey: "has_completed_onboarding")
            try? keychain.save(value ? "true" : "false", forKey: "has_completed_onboarding")
            defaults.removeObject(forKey: "has_completed_onboarding")
        }
    }
    
    func clearAllSecureData() {
        try? keychain.clearAll()
    }
}
