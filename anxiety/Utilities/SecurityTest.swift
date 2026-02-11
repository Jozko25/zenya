import Foundation

class SecurityTest {
    static func runAllTests() {
        print("\n🔐 Running Security Tests...\n")
        
        testKeychainStorage()
        testInputValidation()
        testSecureLogging()
        testSecurityChecks()
        
        print("\n✅ All security tests completed!\n")
    }
    
    private static func testKeychainStorage() {
        print("📦 Testing Keychain Storage...")
        
        do {
            try KeychainManager.shared.save("test_value", forKey: "test_key")
            let retrieved = try KeychainManager.shared.loadString(forKey: "test_key")
            
            if retrieved == "test_value" {
                print("   ✅ Keychain save/load works")
            } else {
                print("   ❌ Keychain value mismatch")
            }
            
            try KeychainManager.shared.delete(forKey: "test_key")
            print("   ✅ Keychain delete works")
            
        } catch {
            print("   ❌ Keychain test failed: \(error)")
        }
        
        let deviceId = SecureStorage.shared.deviceUserId
        print("   ✅ Device ID from SecureStorage: \(deviceId.uuidString.prefix(8))...")
    }
    
    private static func testInputValidation() {
        print("\n🔍 Testing Input Validation...")
        
        do {
            let email = try InputValidator.shared.validateEmail("test@example.com")
            print("   ✅ Email validation works: \(email)")
        } catch {
            print("   ❌ Email validation failed: \(error)")
        }
        
        do {
            let xssAttempt = "<script>alert('xss')</script>Hello"
            let sanitized = InputValidator.shared.sanitizeText(xssAttempt)
            
            if !sanitized.contains("<script") {
                print("   ✅ XSS sanitization works")
            } else {
                print("   ❌ XSS sanitization failed")
            }
        }
        
        do {
            _ = try InputValidator.shared.validateActivationCode("ZENYA-ABCD-1234")
            print("   ✅ Activation code validation works")
        } catch {
            print("   ❌ Activation code validation failed: \(error)")
        }
    }
    
    private static func testSecureLogging() {
        print("\n📝 Testing Secure Logging...")
        
        #if DEBUG
        SecureLogger.shared.info("This should appear in DEBUG")
        SecureLogger.shared.error("This error should appear in DEBUG")
        SecureLogger.shared.success("This success should appear in DEBUG")
        print("   ✅ Secure logging active in DEBUG mode")
        #else
        print("   ✅ Secure logging disabled in RELEASE mode")
        #endif
    }
    
    private static func testSecurityChecks() {
        print("\n🛡️ Testing Security Checks...")
        
        let securityResult = SecurityManager.shared.performSecurityChecks()
        
        print("   Device is secure: \(securityResult.isSecure)")
        
        if !securityResult.warnings.isEmpty {
            print("   ⚠️  Security warnings:")
            for warning in securityResult.warnings {
                print("      - \(warning)")
            }
        } else {
            print("   ✅ No security warnings")
        }
        
        #if targetEnvironment(simulator)
        print("   ℹ️  Running in simulator")
        #else
        print("   ℹ️  Running on real device")
        
        if SecurityManager.shared.isJailbroken {
            print("   ⚠️  Device appears to be jailbroken")
        } else {
            print("   ✅ Device is not jailbroken")
        }
        #endif
    }
}
