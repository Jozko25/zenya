//
//  ActivationService.swift
//  anxiety
//
//  Service for redeeming and validating activation codes
//

import Foundation
import SwiftUI

@MainActor
class ActivationService: ObservableObject {
    static let shared = ActivationService()
    
    @Published var isLoading = false
    @Published var error: ActivationError?
    @Published var isActivated = false
    
    private let httpClient = SupabaseHTTPClient.shared
    private let databaseService = DatabaseService.shared
    
    private init() {
        checkActivationStatus()
    }
    
    // MARK: - Check Activation Status
    
    func checkActivationStatus() {
        let hasSubscription = UserDefaults.standard.bool(forKey: "has_active_subscription")
        let expiresAt = UserDefaults.standard.string(forKey: "subscription_expires_at")
        
        if hasSubscription {
            // Check if subscription is still valid
            if let expiresAtString = expiresAt,
               let expiresDate = ISO8601DateFormatter().date(from: expiresAtString) {
                isActivated = expiresDate > Date()
            } else {
                isActivated = true // No expiration date means lifetime/valid
            }
        } else {
            isActivated = false
        }
    }
    
    // MARK: - Redeem Activation Code
    
    func redeemCode(_ code: String) async throws {
        guard !code.isEmpty else {
            throw ActivationError.invalidCode
        }
        
        // Format code (remove spaces, uppercase)
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
        
        // Validate format: ZENYA-XXXX-XXXX
        guard cleanCode.range(of: "^ZENYA-[A-Z0-9]{4}-[A-Z0-9]{4}$", options: .regularExpression) != nil else {
            throw ActivationError.invalidCode
        }
        
        error = nil
        
        do {
            // Get device ID
            guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
                throw ActivationError.networkError
            }
            
            // Call Supabase Edge Function to redeem code
            guard let url = URL(string: "\(SupabaseConfig.url)/functions/v1/redeem-activation-code") else {
                throw ActivationError.networkError
            }
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "code": cleanCode,
                "device_id": deviceId
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            
            // Log response for debugging
            debugPrint("📡 Response status: \((urlResponse as? HTTPURLResponse)?.statusCode ?? -1)")
            debugPrint("📦 Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            if let httpResponse = urlResponse as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                debugPrint("❌ Edge Function Error: \(httpResponse.statusCode) - \(errorMessage)")
                throw ActivationError.networkError
            }
            
            let apiResponse = try JSONDecoder().decode(ActivationCodeResponse.self, from: data)
            debugPrint("✅ Decoded response: success=\(apiResponse.success), planType=\(apiResponse.planType ?? "nil")")
            
            if apiResponse.success {
                // Activation successful!
                await handleSuccessfulActivation(
                    planType: apiResponse.planType,
                    expiresAt: apiResponse.expiresAt
                )
            } else {
                // Handle specific errors
                if let errorCode = apiResponse.error {
                    throw mapErrorCode(errorCode)
                } else {
                    throw ActivationError.unknown(apiResponse.message ?? "Activation failed")
                }
            }
        } catch let activationError as ActivationError {
            debugPrint("❌ Activation error: \(activationError.localizedDescription)")
            self.error = activationError
            throw activationError
        } catch {
            debugPrint("❌ Unexpected error: \(error)")
            let networkError = ActivationError.networkError
            self.error = networkError
            throw networkError
        }
    }
    
    // MARK: - Validate Subscription
    
    func validateSubscription() async throws -> Bool {
        guard let deviceId = databaseService.currentUser?.id else {
            return false
        }
        
        do {
            guard let url = URL(string: "\(SupabaseConfig.url)/functions/v1/validate-subscription") else {
                return false
            }
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "device_id": deviceId.uuidString
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let response = try JSONDecoder().decode(SubscriptionValidationResponse.self, from: data)
            
            // Update local state
            UserDefaults.standard.set(response.isActive, forKey: "has_active_subscription")
            if let expiresAt = response.expiresAt {
                UserDefaults.standard.set(expiresAt, forKey: "subscription_expires_at")
            }
            if let planType = response.planType {
                UserDefaults.standard.set(planType, forKey: "subscription_plan_type")
            }
            
            isActivated = response.isActive
            
            return response.isActive
        } catch {
            debugPrint("❌ Subscription validation failed: \(error)")
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    private func handleSuccessfulActivation(planType: String?, expiresAt: String?) async {
        // Save to UserDefaults
        UserDefaults.standard.set(true, forKey: "has_active_subscription")
        
        if let planType = planType {
            UserDefaults.standard.set(planType, forKey: "subscription_plan_type")
        }
        
        if let expiresAt = expiresAt {
            UserDefaults.standard.set(expiresAt, forKey: "subscription_expires_at")
        }
        
        debugPrint("✅ Subscription activated successfully")
        
        // Update state
        isActivated = true
        
        // Note: UserProfile is immutable, subscription state is stored in UserDefaults
        // and will be picked up by DatabaseService on next app launch
        
        // Haptic feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        debugPrint("✅ Activation successful! Plan: \(planType ?? "unknown"), Expires: \(expiresAt ?? "never")")
    }
    
    private func mapErrorCode(_ code: String) -> ActivationError {
        switch code {
        case "INVALID_CODE":
            return .invalidCode
        case "ALREADY_REDEEMED":
            return .alreadyRedeemed
        case "EXPIRED":
            return .expired
        case "RATE_LIMIT_EXCEEDED":
            return .rateLimitExceeded
        default:
            return .unknown(code)
        }
    }
}
