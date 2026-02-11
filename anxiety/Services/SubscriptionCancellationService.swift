import Foundation
import UIKit

@MainActor
class SubscriptionCancellationService: ObservableObject {
    static let shared = SubscriptionCancellationService()
    
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {}
    
    func cancelSubscription() async throws {
        debugPrint("🚫 Starting cancellation process...")
        debugPrint("📋 Debug Info:")
        debugPrint("  - has_active_subscription: \(UserDefaults.standard.bool(forKey: "has_active_subscription"))")
        debugPrint("  - subscription_plan_type: \(UserDefaults.standard.string(forKey: "subscription_plan_type") ?? "nil")")
        debugPrint("  - subscription_expires_at: \(UserDefaults.standard.string(forKey: "subscription_expires_at") ?? "nil")")
        debugPrint("  - subscription_source: \(UserDefaults.standard.string(forKey: "subscription_source") ?? "nil")")
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
            debugPrint("❌ No device ID available")
            throw CancellationError.noDeviceId
        }
        
        // For App Store subscriptions, redirect to App Store settings
        let subscriptionSource = UserDefaults.standard.string(forKey: "subscription_source")
        if subscriptionSource == "appstore" {
            debugPrint("📱 Detected App Store subscription")
            throw CancellationError.appStoreSubscription
        }
        
        // Check if user has an active subscription
        let hasActiveSubscription = UserDefaults.standard.bool(forKey: "has_active_subscription")
        if !hasActiveSubscription {
            debugPrint("❌ No active subscription found")
            throw CancellationError.noSubscription
        }
        
        debugPrint("📤 Sending cancellation request - deviceId: \(deviceId)")
        
        let url = URL(string: "https://zenya-web.vercel.app/api/cancel-subscription")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "deviceId": deviceId
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        debugPrint("📡 Making request to: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            debugPrint("❌ Invalid response type")
            throw CancellationError.networkError
        }
        
        debugPrint("📥 Response status: \(httpResponse.statusCode)")
        debugPrint("📦 Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        if httpResponse.statusCode >= 400 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            debugPrint("❌ Server error: \(errorResponse?.error ?? "Unknown error")")
            throw CancellationError.serverError(errorResponse?.error ?? "Unknown error")
        }
        
        let cancellationResponse = try JSONDecoder().decode(CancellationResponse.self, from: data)
        
        if cancellationResponse.success {
            debugPrint("✅ Subscription marked as canceled")
            UserDefaults.standard.set(false, forKey: "has_active_subscription")
        }
    }
    
    enum CancellationError: LocalizedError {
        case noSubscription
        case noDeviceId
        case networkError
        case serverError(String)
        case appStoreSubscription
        
        var errorDescription: String? {
            switch self {
            case .noSubscription:
                return "No active subscription found"
            case .noDeviceId:
                return "Unable to identify device"
            case .networkError:
                return "Network error occurred"
            case .serverError(let message):
                return message
            case .appStoreSubscription:
                return "To cancel your App Store subscription, please go to Settings > [Your Name] > Subscriptions on your device."
            }
        }
    }
}

struct CancellationResponse: Codable {
    let success: Bool
    let message: String?
    let cancelAt: Int?
    let currentPeriodEnd: Int?
}

struct ErrorResponse: Codable {
    let error: String
}
