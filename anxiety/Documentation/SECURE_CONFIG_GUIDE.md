# Secure Configuration Guide 🔐

## Why This Approach?

**Problem with hardcoding API keys:**
- ❌ Keys are visible in source code
- ❌ Keys get committed to git
- ❌ Keys are exposed in git history forever
- ❌ Anyone with repo access sees your keys
- ❌ Hard to rotate keys without code changes

**Our secure solution:**
- ✅ Keys stored in separate file (Secrets.plist)
- ✅ Secrets.plist is in .gitignore (never committed)
- ✅ Template file shows structure without secrets
- ✅ Easy key rotation (just edit the plist)
- ✅ Different keys per environment (dev/staging/prod)
- ✅ CI/CD support via environment variables

## Setup Instructions (5 minutes)

### Step 1: Create Secrets.plist

```bash
cd anxiety/Config
cp Secrets.plist.template Secrets.plist
```

Or manually:
1. Go to `anxiety/Config/` folder
2. Duplicate `Secrets.plist.template`
3. Rename to `Secrets.plist`

### Step 2: Add Your API Key

Open `Secrets.plist` and replace:

```xml
<key>OPENWEATHER_API_KEY</key>
<string>YOUR_API_KEY_HERE</string>
```

With your actual key:

```xml
<key>OPENWEATHER_API_KEY</key>
<string>abc123def456ghi789jkl012mno345pq</string>
```

### Step 3: Verify .gitignore

Check that `Secrets.plist` is in `.gitignore`:

```bash
cat .gitignore | grep Secrets
```

Should see:
```
anxiety/Config/Secrets.plist
```

✅ Done! Your API key is now secure.

## How It Works

### File Structure

```
anxiety/Config/
├── Secrets.plist.template    ← Committed to git ✅
├── Secrets.plist              ← NOT committed (in .gitignore) 🔒
├── SecureConfig.swift         ← Committed to git ✅
└── WeatherConfig.swift        ← Committed to git ✅
```

### Loading Order

```
SecureConfig tries to load in this order:

1. Secrets.plist (primary method)
   ↓ if not found
2. Environment variable: OPENWEATHER_API_KEY
   ↓ if not found
3. Info.plist: OpenWeatherAPIKey
   ↓ if not found
4. Fallback mode (simulated weather)
```

### Code Flow

```swift
// OpenWeatherService requests API key
apiKey = SecureConfig.shared.openWeatherAPIKey

// SecureConfig loads from Secrets.plist
SecureConfig.shared.loadSecrets()

// Returns key or nil (triggers fallback)
return secrets["OPENWEATHER_API_KEY"] as? String
```

## Multiple Environments

### Development, Staging, Production

Create different secret files:

```
anxiety/Config/
├── Secrets.plist              ← Development (your local key)
├── Secrets.plist.staging      ← Staging environment
└── Secrets.plist.production   ← Production environment
```

Add to `.gitignore`:
```
anxiety/Config/Secrets.plist*
```

### Xcode Schemes

Configure different schemes to use different files:

1. **Product → Scheme → Edit Scheme**
2. **Build → Pre-actions**
3. Add script:

```bash
# Development
cp "${PROJECT_DIR}/anxiety/Config/Secrets.plist" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Secrets.plist"

# Staging
# cp "${PROJECT_DIR}/anxiety/Config/Secrets.plist.staging" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Secrets.plist"

# Production
# cp "${PROJECT_DIR}/anxiety/Config/Secrets.plist.production" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Secrets.plist"
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Build

on: [push]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Create Secrets.plist
        run: |
          cat > anxiety/Config/Secrets.plist << EOF
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
              <key>OPENWEATHER_API_KEY</key>
              <string>${{ secrets.OPENWEATHER_API_KEY }}</string>
          </dict>
          </plist>
          EOF
      
      - name: Build
        run: xcodebuild -scheme zenya build
```

### Environment Variables (Alternative)

Set environment variable in CI/CD:

```bash
export OPENWEATHER_API_KEY="your_key_here"
```

SecureConfig automatically falls back to environment variables.

### Fastlane

```ruby
lane :build do
  # Create Secrets.plist from environment
  secrets_path = "anxiety/Config/Secrets.plist"
  secrets_content = <<-PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>OPENWEATHER_API_KEY</key>
    <string>#{ENV['OPENWEATHER_API_KEY']}</string>
</dict>
</plist>
  PLIST
  
  File.write(secrets_path, secrets_content)
  
  # Build
  build_app(scheme: "zenya")
end
```

## Team Setup

### For New Team Members

1. Clone the repo
2. Create `Secrets.plist` from template:
   ```bash
   cd anxiety/Config
   cp Secrets.plist.template Secrets.plist
   ```
3. Get API key from team lead
4. Add key to their local `Secrets.plist`
5. Never commit `Secrets.plist`

### Sharing Keys Securely

**DON'T:**
- ❌ Email API keys
- ❌ Slack/Discord keys
- ❌ Commit to git
- ❌ Share in screenshots

**DO:**
- ✅ Use password manager (1Password, LastPass)
- ✅ Use secret management tool (Vault, AWS Secrets Manager)
- ✅ In-person or encrypted channel
- ✅ Each developer gets their own key

## Key Rotation

### When to Rotate

- Key is compromised
- Team member leaves
- Suspicious API usage
- Regular security practice (quarterly)

### How to Rotate

1. Generate new key on OpenWeather
2. Update `Secrets.plist`:
   ```xml
   <string>new_key_here</string>
   ```
3. Test locally
4. Update CI/CD secrets
5. Delete old key on OpenWeather
6. Notify team to update their local `Secrets.plist`

### Zero Downtime Rotation

1. Generate new key (Key B)
2. Keep old key (Key A) active
3. Deploy app with Key B
4. Wait 24 hours
5. Delete Key A

## Security Best Practices

### ✅ DO

- Keep Secrets.plist in .gitignore
- Use different keys per environment
- Rotate keys regularly
- Monitor API usage for anomalies
- Use environment variables in CI/CD
- Limit API key permissions (if available)
- Set up billing alerts

### ❌ DON'T

- Commit Secrets.plist to git
- Hardcode keys in source code
- Share keys in plain text
- Use production keys in development
- Screenshot code with visible keys
- Log API keys
- Include keys in error messages

## Troubleshooting

### "No secrets configuration found" Error

**Check 1:** Does `Secrets.plist` exist?
```bash
ls anxiety/Config/Secrets.plist
```

**Check 2:** Is it in the Xcode project?
- Open Xcode
- Check Project Navigator
- anxiety/Config/ should have Secrets.plist

**Check 3:** Is the key correct?
```bash
cat anxiety/Config/Secrets.plist
```

**Check 4:** Rebuild the app
- Product → Clean Build Folder
- Product → Build

### API Key Still Not Working

**Verify SecureConfig is loading:**
```swift
// Add to AppDelegate or ContentView
print("Has key: \(SecureConfig.shared.hasOpenWeatherKey)")
print("Key prefix: \(SecureConfig.shared.openWeatherAPIKey?.prefix(8) ?? "nil")")
```

Should see:
```
Has key: true
Key prefix: abc12345
```

### Git Shows Secrets.plist as Untracked

This is normal! It should be untracked (not committed).

To hide it from git status:
```bash
git update-index --assume-unchanged anxiety/Config/Secrets.plist
```

## Advanced: Multiple Secrets

Add more secrets to `Secrets.plist`:

```xml
<dict>
    <key>OPENWEATHER_API_KEY</key>
    <string>weather_key_here</string>
    
    <key>SUPABASE_URL</key>
    <string>https://project.supabase.co</string>
    
    <key>SUPABASE_ANON_KEY</key>
    <string>supabase_key_here</string>
    
    <key>ANALYTICS_KEY</key>
    <string>analytics_key_here</string>
</dict>
```

Access in code:
```swift
let supabaseURL = SecureConfig.shared.value(forKey: "SUPABASE_URL")
```

## Comparison: Before vs After

### Before (Insecure) ❌

```swift
// WeatherConfig.swift (committed to git)
struct WeatherConfig {
    static let apiKey = "abc123def456..."  // 🚨 EXPOSED!
}
```

Problems:
- Visible in source code
- In git history forever
- Anyone with repo access sees it
- Can't rotate without code change

### After (Secure) ✅

```swift
// SecureConfig.swift (committed to git)
class SecureConfig {
    var openWeatherAPIKey: String? {
        return secrets["OPENWEATHER_API_KEY"] as? String
    }
}

// Secrets.plist (NOT in git)
<key>OPENWEATHER_API_KEY</key>
<string>abc123def456...</string>
```

Benefits:
- Not visible in source code
- Not in git (in .gitignore)
- Easy to rotate (just edit plist)
- Different keys per environment
- Team members use their own keys

## Migration from Hardcoded Keys

If you previously hardcoded keys:

### Step 1: Remove from Source
```swift
// OLD - DELETE THIS
static let apiKey = "abc123..."

// NEW - Use this
// Keys now loaded from Secrets.plist
```

### Step 2: Create Secrets.plist
```bash
cp Secrets.plist.template Secrets.plist
# Add your key to Secrets.plist
```

### Step 3: Clean Git History (Optional but Recommended)

```bash
# Use BFG Repo Cleaner to remove keys from history
git clone --mirror https://github.com/you/anxiety.git
java -jar bfg.jar --replace-text keys.txt anxiety.git
cd anxiety.git
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push
```

Or use GitHub's "Remove sensitive data" guide:
https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository

## Checklist

Before deploying:

- [ ] `Secrets.plist` is in `.gitignore`
- [ ] `Secrets.plist.template` is in git
- [ ] API key works (test in app)
- [ ] No keys in source code
- [ ] CI/CD secrets configured
- [ ] Team knows how to set up locally
- [ ] Key rotation process documented
- [ ] Billing alerts configured
- [ ] Different keys per environment

---

**Your API keys are now secure! 🔒**

Keys are isolated from source code, never committed to git, and easy to manage across environments.
