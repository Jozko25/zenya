# Advanced Mood Prediction System

## Overview

The mood prediction system uses a multi-factor approach to predict user mood, taking into account:

1. **Historical Patterns** (Base Prediction)
2. **Weather Conditions**
3. **Seasonal Effects**
4. **Time of Year (Holidays, Events)**
5. **Moon Phases**
6. **Location Context**

## Architecture

### Core Components

#### 1. MoodPredictionService.swift
Main service that orchestrates mood predictions using contextual factors.

**Key Methods:**
- `predictMood(for:historicalEntries:location:)` - Main prediction method
- `gatherContextualFactors()` - Collects all contextual data
- `applyContextualAdjustments()` - Applies weighted adjustments

#### 2. Contextual Factors

**WeatherData**
```swift
struct WeatherData {
    let temperature: Double
    let condition: WeatherCondition // sunny, rainy, cloudy, etc.
    let humidity: Double?
    let uvIndex: Double?
    let airQuality: Int?
}
```

Impact: -0.8 to +0.8 depending on condition

**Season**
- Spring: +0.5 impact
- Summer: +0.7 impact
- Fall: 0.0 impact
- Winter: -0.4 impact

**Moon Phase**
- Full Moon: -0.2 (some studies show slight negative impact)
- New Moon: +0.1
- Other phases: 0.0

**Time of Year**
- Approaching holidays: +0.3
- New Year period: +0.2
- Tax season (March-April): -0.3

### Prediction Algorithm

```
Final Prediction = Base Prediction + Weather Adjustment + Seasonal Adjustment + Time of Year + Moon Phase
```

#### Base Prediction Weights:
- Recent entries (last 14): 40%
- Same day of week: 35%
- Last 7 days trend: 25%

#### Contextual Adjustments:
- Weather: 70% correlation strength
- Season: 50% impact multiplier
- Time of Year: 60% impact multiplier
- Moon Phase: 30% impact multiplier

### Confidence Scoring

The system provides confidence scores based on:
- Number of historical entries (more data = higher confidence)
- Recency of data
- Consistency of patterns

**Confidence Levels:**
- High: 80%+ (based on 30+ entries)
- Medium: 60-80% (based on 10-30 entries)
- Low: <60% (fewer than 10 entries)

## Integration

### Database Schema Extensions

Add to `journal_entries` table:
```sql
ALTER TABLE journal_entries 
ADD COLUMN weather_data JSONB,
ADD COLUMN location_data JSONB;
```

**weather_data structure:**
```json
{
  "temperature": 22.5,
  "condition": "sunny",
  "humidity": 65.0,
  "uv_index": 7.0,
  "feels_like": 24.0
}
```

**location_data structure:**
```json
{
  "latitude": 37.7749,
  "longitude": -122.4194,
  "city": "San Francisco",
  "country": "US"
}
```

### Weather API Integration

To enable real-time weather predictions, integrate a weather API:

**Recommended APIs:**
1. **OpenWeatherMap** (Free tier: 1000 calls/day)
   - Current weather
   - 5-day forecast
   - Historical data

2. **WeatherAPI.com** (Free tier: 1M calls/month)
   - More generous free tier
   - Good documentation

**Implementation:**
```swift
// In MoodPredictionService.swift
private func fetchWeather(for date: Date, location: CLLocation?) async -> WeatherData? {
    guard let location = location,
          let apiKey = ProcessInfo.processInfo.environment["WEATHER_API_KEY"] else {
        return generateSimulatedWeather(for: date)
    }
    
    let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(apiKey)"
    
    // Fetch and parse weather data
    // ...
}
```

### Location Services

Add to Info.plist:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to provide weather-based mood predictions</string>
```

Enable in journal entry creation:
```swift
import CoreLocation

class JournalEntryCreator: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    
    func captureLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
}
```

## Usage Examples

### Basic Prediction
```swift
let prediction = await MoodPredictionService.shared.predictMood(
    for: Date(),
    historicalEntries: userEntries,
    location: nil
)

print("Predicted mood: \(prediction.predictedMood)")
print("Confidence: \(prediction.confidenceDescription)")
```

### With Location
```swift
let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
let prediction = await MoodPredictionService.shared.predictMood(
    for: Date(),
    historicalEntries: userEntries,
    location: location
)
```

### Accessing Factors
```swift
for factor in prediction.factors {
    print("\(factor.name): \(factor.impact) - \(factor.description)")
}
```

## UI Components

### DayMoodDetailView
Shows comprehensive mood prediction with:
- Predicted vs Actual mood comparison
- Contributing factors breakdown
- Weather context card
- Visual indicators for each factor

### WeatherContextCard
Displays weather information:
- Temperature
- Condition (with icon)
- Humidity
- Impact on mood

### PredictionFactorRow
Shows individual factors:
- Factor name and icon
- Description
- Impact score (+/-)
- Visual color coding

## Future Enhancements

### 1. Machine Learning Integration
Train an ML model on user data to:
- Learn personalized weather sensitivity
- Detect unique patterns
- Improve prediction accuracy over time

### 2. Additional Factors
- Sleep quality correlation
- Exercise frequency
- Social interactions
- Stress level tracking
- Medication tracking

### 3. Correlation Analysis
Build a correlation matrix showing which factors most affect the user:
```
Weather Impact: 0.72
Season Impact: 0.45
Sleep Quality: 0.81
Exercise: 0.63
```

### 4. Notifications
"Based on tomorrow's weather (rainy, 15°C), we predict you might feel slightly down. Here are some mood-boosting activities..."

### 5. Historical Weather Data
Fetch actual weather data for past entries to improve predictions:
- Correlate past moods with weather
- Build user-specific weather sensitivity profile

## Performance Considerations

- Cache weather data (15-minute TTL)
- Batch location requests
- Store predictions to avoid recalculation
- Limit historical data queries (max 1000 entries)

## Privacy & Data

- Location data is optional
- Weather data is contextual, not identifying
- All data stays on user's device unless synced
- Clear privacy policy about data usage

## Testing

### Unit Tests
```swift
func testMoodPredictionWithSunnyWeather() {
    let entries = createMockEntries()
    let weather = WeatherData(temperature: 25, condition: .sunny, ...)
    
    // Test prediction logic
}
```

### Integration Tests
- Test with various weather conditions
- Test seasonal transitions
- Test holiday impacts
- Test with limited historical data

## Configuration

Add to environment variables:
```bash
WEATHER_API_KEY=your_api_key_here
ENABLE_LOCATION_SERVICES=true
ENABLE_WEATHER_PREDICTIONS=true
```

## Analytics

Track prediction accuracy:
```swift
struct PredictionAccuracy {
    let predictedMood: Double
    let actualMood: Double
    let difference: Double
    let factors: [PredictionFactor]
}
```

This allows continuous improvement of the algorithm.
