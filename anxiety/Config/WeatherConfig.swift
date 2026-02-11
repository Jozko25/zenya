//
//  WeatherConfig.swift
//  anxiety
//
//  Weather API Configuration (Non-sensitive settings only)
//  API key is stored in APIKeys.plist (never committed to git)
//

import Foundation

struct WeatherConfig {
    /// Enable/disable weather integration
    /// Set to false to use simulated weather only
    static let enabled = true
    
    /// Cache duration in seconds (default: 10 minutes)
    /// Increase to reduce API calls (e.g., 1800 for 30 minutes)
    static let cacheDuration: TimeInterval = 600
    
    /// Debug mode - prints API calls and responses
    /// Set to true during development, false in production
    static let debugMode = false
}
