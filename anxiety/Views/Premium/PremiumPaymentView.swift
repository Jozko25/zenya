//
//  PremiumPaymentView.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI

struct PremiumPaymentView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var activationService = ActivationService.shared
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var isProcessing = false
    @State private var showingActivationCode = false
    @State private var showingSuccess = false
    @State private var purchaseError: String?
    
    let subscriptionPlans: [SubscriptionPlan] = [.annual, .monthly]
    
    var body: some View {
        NavigationView {
            ZStack {
                AdaptiveColors.Background.primary
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerSection
                        
                        pricingPlansSection
                        
                        paymentMethodsSection
                        
                        trustSignalsSection
                        
                        termsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AdaptiveColors.Text.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.quicksand(size: 12))
                        Text("Secure Checkout")
                            .font(.quicksand(size: 12, weight: .medium))
                    }
                    .foregroundColor(AdaptiveColors.Action.progress)
                }
            }
        }
        .sheet(isPresented: $showingActivationCode) {
            ActivationCodeView()
        }
        .sheet(isPresented: $showingSuccess) {
            PurchaseSuccessView()
        }
        .alert("Payment Error", isPresented: .constant(purchaseError != nil)) {
            Button("Try Again") {
                purchaseError = nil
            }
            Button("Cancel", role: .cancel) {
                purchaseError = nil
            }
        } message: {
            if let error = purchaseError {
                Text(error)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AdaptiveColors.Action.breathing.opacity(0.2),
                                AdaptiveColors.Action.coaching.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.quicksand(size: 36, weight: .medium))
                    .foregroundColor(AdaptiveColors.Action.breathing)
            }
            
            VStack(spacing: 12) {
                Text("Unlock Premium")
                    .font(.quicksand(size: 28, weight: .bold))
                    .foregroundColor(AdaptiveColors.Text.primary)
                
                Text("Transform your mental wellness journey with unlimited access to all premium features")
                    .font(.quicksand(size: 16, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            VStack(spacing: 8) {
                FeatureBenefit(icon: "infinity", text: "Unlimited meditations & breathing exercises")
                FeatureBenefit(icon: "chart.xyaxis.line", text: "Advanced progress tracking & insights")
                FeatureBenefit(icon: "moon.stars.fill", text: "Premium sleep stories & soundscapes")
                FeatureBenefit(icon: "heart.text.square", text: "Personalized coaching & recommendations")
            }
        }
    }
    
    private var pricingPlansSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.quicksand(size: 20, weight: .semibold))
                .foregroundColor(AdaptiveColors.Text.primary)
            
            VStack(spacing: 12) {
                ForEach(subscriptionPlans, id: \.self) { plan in
                    PremiumPricingCard(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        onSelect: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPlan = plan
                            }
                        }
                    )
                }
            }
            
            Text("7-day free trial • Cancel anytime")
                .font(.quicksand(size: 13, weight: .medium))
                .foregroundColor(AdaptiveColors.Text.secondary)
                .padding(.top, 8)
        }
    }
    
    private var paymentMethodsSection: some View {
        VStack(spacing: 16) {
            // Purchase on Web Button (Primary)
            Button(action: {
                openWebPurchase()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.quicksand(size: 18, weight: .medium))
                    
                    Text("Purchase on Web")
                        .font(.quicksand(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.black)
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isProcessing)
            
            // Alternative payment methods
            VStack(spacing: 12) {
                HStack {
                    Rectangle()
                        .fill(AdaptiveColors.Text.tertiary.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("or")
                        .font(.quicksand(size: 14, weight: .medium))
                        .foregroundColor(AdaptiveColors.Text.secondary)
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(AdaptiveColors.Text.tertiary.opacity(0.3))
                        .frame(height: 1)
                }
                
                Button(action: {
                    showingActivationCode = true
                }) {
                    HStack(spacing: 12) {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "key.fill")
                                .font(.quicksand(size: 18, weight: .medium))
                        }
                        
                        Text(isProcessing ? "Processing..." : "Enter Activation Code")
                            .font(.quicksand(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [
                                AdaptiveColors.Action.breathing,
                                AdaptiveColors.Action.coaching
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isProcessing)
            }
        }
    }
    
    private var trustSignalsSection: some View {
        TherapeuticCard(elevation: .elevated) {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.quicksand(size: 20))
                        .foregroundColor(AdaptiveColors.Action.progress)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Secure & Private")
                            .font(.quicksand(size: 16, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.primary)
                        
                        Text("Your payment data is encrypted and secure")
                            .font(.quicksand(size: 14, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                    .background(AdaptiveColors.Text.tertiary.opacity(0.2))
                
                HStack(spacing: 20) {
                    PaymentMethodLogo(type: .visa)
                    PaymentMethodLogo(type: .mastercard)
                    PaymentMethodLogo(type: .amex)
                    PaymentMethodLogo(type: .discover)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Powered by")
                            .font(.quicksand(size: 11, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.tertiary)
                        
                        Text("Stripe")
                            .font(.quicksand(size: 13, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                    }
                }
            }
            .padding(20)
        }
    }
    
    private var termsSection: some View {
        VStack(spacing: 12) {
            Text("By continuing, you agree to our Terms of Service and Privacy Policy. Your subscription will automatically renew unless canceled at least 24 hours before the end of the current period.")
                .font(.quicksand(size: 12, weight: .medium))
                .foregroundColor(AdaptiveColors.Text.tertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            
            HStack(spacing: 24) {
                Button("Terms of Service") {
                    // Open terms
                }
                .font(.quicksand(size: 12, weight: .semibold))
                .foregroundColor(AdaptiveColors.Action.breathing)
                
                Button("Privacy Policy") {
                    // Open privacy
                }
                .font(.quicksand(size: 12, weight: .semibold))
                .foregroundColor(AdaptiveColors.Action.breathing)
                
                Button("Already Have Code?") {
                    showingActivationCode = true
                }
                .font(.quicksand(size: 12, weight: .semibold))
                .foregroundColor(AdaptiveColors.Text.secondary)
            }
        }
    }
    
    private func openWebPurchase() {
        // Open web purchase page
        let planType = selectedPlan == .annual ? "annual" : "monthly"
        let webURL = "https://zenya.app/purchase?plan=\(planType)"
        
        if let url = URL(string: webURL) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Models

public enum SubscriptionPlan: String, CaseIterable {
    case monthly = "Monthly"
    case annual = "Annual"
    
    public var price: String {
        switch self {
        case .monthly: return "$12.99"
        case .annual: return "$69.99"
        }
    }
    
    public var period: String {
        switch self {
        case .monthly: return "per month"
        case .annual: return "per year"
        }
    }
    
    public var savings: String? {
        switch self {
        case .monthly: return nil
        case .annual: return "Save 55%"
        }
    }
    
    public var popularBadge: Bool {
        return self == .annual
    }
    
    public var equivalentMonthlyPrice: String? {
        switch self {
        case .monthly: return nil
        case .annual: return "$5.83/month"
        }
    }
}

// MARK: - Supporting Components

struct FeatureBenefit: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.quicksand(size: 16, weight: .medium))
                .foregroundColor(AdaptiveColors.Action.breathing)
                .frame(width: 20)
            
            Text(text)
                .font(.quicksand(size: 15, weight: .medium))
                .foregroundColor(AdaptiveColors.Text.secondary)
            
            Spacer()
        }
    }
}

struct PremiumPricingCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
            impactFeedback.impactOccurred()
            onSelect()
        }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(plan.rawValue)
                            .font(.quicksand(size: 18, weight: .bold))
                            .foregroundColor(AdaptiveColors.Text.primary)
                        
                        if plan.popularBadge {
                            Text("MOST POPULAR")
                                .font(.quicksand(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AdaptiveColors.Action.sos)
                                .cornerRadius(6)
                        }
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text(plan.price)
                                .font(.quicksand(size: 24, weight: .bold))
                                .foregroundColor(AdaptiveColors.Text.primary)
                            
                            Text(plan.period)
                                .font(.quicksand(size: 14, weight: .medium))
                                .foregroundColor(AdaptiveColors.Text.secondary)
                        }
                        
                        if let equivalent = plan.equivalentMonthlyPrice {
                            Text(equivalent)
                                .font(.quicksand(size: 13, weight: .medium))
                                .foregroundColor(AdaptiveColors.Action.progress)
                        }
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.quicksand(size: 13, weight: .semibold))
                                .foregroundColor(AdaptiveColors.Action.progress)
                        }
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? AdaptiveColors.Action.breathing : AdaptiveColors.Text.tertiary.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AdaptiveColors.Action.breathing)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(20)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isSelected ?
                        AdaptiveColors.Action.breathing.opacity(colorScheme == .dark ? 0.1 : 0.05) :
                        AdaptiveColors.Surface.cardElevated
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? AdaptiveColors.Action.breathing : Color.clear,
                            lineWidth: 2
                        )
                )
        )
    }
}

enum PaymentMethodType {
    case visa, mastercard, amex, discover
    
    var imageName: String {
        switch self {
        case .visa: return "creditcard.fill"
        case .mastercard: return "creditcard.fill"
        case .amex: return "creditcard.fill"
        case .discover: return "creditcard.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .visa: return .blue
        case .mastercard: return .red
        case .amex: return .green
        case .discover: return .orange
        }
    }
}

struct PaymentMethodLogo: View {
    let type: PaymentMethodType
    
    var body: some View {
        Image(systemName: type.imageName)
            .font(.quicksand(size: 20))
            .foregroundColor(type.color.opacity(0.7))
    }
}

#Preview {
    PremiumPaymentView()
}