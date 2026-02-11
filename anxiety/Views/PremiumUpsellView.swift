//
//  PremiumUpsellView.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI

struct PremiumUpsellView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingPayment = false
    @StateObject private var activationService = ActivationService.shared
    
    let upsellContext: UpsellContext
    
    init(context: UpsellContext = .general) {
        self.upsellContext = context
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AdaptiveColors.Background.primary
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerSection
                        
                        featuresSection
                        
                        pricingPreviewSection
                        
                        socialProofSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Maybe Later") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AdaptiveColors.Text.secondary)
                }
            }
        }
        .fullScreenCover(isPresented: $showingPayment) {
            PremiumPaymentView()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 24) {
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
                    .frame(width: 100, height: 100)
                
                Image(systemName: "crown.fill")
                    .font(.quicksand(size: 40, weight: .medium))
                    .foregroundColor(AdaptiveColors.Action.breathing)
            }
            
            VStack(spacing: 16) {
                Text(upsellContext.headline)
                    .font(.quicksand(size: 28, weight: .bold))
                    .foregroundColor(AdaptiveColors.Text.primary)
                    .multilineTextAlignment(.center)
                
                Text(upsellContext.subtitle)
                    .font(.quicksand(size: 16, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Premium Features")
                .font(.quicksand(size: 22, weight: .bold))
                .foregroundColor(AdaptiveColors.Text.primary)
            
            VStack(spacing: 16) {
                UpsellFeatureRow(
                    icon: "infinity",
                    title: "Unlimited Meditations",
                    subtitle: "Access 200+ guided sessions & breathing exercises",
                    color: AdaptiveColors.Action.breathing,
                    isHighlight: upsellContext == .meditation
                )
                
                UpsellFeatureRow(
                    icon: "chart.xyaxis.line",
                    title: "Advanced Analytics",
                    subtitle: "Track mood patterns, progress & personalized insights",
                    color: AdaptiveColors.Action.progress,
                    isHighlight: upsellContext == .progress
                )
                
                UpsellFeatureRow(
                    icon: "moon.stars.fill",
                    title: "Sleep Stories & Sounds",
                    subtitle: "Premium bedtime content for better rest",
                    color: AdaptiveColors.Action.mood,
                    isHighlight: upsellContext == .sleep
                )
                
                UpsellFeatureRow(
                    icon: "brain.head.profile",
                    title: "Personalized Coaching",
                    subtitle: "AI-powered recommendations based on your data",
                    color: AdaptiveColors.Action.coaching,
                    isHighlight: upsellContext == .coaching
                )
                
                UpsellFeatureRow(
                    icon: "person.2.fill",
                    title: "Expert Support",
                    subtitle: "Priority access to mental health resources",
                    color: AdaptiveColors.Action.sos,
                    isHighlight: upsellContext == .support
                )
            }
        }
    }
    
    private var pricingPreviewSection: some View {
        TherapeuticCard(elevation: .floating) {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Free Trial")
                            .font(.quicksand(size: 20, weight: .bold))
                            .foregroundColor(AdaptiveColors.Text.primary)
                        
                        Text("7 days free, then $69.99/year")
                            .font(.quicksand(size: 16, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                        
                        Text("Save 55% vs monthly • Cancel anytime")
                            .font(.quicksand(size: 13, weight: .medium))
                            .foregroundColor(AdaptiveColors.Action.progress)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$5.83")
                            .font(.quicksand(size: 24, weight: .bold))
                            .foregroundColor(AdaptiveColors.Action.breathing)
                        
                        Text("/month")
                            .font(.quicksand(size: 14, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                    }
                }
                
                Button(action: {
                    // Bypass paywall - enable premium features and dismiss
                    // Note: Development bypass is handled in ActivationService
                    UserDefaults.standard.set(true, forKey: "has_active_subscription")
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.quicksand(size: 16))
                        
                        Text("Unlock Oasis for Free")
                            .font(.quicksand(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
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
                    .cornerRadius(14)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
        }
    }
    
    private var socialProofSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .font(.quicksand(size: 16))
                        .foregroundColor(AdaptiveColors.Action.progress)
                }
                
                Text("4.8")
                    .font(.quicksand(size: 16, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Text.primary)
                
                Text("(12,000+ reviews)")
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
            }
            
            VStack(spacing: 12) {
                TestimonialCard(
                    text: "This app helped me manage my anxiety better than therapy alone. The breathing exercises are life-changing.",
                    author: "Sarah M.",
                    isHighlighted: true
                )
                
                TestimonialCard(
                    text: "I've tried many apps but this is the first one that actually helped me sleep better. Worth every penny.",
                    author: "Mike R.",
                    isHighlighted: false
                )
            }
        }
    }
}

// MARK: - Supporting Models

enum UpsellContext {
    case general
    case meditation
    case progress
    case sleep
    case coaching
    case support
    
    var headline: String {
        switch self {
        case .general:
            return "Unlock Your Full Potential"
        case .meditation:
            return "Discover Premium Meditations"
        case .progress:
            return "Track Your Journey"
        case .sleep:
            return "Sleep Better Tonight"
        case .coaching:
            return "Get Personal Guidance"
        case .support:
            return "Access Expert Help"
        }
    }
    
    var subtitle: String {
        switch self {
        case .general:
            return "Get unlimited access to all premium features designed to transform your mental wellness"
        case .meditation:
            return "Access 200+ guided meditations and breathing exercises from world-class instructors"
        case .progress:
            return "Visualize your progress with detailed analytics and personalized insights"
        case .sleep:
            return "Drift off to premium sleep stories and soundscapes crafted for deep rest"
        case .coaching:
            return "Receive personalized recommendations based on your unique wellness journey"
        case .support:
            return "Connect with expert resources and priority support when you need it most"
        }
    }
}

// MARK: - Supporting Components

struct UpsellFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isHighlight: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        isHighlight ?
                            color.opacity(0.3) :
                            color.opacity(0.15)
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.quicksand(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            .scaleEffect(isHighlight ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlight)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.quicksand(size: 16, weight: .semibold))
                    .foregroundColor(
                        isHighlight ?
                            color :
                            AdaptiveColors.Text.primary
                    )
                
                Text(subtitle)
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if isHighlight {
                Image(systemName: "sparkles")
                    .font(.quicksand(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isHighlight ?
                        color.opacity(colorScheme == .dark ? 0.1 : 0.05) :
                        Color.clear
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHighlight ?
                        color.opacity(0.3) :
                        Color.clear,
                    lineWidth: 1
                )
        )
    }
}

struct TestimonialCard: View {
    let text: String
    let author: String
    let isHighlighted: Bool
    
    var body: some View {
        TherapeuticCard(elevation: isHighlighted ? .elevated : .flat) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .font(.quicksand(size: 12))
                            .foregroundColor(AdaptiveColors.Action.progress)
                    }
                    
                    Spacer()
                    
                    Text("Verified User")
                        .font(.quicksand(size: 11, weight: .medium))
                        .foregroundColor(AdaptiveColors.Action.progress)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AdaptiveColors.Action.progress.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text("\"\(text)\"")
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.primary)
                    .lineSpacing(2)
                
                Text("— \(author)")
                    .font(.quicksand(size: 13, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Text.secondary)
            }
            .padding(16)
        }
    }
}

#Preview {
    PremiumUpsellView(context: .meditation)
}