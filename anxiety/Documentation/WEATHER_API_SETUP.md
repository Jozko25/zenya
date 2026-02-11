# Weather API Setup Guide

## Quick Setup (5 minutes)

### Step 1: Get Your API Key

1. Go to [https://openweathermap.org](https://openweathermap.org)
2. Click "Sign Up" (top right)
3. Fill in the form (use your business email)
4. Verify your email
5. Go to "API keys" section in your dashboard
6. Copy your default API key (or generate a new one)
7. **Important**: Wait 10-15 minutes for the key to activate

### Step 2: Add API Key to Your App

Open `anxiety/Config/WeatherConfig.swift` and replace:

```swift
static let apiKey = "YOUR_API_KEY_HERE"
```

With your actual key:

```swift
static let apiKey = "abc123def456ghi789jkl012mno345pq"
```

### Step 3: Test It

Run the app and:
1. Navigate to Feel page
2. Click on any day in the calendar
3. Look for "Expected Weather" card
4. If you see weather data → Success! ✅
5. If you see simulated weather → Check the key/wait for activation

## Configuration Options

### Enable/Disable Weather

In `WeatherConfig.swift`:

```swift
static let enabled = true  // false to disable weather API
```

### Cache Duration

Adjust how long weather data is cached:

```swift
static let cacheDuration: TimeInterval = 600  // 10 minutes (default)
// static let cacheDuration: TimeInterval = 1800  // 30 minutes (more aggressive caching)
```

### Debug Mode

Enable detailed logging:

```swift
static let debugMode = true  // Shows API calls in console
```

When enabled, you'll see:
```
🌤️ OpenWeather API Request: https://api.openweathermap.org/data/3.0/onecall?lat=37.7749&lon=-122.4194...
🌤️ OpenWeather API Response: Status 200
```

## Environment Variable (Alternative Method)

Instead of hardcoding the key, you can use an environment variable:

### Xcode Setup:
1. Product → Scheme → Edit Scheme
2. Run → Arguments
3. Environment Variables
4. Add: `OPENWEATHER_API_KEY` = `your_key_here`

The app will automatically use the environment variable in DEBUG mode.

## API Usage & Costs

### Free Tier
- ✅ **1,000 calls per day**
- ✅ Current weather
- ✅ 48-hour forecast
- ✅ 8-day forecast
- ✅ **$0/month**

Perfect for:
- Development
- Testing
- Small user base (<200 active users)

### Paid Tier (One Call by Call 3.0)
- 💵 **$0.0015 per call** (~$1.50 per 1,000 calls)
- All free tier features
- Extended historical data
- Weather alerts

### Cost Estimation

With smart caching (10 min), typical usage:

| Users | Calls/Day | Monthly Cost |
|-------|-----------|-------------|
| 100   | 300       | **Free**    |
| 500   | 1,500     | **$23**     |
| 1,000 | 3,000     | **$45**     |
| 5,000 | 15,000    | **$225**    |

### Optimize Costs

1. **Increase cache duration** to 30 minutes:
   ```swift
   static let cacheDuration: TimeInterval = 1800
   ```
   This cuts API calls by ~66%

2. **Location rounding**: Round coordinates to city level
   ```swift
   let roundedLat = round(latitude * 100) / 100  // 2 decimal places
   let roundedLon = round(longitude * 100) / 100
   ```

3. **User throttling**: Limit requests per user
   ```swift
   // Add to OpenWeatherService
   private var lastFetchTime: [String: Date] = [:]
   ```

## Monitoring

### Track API Usage

Add analytics to `OpenWeatherService.swift`:

```swift
guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200 else {
    // Log failed call
    Analytics.logEvent("weather_api_failed", parameters: ["status": statusCode])
    throw OpenWeatherError.invalidResponse
}

// Log successful call
Analytics.logEvent("weather_api_success")
```

### Check Daily Usage

OpenWeather Dashboard:
1. Login to openweathermap.org
2. Go to "Statistics"
3. View daily API call count
4. Set up alerts for approaching limits

## Error Handling

The app handles errors gracefully:

### No API Key or Disabled
→ Uses simulated weather based on season
→ Users still get mood predictions

### Rate Limit Exceeded
→ Uses cached data if available
→ Falls back to simulated weather
→ **Action**: Upgrade plan or wait for reset (midnight UTC)

### Invalid API Key
→ Falls back to simulated weather
→ **Action**: Check key in WeatherConfig.swift
→ Ensure key is activated (wait 15 min after creation)

### Network Error
→ Uses last cached data
→ Falls back to simulated weather if cache expired
→ No user-facing error

## Production Checklist

Before releasing to production:

- [ ] API key is set in `WeatherConfig.swift`
- [ ] API key is activated (waited 15+ minutes)
- [ ] Tested in app (weather data shows correctly)
- [ ] `debugMode` is set to `false`
- [ ] Cache duration is appropriate (10-30 min)
- [ ] Monitor API usage in OpenWeather dashboard
- [ ] Set up billing alerts if using paid tier
- [ ] `.gitignore` includes config file if needed

## Security

### Don't Commit API Keys

Add to `.gitignore`:
```
anxiety/Config/WeatherConfig.swift
```

Then commit a template:
```swift
// WeatherConfig.swift.template
struct WeatherConfig {
    static let apiKey = "YOUR_API_KEY_HERE"  // Replace with actual key
    static let enabled = true
    static let cacheDuration: TimeInterval = 600
    static let debugMode = false
}
```

### For CI/CD

Use environment variables:
```bash
export OPENWEATHER_API_KEY="your_key_here"
```

The app will read from environment variables in DEBUG mode.

## Troubleshooting

### "Invalid API Key" Error
**Cause**: Key not activated yet
**Solution**: Wait 10-15 minutes after creating key

### Weather Data Not Showing
**Cause**: Various (see below)
**Debug steps**:
1. Enable `debugMode = true` in WeatherConfig
2. Check console for API requests/responses
3. Verify API key is correct
4. Check internet connection
5. Verify OpenWeather service status

### "Rate Limit Exceeded"
**Cause**: Exceeded 1,000 calls/day (free tier)
**Solutions**:
- Wait until midnight UTC (resets daily)
- Increase cache duration
- Upgrade to paid tier

### Weather Always Simulated
**Causes**:
- `enabled = false` in WeatherConfig
- Invalid/missing API key
- API key not activated
- Network error

**Check**: Enable debug mode and look for error messages

## Support

### OpenWeather Support
- Website: https://openweathermap.org
- Email: info@openweathermap.org
- FAQ: https://openweathermap.org/faq

### App Integration Issues
- Check this guide first
- Enable debug mode
- Check console logs
- Review error messages

## API Documentation

- **One Call API 3.0**: https://openweathermap.org/api/one-call-3
- **Weather Conditions**: https://openweathermap.org/weather-conditions
- **API Errors**: https://openweathermap.org/faq#error401

## Example API Response

```json
{
  "lat": 37.7749,
  "lon": -122.4194,
  "current": {
    "dt": 1698422400,
    "temp": 18.5,
    "feels_like": 17.2,
    "humidity": 65,
    "uvi": 3.2,
    "weather": [{
      "id": 800,
      "main": "Clear",
      "description": "clear sky",
      "icon": "01d"
    }]
  },
  "hourly": [...],
  "daily": [...]
}
```

## License & Attribution

OpenWeather free tier requires attribution:

Add to your app's About/Credits section:
```
Weather data provided by OpenWeather
https://openweathermap.org
```

## Next Steps

After setup is working:

1. ✅ Monitor API usage for first week
2. ✅ Adjust cache duration based on usage
3. ✅ Set up billing alerts
4. ✅ Consider paid tier if approaching limits
5. ✅ Track weather prediction accuracy
6. ✅ Gather user feedback on weather features
