//
//  ActivationCode.swift
//  anxiety
//
//  Activation code models for web-based subscription system
//

import Foundation

// MARK: - Activation Code Response
struct ActivationCodeResponse: Codable {
    let success: Bool
    let userId: String?
    let planType: String?
    let expiresAt: String?
    let customerId: String?
    let message: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case userId = "user_id"
        case planType = "plan_type"
        case expiresAt = "expires_at"
        case customerId = "customer_id"
        case message
        case error
    }
}

// MARK: - Validation Response
struct SubscriptionValidationResponse: Codable {
    let isActive: Bool
    let planType: String?
    let expiresAt: String?
    let daysRemaining: Int?
    
    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
        case planType = "plan_type"
        case expiresAt = "expires_at"
        case daysRemaining = "days_remaining"
    }
}

// MARK: - Activation Error Types
enum ActivationError: LocalizedError {
    case invalidCode
    case alreadyRedeemed
    case expired
    case networkError
    case rateLimitExceeded
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "This activation code is invalid. Please check and try again."
        case .alreadyRedeemed:
            return "This code has already been used."
        case .expired:
            return "This code has expired. Please purchase a new subscription."
        case .networkError:
            return "Connection failed. Please check your internet and try again."
        case .rateLimitExceeded:
            return "Too many attempts. Please wait a moment and try again."
        case .unknown(let message):
            return message
        }
    }
}
