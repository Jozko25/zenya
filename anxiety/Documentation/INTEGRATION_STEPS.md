# Security Integration Steps

## Quick Start Guide

### Step 1: Add New Files to Xcode Project

The following files need to be added to your Xcode project:

**Security Utilities:**
1. `anxiety/Utilities/KeychainManager.swift`
2. `anxiety/Utilities/SecureNetworkManager.swift`
3. `anxiety/Utilities/InputValidator.swift`
4. `anxiety/Utilities/SecureLogger.swift`
5. `anxiety/Utilities/SecurityManager.swift`

**How to add:**
1. Open Xcode
2. Right-click on `anxiety/Utilities` folder
3. Select "Add Files to 'anxiety'"
4. Select all 5 new files
5. Check "Copy items if needed"
6. Click "Add"

### Step 2: Update Certificate Pins ⚠️ CRITICAL

Open `anxiety/Utilities/SecureNetworkManager.swift` and find the `setupCertificatePinning()` function.

Run these commands in Terminal to get real certificate hashes:

```bash
# OpenAI
echo "OpenAI:" && openssl s_client -connect api.openai.com:443 -servername api.openai.com < /dev/null 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64

# OpenWeather
echo "OpenWeather:" && openssl s_client -connect api.openweathermap.org:443 -servername api.openweathermap.org < /dev/null 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64

# Supabase
echo "Supabase:" && openssl s_client -connect ejtdmxnaauqkhdgslwyi.supabase.co:443 -servername ejtdmxnaauqkhdgslwyi.supabase.co < /dev/null 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
```

Update the placeholder hashes with the real ones you got from the commands above.

### Step 3: Test Build

1. Build the project (⌘+B)
2. Fix any compilation errors:
   - Add `import Security` if needed
   - Add `import CommonCrypto` if needed

### Step 4: Update Edge Functions (Optional but Recommended)

If you use Supabase Edge Functions:

```bash
cd anxietyUITests/supabase
supabase functions deploy redeem-activation-code
supabase functions deploy generate-activation-code
```

### Step 5: Test Security Features

Run these tests to verify everything works:

#### Test 1: Keychain Storage
```swift
// Add this to a test or viewDidLoad temporarily
do {
    try KeychainManager.shared.save("test", forKey: "test_key")
    let value = try KeychainManager.shared.loadString(forKey: "test_key")
    print("✅ Keychain test passed: \(value)")
} catch {
    print("❌ Keychain test failed: \(error)")
}
```

#### Test 2: Input Validation
```swift
// Test validation
do {
    let validated = try InputValidator.shared.validateEmail("test@example.com")
    print("✅ Validation passed: \(validated)")
} catch {
    print("❌ Validation failed: \(error)")
}
```

#### Test 3: Secure Logging
```swift
// This should only appear in Debug builds
SecureLogger.shared.info("Testing secure logging")
secureLog("This is a test", level: .success)
```

#### Test 4: Security Checks
```swift
let result = SecurityManager.shared.performSecurityChecks()
print("Is Secure: \(result.isSecure)")
print("Warnings: \(result.warnings)")
```

### Step 6: Build for Release

1. Select "Any iOS Device" as target
2. Product → Archive
3. Verify debug logs don't appear in console

### Step 7: Clean Up (Optional)

Remove test code you added in Step 5.

---

## Common Issues & Solutions

### Issue: "Use of unresolved identifier 'SecureStorage'"

**Solution:** Make sure `KeychainManager.swift` is added to your target.

### Issue: "Cannot find 'CC_SHA256' in scope"

**Solution:** Add bridging header or import CommonCrypto:
```swift
import CommonCrypto
```

### Issue: Certificate pinning failing

**Solution:** 
1. Check you updated the hashes from placeholders
2. Verify you're using the correct hash format: `"sha256/BASE64HASH"`
3. For development, you can temporarily disable in DEBUG:
```swift
#if DEBUG
completionHandler(.performDefaultHandling, nil)
#else
// Certificate pinning code
#endif
```

### Issue: Rate limiting blocking legitimate requests

**Solution:** Adjust limits in `SecureNetworkManager.swift`:
```swift
private let maxRequestsPerMinute = 100  // Increase from 60
private let maxRequestsPer5Minutes = 300  // Increase from 200
```

---

## Migrating Existing Code

### Replace UserDefaults calls:

**Before:**
```swift
UserDefaults.standard.set(token, forKey: "auth_token")
let token = UserDefaults.standard.string(forKey: "auth_token")
```

**After:**
```swift
try? KeychainManager.shared.save(token, forKey: "auth_token")
let token = try? KeychainManager.shared.loadString(forKey: "auth_token")
```

**Or use SecureStorage:**
```swift
SecureStorage.shared.hasActiveSubscription = true
let isSubscribed = SecureStorage.shared.hasActiveSubscription
```

### Replace debugPrint:

**Before:**
```swift
debugPrint("User logged in: \(userName)")
```

**After:**
```swift
SecureLogger.shared.info("User logged in")
// or
secureLog("User logged in", level: .info)
```

### Replace URLSession calls:

**Before:**
```swift
let (data, _) = try await URLSession.shared.data(from: url)
```

**After:**
```swift
let request = URLRequest(url: url)
let (data, _) = try await SecureNetworkManager.shared
    .performRequest(request, rateLimitKey: "api-endpoint")
```

---

## Verification Checklist

Before releasing:

- [ ] All 5 security utility files added to Xcode project
- [ ] Certificate pins updated with real values (not placeholders)
- [ ] App builds without errors
- [ ] Keychain storage tested
- [ ] Input validation tested
- [ ] Secure logging works (debug-only)
- [ ] Security checks work on real device
- [ ] Edge functions deployed (if applicable)
- [ ] Release build doesn't show debug logs
- [ ] No "debugPrint" in production code

---

## Need Help?

1. Check `SECURITY_GUIDE.md` for detailed documentation
2. Check `SECURITY_FIXES_SUMMARY.md` for what was changed
3. Review the code in the security utility files - they're well commented

---

## Congratulations! 🎉

Your app now has enterprise-grade security!
