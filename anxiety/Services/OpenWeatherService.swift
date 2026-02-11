//
//  OpenWeatherService.swift
//  anxiety
//
//  OpenWeather One Call API 3.0 Integration
//

import Foundation
import CoreLocation

struct OpenWeatherResponse: Codable {
    let lat: Double
    let lon: Double
    let timezone: String
    let current: CurrentWeather?
    let hourly: [HourlyWeather]?
    let daily: [DailyWeather]?
    let alerts: [WeatherAlert]?
    
    struct CurrentWeather: Codable {
        let dt: Int
        let temp: Double
        let feelsLike: Double
        let pressure: Int
        let humidity: Int
        let dewPoint: Double
        let uvi: Double
        let clouds: Int
        let visibility: Int
        let windSpeed: Double
        let weather: [Weather]
        
        enum CodingKeys: String, CodingKey {
            case dt, temp, pressure, humidity, clouds, visibility, uvi
            case feelsLike = "feels_like"
            case dewPoint = "dew_point"
            case windSpeed = "wind_speed"
            case weather
        }
    }
    
    struct HourlyWeather: Codable {
        let dt: Int
        let temp: Double
        let feelsLike: Double
        let humidity: Int
        let uvi: Double
        let clouds: Int
        let weather: [Weather]
        let pop: Double
        
        enum CodingKeys: String, CodingKey {
            case dt, temp, humidity, uvi, clouds, weather, pop
            case feelsLike = "feels_like"
        }
    }
    
    struct DailyWeather: Codable {
        let dt: Int
        let temp: Temperature
        let humidity: Int
        let weather: [Weather]
        let clouds: Int
        let uvi: Double
        let pop: Double
        
        struct Temperature: Codable {
            let day: Double
            let min: Double
            let max: Double
            let night: Double
            let eve: Double
            let morn: Double
        }
    }
    
    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct WeatherAlert: Codable {
        let senderName: String
        let event: String
        let start: Int
        let end: Int
        let description: String
        
        enum CodingKeys: String, CodingKey {
            case event, start, end, description
            case senderName = "sender_name"
        }
    }
}

@MainActor
class OpenWeatherService: ObservableObject {
    static let shared = OpenWeatherService()
    
    private let baseURL = "https://api.openweathermap.org/data/3.0/onecall"
    
    private var apiKey: String? {
        if !WeatherConfig.enabled {
            return nil
        }
        
        return SecureConfig.shared.openWeatherAPIKey
    }
    
    private var weatherCache: [String: CachedWeather] = [:]
    private var cacheExpiration: TimeInterval {
        return WeatherConfig.cacheDuration
    }
    
    struct CachedWeather {
        let data: OpenWeatherResponse
        let timestamp: Date
    }
    
    private init() {}
    
    func fetchWeather(
        latitude: Double,
        longitude: Double,
        date: Date = Date()
    ) async throws -> OpenWeatherResponse {
        
        let cacheKey = "\(latitude),\(longitude)"
        if let cached = weatherCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
            return cached.data
        }
        
        guard let apiKey = apiKey else {
            throw OpenWeatherError.noAPIKey
        }
        
        let isFuture = date > Date()
        let isPast = date < Date().addingTimeInterval(-3600)
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]
        
        if !isPast && !isFuture {
            urlComponents.queryItems?.append(contentsOf: [
                URLQueryItem(name: "exclude", value: "minutely")
            ])
        }
        
        guard let url = urlComponents.url else {
            throw OpenWeatherError.invalidURL
        }
        
        if WeatherConfig.debugMode {
            debugPrint("🌤️ OpenWeather API Request: \(url.absoluteString)")
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenWeatherError.invalidResponse
        }
        
        if WeatherConfig.debugMode {
            debugPrint("🌤️ OpenWeather API Response: Status \(httpResponse.statusCode)")
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw OpenWeatherError.invalidAPIKey
            } else if httpResponse.statusCode == 429 {
                throw OpenWeatherError.rateLimitExceeded
            }
            throw OpenWeatherError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let weatherResponse = try decoder.decode(OpenWeatherResponse.self, from: data)
        
        weatherCache[cacheKey] = CachedWeather(data: weatherResponse, timestamp: Date())
        
        return weatherResponse
    }
    
    func fetchHistoricalWeather(
        latitude: Double,
        longitude: Double,
        date: Date
    ) async throws -> OpenWeatherResponse {
        guard let apiKey = apiKey else {
            throw OpenWeatherError.noAPIKey
        }
        
        let timestamp = Int(date.timeIntervalSince1970)
        
        let urlString = "https://api.openweathermap.org/data/3.0/onecall/timemachine"
        var urlComponents = URLComponents(string: urlString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "dt", value: String(timestamp)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]
        
        guard let url = urlComponents.url else {
            throw OpenWeatherError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenWeatherError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(OpenWeatherResponse.self, from: data)
    }
    
    func convertToWeatherData(_ response: OpenWeatherResponse, for date: Date = Date()) -> WeatherData {
        let calendar = Calendar.current
        let targetHour = calendar.component(.hour, from: date)
        
        let weather: OpenWeatherResponse.Weather
        let temp: Double
        let humidity: Double
        let uvi: Double
        
        if calendar.isDateInToday(date), let current = response.current {
            weather = current.weather.first!
            temp = current.temp
            humidity = Double(current.humidity)
            uvi = current.uvi
        } else if let hourly = response.hourly {
            let targetTimestamp = Int(date.timeIntervalSince1970)
            let closestHour = hourly.min(by: { abs($0.dt - targetTimestamp) < abs($1.dt - targetTimestamp) })
            
            if let hour = closestHour {
                weather = hour.weather.first!
                temp = hour.temp
                humidity = Double(hour.humidity)
                uvi = hour.uvi
            } else {
                weather = OpenWeatherResponse.Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")
                temp = 20.0
                humidity = 50.0
                uvi = 5.0
            }
        } else if let daily = response.daily?.first {
            weather = daily.weather.first!
            temp = daily.temp.day
            humidity = Double(daily.humidity)
            uvi = daily.uvi
        } else {
            weather = OpenWeatherResponse.Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")
            temp = 20.0
            humidity = 50.0
            uvi = 5.0
        }
        
        let condition = mapWeatherCondition(weatherId: weather.id, main: weather.main)
        
        return WeatherData(
            temperature: temp,
            condition: condition,
            humidity: humidity,
            uvIndex: uvi,
            airQuality: nil
        )
    }
    
    private func mapWeatherCondition(weatherId: Int, main: String) -> WeatherData.WeatherCondition {
        switch weatherId {
        case 200...232:
            return .stormy
        case 300...321:
            return .rainy
        case 500...531:
            return .rainy
        case 600...622:
            return .snowy
        case 701...781:
            return .foggy
        case 800:
            return .sunny
        case 801:
            return .partlyCloudy
        case 802...804:
            return .cloudy
        default:
            if main.lowercased().contains("cloud") {
                return .cloudy
            } else if main.lowercased().contains("rain") {
                return .rainy
            } else if main.lowercased().contains("snow") {
                return .snowy
            }
            return .sunny
        }
    }
    
    func clearCache() {
        weatherCache.removeAll()
    }
}

enum OpenWeatherError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case invalidAPIKey
    case rateLimitExceeded
    case httpError(statusCode: Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenWeather API key not configured. Please add your API key in settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from weather service"
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenWeather API key."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode weather data: \(error.localizedDescription)"
        }
    }
}
