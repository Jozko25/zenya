# Security Implementation Guide

## Overview
This document outlines the security measures implemented in the Anxiety/Zenya app to protect user data and prevent unauthorized access.

## ✅ Implemented Security Features

### 1. Secure Credential Storage (iOS Keychain)

**Location:** `anxiety/Utilities/KeychainManager.swift`

All sensitive data is now stored in the iOS Keychain instead of UserDefaults:
- Device User ID
- Subscription status
- User authentication tokens
- Personal user information

**Usage:**
```swift
// Store sensitive data
SecureStorage.shared.hasActiveSubscription = true
SecureStorage.shared.userName = "John Doe"

// Retrieve sensitive data
let userId = SecureStorage.shared.deviceUserId
let isSubscribed = SecureStorage.shared.hasActiveSubscription
```

**Migration:**
The `SecureStorage` class automatically migrates existing data from UserDefaults to Keychain on first launch.

---

### 2. Certificate Pinning

**Location:** `anxiety/Utilities/SecureNetworkManager.swift`

Certificate pinning is implemented for all external API calls to prevent MITM attacks:
- OpenAI API
- OpenWeather API
- Supabase backend

**How it works:**
The app validates SSL certificates against known certificate hashes before allowing connections.

**To update certificate pins:**
```swift
// In SecureNetworkManager.swift
pinnedHosts["api.openai.com"] = [
    "sha256/YOUR_CERTIFICATE_HASH_HERE"
]
```

**Getting certificate hash:**
```bash
openssl s_client -connect api.openai.com:443 -servername api.openai.com < /dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
```

---

### 3. Input Validation & Sanitization

**Location:** `anxiety/Utilities/InputValidator.swift`

All user input is validated and sanitized before processing:

**Supported validations:**
- Journal entries (max 50,000 chars, XSS prevention)
- User names (max 100 chars)
- Activation codes (format validation)
- Email addresses (RFC compliant)
- URLs (HTTPS only)
- Mood values (0-10 range)
- Anxiety levels (1-10 range)

**Usage:**
```swift
let validator = InputValidator.shared

// Validate journal entry
let sanitizedEntry = try validator.validateJournalEntry(userInput)

// Validate activation code
let cleanCode = try validator.validateActivationCode(code)

// Validate email
let validEmail = try validator.validateEmail(email)
```

---

### 4. Rate Limiting

**Location:** `anxiety/Utilities/SecureNetworkManager.swift` (RateLimiter class)

Client-side rate limiting prevents API abuse:
- Max 60 requests per minute per endpoint
- Max 200 requests per 5 minutes per endpoint

**How it works:**
Automatically enforced when using `SecureNetworkManager.shared.performRequest()`

---

### 5. Secure API Configuration

**Changes made:**
- Removed hardcoded Supabase credentials from `SupabaseConfig.swift`
- All API keys now loaded from `SecureConfig.swift` → `APIKeys.plist`
- Fallback values only used in development

**Important:** 
Never commit `APIKeys.plist` to version control. It's properly ignored in `.gitignore`.

---

### 6. CORS Security (Edge Functions)

**Location:** 
- `anxietyUITests/supabase/functions/redeem-activation-code/index.ts`
- `anxietyUITests/supabase/functions/generate-activation-code/index.ts`

**Changes:**
- Removed wildcard `*` CORS
- Only allowed origins: `zenya-web.vercel.app`, `zenya.app`
- Added proper CORS preflight handling

---

### 7. Cryptographically Secure Random Generation

**Location:** `anxietyUITests/supabase/functions/generate-activation-code/index.ts`

Activation codes now use `crypto.getRandomValues()` instead of `Math.random()`:

```typescript
// Before (INSECURE)
const randomIndex = Math.floor(Math.random() * chars.length);

// After (SECURE)
const randomBytes = new Uint8Array(1);
crypto.getRandomValues(randomBytes);
const randomIndex = randomBytes[0] % chars.length;
```

---

### 8. Secure Logging

**Location:** `anxiety/Utilities/SecureLogger.swift`

All debug logging is wrapped in `#if DEBUG` checks:

```swift
// Usage
SecureLogger.shared.info("User logged in")
SecureLogger.shared.error("API call failed")

// Or use shorthand
secureLog("Database updated", level: .success)
```

**Production builds:** All debug logs are automatically stripped out.

---

### 9. Jailbreak Detection

**Location:** `anxiety/Utilities/SecurityManager.swift`

The app detects jailbroken devices and can restrict premium features:

**Checks performed:**
- Jailbreak files/apps (Cydia, etc.)
- System file write permissions
- Suspicious dynamic libraries
- Debugger attachment

**Usage:**
```swift
let securityResult = SecurityManager.shared.performSecurityChecks()
if !securityResult.isSecure {
    print("Warnings: \(securityResult.warnings)")
}

// Check before allowing premium features
if SecurityManager.shared.shouldAllowPremiumFeatures() {
    // Allow access
}
```

---

## 🔒 API Key Security

### Storage Location
API keys are stored in: `anxiety/Config/APIKeys.plist`

### Template File
A template is provided at: `anxiety/Config/APIKeys.plist.template`

### Setup Instructions
1. Copy `APIKeys.plist.template` to `APIKeys.plist`
2. Replace placeholder values with real API keys
3. Never commit `APIKeys.plist` to git (already in `.gitignore`)

### Supported Keys
- `OpenAI_API_Key` - OpenAI GPT API
- `OpenWeather_API_Key` - Weather data API
- `Supabase_URL` - Supabase project URL
- `Supabase_Anon_Key` - Supabase anonymous key

---

## 🛡️ Best Practices

### For Developers

1. **Never log sensitive data**
   ```swift
   // ❌ BAD
   print("User token: \(token)")
   
   // ✅ GOOD
   secureLog("User authenticated successfully")
   ```

2. **Always validate input**
   ```swift
   // ❌ BAD
   let entry = SupabaseJournalEntry(content: userInput, ...)
   
   // ✅ GOOD
   let sanitized = try InputValidator.shared.validateJournalEntry(userInput)
   let entry = SupabaseJournalEntry(content: sanitized, ...)
   ```

3. **Use SecureStorage for sensitive data**
   ```swift
   // ❌ BAD
   UserDefaults.standard.set(token, forKey: "auth_token")
   
   // ✅ GOOD
   try KeychainManager.shared.save(token, forKey: "auth_token")
   ```

4. **Use SecureNetworkManager for API calls**
   ```swift
   // ❌ BAD
   let (data, _) = try await URLSession.shared.data(from: url)
   
   // ✅ GOOD
   let (data, _) = try await SecureNetworkManager.shared
       .performRequest(request, rateLimitKey: "openai")
   ```

### For Production Deployment

1. ✅ Ensure `APIKeys.plist` is not in repository
2. ✅ Verify certificate pins are up to date
3. ✅ Test jailbreak detection on real devices
4. ✅ Confirm all debug logs are stripped in release builds
5. ✅ Run security audit before each release
6. ✅ Rotate API keys if exposed
7. ✅ Monitor API usage for abuse

---

## 📊 Security Checklist

Before each release, verify:

- [ ] No API keys in source code
- [ ] Certificate pins updated (if APIs changed)
- [ ] All user input validated
- [ ] Sensitive data in Keychain, not UserDefaults
- [ ] CORS properly configured on edge functions
- [ ] Rate limiting functional
- [ ] Jailbreak detection working
- [ ] Debug logs stripped from production
- [ ] HTTPS enforced everywhere
- [ ] App Transport Security enabled

---

## 🚨 Incident Response

If API keys are compromised:

1. **Immediately rotate all API keys:**
   - OpenAI API: https://platform.openai.com/api-keys
   - OpenWeather: https://home.openweathermap.org/api_keys
   - Supabase: Project Settings → API

2. **Update `APIKeys.plist` on all development machines**

3. **Update certificate pins if needed:**
   ```swift
   // Update in SecureNetworkManager.swift
   pinnedHosts["api.openai.com"] = ["sha256/NEW_HASH"]
   ```

4. **Force app update if keys were in released build**

5. **Monitor API usage for 48 hours**

---

## 📝 Maintenance

### Weekly
- Review API usage logs
- Check for unusual activity

### Monthly
- Audit new code for security issues
- Update dependencies
- Review certificate expiration dates

### Quarterly
- Perform full security audit
- Update certificate pins
- Review and update CORS policies
- Test jailbreak detection on latest iOS

---

## 🆘 Support

For security concerns, contact the development team immediately.

**Do not post security issues publicly on GitHub or other platforms.**

---

## Version History

- **v1.0** - Initial security implementation (Oct 2025)
  - Added Keychain storage
  - Implemented certificate pinning
  - Added input validation
  - Configured rate limiting
  - Implemented jailbreak detection
