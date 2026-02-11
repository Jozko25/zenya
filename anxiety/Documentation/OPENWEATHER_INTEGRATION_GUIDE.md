# OpenWeather API Integration Guide

## Overview

This app now integrates with OpenWeather One Call API 3.0 to provide real-time weather-based mood predictions. The system fetches current weather, hourly forecasts, and daily forecasts to enhance mood prediction accuracy.

## Setup Instructions

### 1. Get an OpenWeather API Key

1. Visit [https://openweathermap.org](https://openweathermap.org)
2. Click "Sign Up" and create a free account
3. Navigate to "API keys" in your account dashboard
4. Copy your default API key (or create a new one)
5. **Important**: New API keys take 10-20 minutes to activate

### 2. Configure in the App

#### Option A: Through the UI (Recommended)
1. Open the app
2. Navigate to Profile → Settings → Weather Integration
3. Paste your API key
4. Click "Save Key"
5. Click "Test" to verify the connection

#### Option B: Environment Variable
Add to your Xcode scheme:
```
OPENWEATHER_API_KEY=your_api_key_here
```

#### Option C: Direct Code
```swift
OpenWeatherService.shared.setAPIKey("your_api_key_here")
```

## API Features Used

### Current Weather
- Temperature
- Feels like temperature
- Humidity
- UV Index
- Cloud coverage
- Weather conditions

### Hourly Forecast (48 hours)
- Temperature predictions
- Weather conditions
- Precipitation probability

### Daily Forecast (8 days)
- Min/max temperatures
- Weather conditions
- UV Index

## Implementation Details

### Service Architecture

**OpenWeatherService.swift**
- Handles all API communication
- Implements caching (10-minute TTL)
- Converts API responses to app's WeatherData model
- Error handling with detailed error messages

**MoodPredictionService.swift**
- Uses OpenWeatherService for weather data
- Falls back to simulated weather if API unavailable
- Integrates weather into mood prediction algorithm

### API Endpoints Used

**Current & Forecast:**
```
GET https://api.openweathermap.org/data/3.0/onecall
Parameters:
  - lat: latitude
  - lon: longitude
  - appid: API key
  - units: metric (Celsius)
  - exclude: minutely (optional)
```

**Historical Data:**
```
GET https://api.openweathermap.org/data/3.0/onecall/timemachine
Parameters:
  - lat: latitude
  - lon: longitude
  - dt: unix timestamp
  - appid: API key
  - units: metric
```

### Weather Condition Mapping

OpenWeather ID → App Condition:
- 200-232: Stormy (thunderstorm)
- 300-321: Rainy (drizzle)
- 500-531: Rainy (rain)
- 600-622: Snowy
- 701-781: Foggy (atmosphere)
- 800: Sunny (clear)
- 801: Partly Cloudy (few clouds)
- 802-804: Cloudy

### Caching Strategy

- Cache duration: 10 minutes
- Cache key: "latitude,longitude"
- Automatic cache invalidation
- Reduces API calls and improves performance

## API Pricing & Limits

### Free Tier (Recommended for Development)
- **Cost**: $0/month
- **Calls**: 1,000 calls/day
- **Features**: 
  - Current weather
  - 48-hour forecast
  - 7-day forecast
  - Historical data (5 days)

### One Call by Call 3.0
- **Cost**: ~$0.0015 per call
- **Features**:
  - All free tier features
  - Extended historical data (46+ years)
  - Weather alerts
  - AI weather assistant

### Professional Collections
Starting at $220/month for extended features.

## Usage Optimization

### Minimize API Calls

1. **Cache aggressively**: 10-minute cache reduces redundant calls
2. **Location grouping**: Use city-level precision, not exact GPS
3. **Batch requests**: Fetch weather once per session
4. **Smart invalidation**: Only refresh when user navigates to weather-dependent features

### Estimated Usage

Typical user behavior:
- Opens app: 1-2 calls
- Views calendar: 0 calls (uses cached data)
- Checks multiple days: 1 call (same location)

**Daily estimate**: 2-5 calls per active user
**Monthly with 1000 users**: 60,000-150,000 calls = $90-225/month

### Cost Reduction Strategies

1. **Increase cache TTL** to 30 minutes for less time-sensitive data
2. **Use city-level coordinates** instead of exact GPS
3. **Implement request throttling** per user
4. **Fallback to simulated weather** for non-critical features

## Error Handling

### Error Types

```swift
enum OpenWeatherError: LocalizedError {
    case noAPIKey              // User hasn't configured API key
    case invalidURL            // Malformed request
    case invalidResponse       // Invalid API response
    case invalidAPIKey         // Wrong or expired key
    case rateLimitExceeded     // Hit API rate limit
    case httpError(Int)        // Other HTTP errors
}
```

### Graceful Degradation

The app handles API failures gracefully:

1. **No API Key**: Uses simulated weather based on season
2. **API Error**: Falls back to simulated weather
3. **Rate Limit**: Uses cached data or simulated weather
4. **Network Error**: Uses last cached data

User still gets mood predictions, just without real weather data.

## Testing

### Test Connection

Use the built-in test feature:
1. Profile → Weather Integration
2. Enter API key
3. Click "Test"

This makes a test call to San Francisco coordinates.

### Manual Testing

```swift
Task {
    do {
        let weather = try await OpenWeatherService.shared.fetchWeather(
            latitude: 37.7749,
            longitude: -122.4194
        )
        print("Temperature: \(weather.current?.temp ?? 0)°C")
    } catch {
        print("Error: \(error)")
    }
}
```

### Unit Tests

```swift
func testWeatherFetch() async throws {
    let service = OpenWeatherService.shared
    service.setAPIKey("test_key")
    
    let weather = try await service.fetchWeather(
        latitude: 51.5074,
        longitude: -0.1278
    )
    
    XCTAssertNotNil(weather.current)
}
```

## Security Best Practices

### DO:
- ✅ Store API key in UserDefaults (encrypted on iOS)
- ✅ Use environment variables for development
- ✅ Implement rate limiting per user
- ✅ Clear cache on logout

### DON'T:
- ❌ Commit API keys to git
- ❌ Expose API key in logs
- ❌ Share API key in screenshots
- ❌ Use same key across multiple apps

### Key Rotation

If your key is compromised:
1. Generate new key on OpenWeather dashboard
2. Delete old key
3. Update app configuration
4. Force user re-authentication if needed

## Monitoring & Analytics

### Track These Metrics:

1. **API Success Rate**: Monitor failed requests
2. **Response Times**: Track API latency
3. **Cache Hit Rate**: Measure caching effectiveness
4. **Daily API Usage**: Stay within limits
5. **Error Types**: Identify common failures

### Implementation

```swift
struct WeatherAnalytics {
    static func logAPICall(success: Bool, responseTime: TimeInterval) {
        // Log to your analytics service
    }
    
    static func logCacheHit() {
        // Track cache effectiveness
    }
}
```

## Troubleshooting

### "Invalid API Key" Error
- **Cause**: New key not activated yet
- **Solution**: Wait 10-20 minutes after key creation

### "Rate Limit Exceeded" Error
- **Cause**: Exceeded 1,000 calls/day on free tier
- **Solution**: 
  - Wait until next day (resets at midnight UTC)
  - Upgrade to paid tier
  - Implement better caching

### Weather Data Not Updating
- **Cause**: Cache not expired yet
- **Solution**: 
  - Wait 10 minutes
  - Clear cache: `OpenWeatherService.shared.clearCache()`

### "Network Error"
- **Cause**: No internet connection
- **Solution**: App automatically falls back to simulated weather

## Future Enhancements

### Potential Improvements:

1. **Weather Alerts Integration**
   - Show government weather alerts
   - Warn users of severe weather
   - Adjust mood predictions accordingly

2. **Air Quality Data**
   - Integrate Air Quality API
   - Factor pollution into mood predictions
   - Show AQI in weather card

3. **Historical Weather Correlation**
   - Fetch actual weather for past entries
   - Build user-specific weather sensitivity profile
   - Improve prediction accuracy over time

4. **Hyperlocal Forecasts**
   - Use minute-by-minute precipitation data
   - More accurate short-term predictions
   - Better user experience

5. **Weather Notifications**
   - "Tomorrow will be sunny - great day for outdoor activities!"
   - "Rain expected - prepare mood-boosting activities"

## Resources

- [OpenWeather API Documentation](https://openweathermap.org/api/one-call-3)
- [Weather Condition Codes](https://openweathermap.org/weather-conditions)
- [API Pricing](https://openweathermap.org/price)
- [FAQ](https://openweathermap.org/faq)
- [Support](https://home.openweathermap.org/questions)

## Support

For issues with:
- **API Integration**: Check this guide first
- **OpenWeather Service**: Contact support@openweathermap.org
- **App-specific**: Check app documentation

## License Compliance

OpenWeather requires:
- Attribution in your app (if using free tier)
- Compliance with their Terms of Service
- Not reselling weather data

Add this to your app's credits:
```
Weather data provided by OpenWeather
https://openweathermap.org
```
