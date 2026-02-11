# API Keys Setup Guide 🔑

## Single Source of Truth: APIKeys.plist

All API keys are stored in **one file**: `anxiety/Config/APIKeys.plist`

This file is **never committed to git** (it's in .gitignore).

## Quick Setup (2 minutes)

### Step 1: Create APIKeys.plist

The file already exists, but if you need to recreate it:

```bash
cd anxiety/Config
cp APIKeys.plist.template APIKeys.plist
```

### Step 2: Add Your OpenWeather API Key

1. Get API key from [https://openweathermap.org](https://openweathermap.org) (free account)
2. Open `anxiety/Config/APIKeys.plist`
3. Find:
   ```xml
   <key>OpenWeather_API_Key</key>
   <string>YOUR_OPENWEATHER_API_KEY_HERE</string>
   ```
4. Replace with your key:
   ```xml
   <key>OpenWeather_API_Key</key>
   <string>abc123def456...</string>
   ```

### Step 3: Done! ✅

Your API keys are now:
- ✅ Secure (not in git)
- ✅ Centralized (one file)
- ✅ Easy to manage

## What's in APIKeys.plist

```xml
<dict>
    <!-- AI Chat -->
    <key>OpenAI_API_Key</key>
    <string>sk-proj-...</string>
    
    <!-- Weather Predictions -->
    <key>OpenWeather_API_Key</key>
    <string>YOUR_KEY_HERE</string>
    
    <!-- Database -->
    <key>Supabase_URL</key>
    <string>https://project.supabase.co</string>
    <key>Supabase_Anon_Key</key>
    <string>eyJh...</string>
</dict>
```

## Security

### ✅ Secure
- APIKeys.plist is in `.gitignore`
- Template file (`.template`) is committed (no secrets)
- Each developer has their own local `APIKeys.plist`

### ❌ Never Commit
- `anxiety/Config/APIKeys.plist` ← Contains real keys
- Never screenshot with visible keys
- Never share in plain text

## File Structure

```
anxiety/Config/
├── APIKeys.plist.template    ← Committed to git (template) ✅
├── APIKeys.plist              ← NOT in git (your keys) 🔒
├── SecureConfig.swift         ← Loads keys at runtime ✅
├── WeatherConfig.swift        ← Non-sensitive settings ✅
└── SupabaseConfig.swift       ← Uses SecureConfig ✅
```

## How It Works

```swift
// SecureConfig loads APIKeys.plist at startup
SecureConfig.shared.loadAPIKeys()

// Services use SecureConfig
OpenWeatherService → SecureConfig.shared.openWeatherAPIKey
OpenAIClient → SecureConfig.shared.openAIAPIKey
SupabaseHTTPClient → SecureConfig.shared.supabaseURL/anonKey
```

## Adding New API Keys

1. Add to `APIKeys.plist`:
   ```xml
   <key>NewService_API_Key</key>
   <string>new_key_here</string>
   ```

2. Add to `APIKeys.plist.template`:
   ```xml
   <key>NewService_API_Key</key>
   <string>YOUR_NEW_SERVICE_KEY</string>
   ```

3. Add accessor to `SecureConfig.swift`:
   ```swift
   var newServiceAPIKey: String? {
       guard let key = apiKeys["NewService_API_Key"] as? String else { return nil }
       return key.isEmpty || key.contains("YOUR_") ? nil : key
   }
   ```

4. Use in your service:
   ```swift
   let apiKey = SecureConfig.shared.newServiceAPIKey
   ```

## Team Setup

### New Developer?

1. Clone repo
2. Copy template:
   ```bash
   cd anxiety/Config
   cp APIKeys.plist.template APIKeys.plist
   ```
3. Add your OpenWeather key to `APIKeys.plist`
4. Done!

### Existing Keys

The repo already has working keys for:
- ✅ OpenAI (already configured)
- ✅ Supabase (already configured)
- ⚠️ OpenWeather (you need to add your own)

## Environment Variables (CI/CD)

For CI/CD pipelines, set environment variables:

```bash
export OPENWEATHER_API_KEY="your_key"
export OPENAI_API_KEY="your_key"
```

SecureConfig automatically falls back to environment variables if APIKeys.plist is not found.

## Troubleshooting

### "No API keys configuration found"

**Solution**: Create APIKeys.plist
```bash
cd anxiety/Config
cp APIKeys.plist.template APIKeys.plist
# Add your keys
```

### Weather not working?

**Check**: Is your OpenWeather key in APIKeys.plist?
```bash
cat anxiety/Config/APIKeys.plist | grep OpenWeather
```

Should show your actual key, not `YOUR_OPENWEATHER_API_KEY_HERE`

### Keys not loading?

**Debug**: Enable debug mode in `WeatherConfig.swift`:
```swift
static let debugMode = true
```

Check Xcode console for:
```
✅ API keys loaded from APIKeys.plist
```

## Summary

- **One file**: `APIKeys.plist` contains all keys
- **Git-safe**: File is in .gitignore, never committed
- **Template**: `.template` file shows structure
- **Simple**: Just add your OpenWeather key and you're done

---

**All API keys in one place, never in git, easy to manage.** 🔒
