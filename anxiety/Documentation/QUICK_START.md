# Quick Start Guide - Secure Setup ⚡

## 3-Step Setup (5 minutes)

### 1️⃣ Get OpenWeather API Key

1. Go to [https://openweathermap.org](https://openweathermap.org)
2. Click "Sign Up" (free account)
3. Navigate to "API Keys" section
4. Copy your API key
5. ⏰ Wait 10-15 minutes for activation

### 2️⃣ Create Secrets File

```bash
# Navigate to config folder
cd anxiety/Config

# Copy template
cp Secrets.plist.template Secrets.plist
```

### 3️⃣ Add Your API Key

Open `anxiety/Config/Secrets.plist` and replace:

```xml
<string>YOUR_API_KEY_HERE</string>
```

With your actual key:

```xml
<string>abc123def456ghi789jkl012mno345pq</string>
```

**That's it!** 🎉

## Verify It Works

1. Run the app in Xcode
2. Go to **Feel** tab
3. Click any day on the calendar
4. Look for "Expected Weather" card

✅ **Seeing real weather?** Success!  
❌ **Still simulated?** Wait 15 min for API key activation

## What You Just Did (Security)

✅ **API key is NOT in source code**  
✅ **Secrets.plist is NOT committed to git** (in .gitignore)  
✅ **Template shows structure** without exposing secrets  
✅ **Easy to rotate keys** (just edit the plist)  
✅ **Each team member has their own key**

## File Structure

```
anxiety/Config/
├── Secrets.plist.template    ← In git ✅ (no real key)
├── Secrets.plist              ← NOT in git 🔒 (your key here)
├── SecureConfig.swift         ← In git ✅ (loads secrets)
└── WeatherConfig.swift        ← In git ✅ (non-sensitive settings)
```

## Troubleshooting

### Weather not showing?

**Check 1:** Did you create Secrets.plist?
```bash
ls anxiety/Config/Secrets.plist
```

**Check 2:** Is the key in the file?
```bash
cat anxiety/Config/Secrets.plist
```

**Check 3:** Did you wait 15 minutes?
New OpenWeather API keys take 10-15 minutes to activate.

**Check 4:** Enable debug mode
```swift
// In WeatherConfig.swift
static let debugMode = true
```

Check Xcode console for error messages.

### "No secrets configuration found"

The app couldn't find your API key. Options:

**Option A:** Create Secrets.plist (recommended)
```bash
cd anxiety/Config
cp Secrets.plist.template Secrets.plist
# Edit Secrets.plist with your key
```

**Option B:** Use environment variable
```bash
# In Xcode: Product → Scheme → Edit Scheme → Arguments
# Add Environment Variable:
OPENWEATHER_API_KEY = your_key_here
```

**Option C:** Add to Info.plist (not recommended)
```xml
<key>OpenWeatherAPIKey</key>
<string>your_key_here</string>
```

## Team Setup

### New Team Member Joining?

Send them this:

```markdown
1. Clone the repo
2. cd anxiety/Config
3. cp Secrets.plist.template Secrets.plist
4. Ask team lead for OpenWeather API key
5. Add key to your local Secrets.plist
6. Never commit Secrets.plist!
```

### Secure Key Sharing

**DO:**
- ✅ Use 1Password/LastPass
- ✅ Encrypted messaging
- ✅ In person

**DON'T:**
- ❌ Email
- ❌ Slack/Discord
- ❌ Git commits

## Configuration

### Non-sensitive settings

Edit `WeatherConfig.swift` (safe to commit):

```swift
struct WeatherConfig {
    // Enable/disable weather API
    static let enabled = true
    
    // Cache duration (10 min = 600 seconds)
    static let cacheDuration: TimeInterval = 600
    
    // Debug logging
    static let debugMode = false
}
```

### Adjust cache for cost savings

```swift
// More aggressive caching = fewer API calls
static let cacheDuration: TimeInterval = 1800  // 30 minutes
```

Reduces API calls by ~66%!

## Cost Management

### Free Tier
- 1,000 calls/day
- Perfect for up to ~300 daily users
- $0/month

### Monitor Usage
1. Login to openweathermap.org
2. Go to "Statistics"
3. View daily API calls
4. Set up billing alerts

## Next Steps

- ✅ Read [SECURE_CONFIG_GUIDE.md](SECURE_CONFIG_GUIDE.md) for advanced setup
- ✅ Review [MOOD_PREDICTION_SYSTEM.md](MOOD_PREDICTION_SYSTEM.md) to understand the algorithm
- ✅ Check [WEATHER_API_SETUP.md](WEATHER_API_SETUP.md) for detailed configuration

---

**You're all set!** The weather integration is working securely. 🌤️🔒
