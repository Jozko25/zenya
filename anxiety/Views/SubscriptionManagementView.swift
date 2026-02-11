import SwiftUI

struct SubscriptionManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var cancellationService = SubscriptionCancellationService.shared
    @State private var showingCancelAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var hasActiveSubscription = UserDefaults.standard.bool(forKey: "has_active_subscription")
    @State private var subscriptionPlan = UserDefaults.standard.string(forKey: "subscription_plan_type")
    @State private var expiresAt = UserDefaults.standard.string(forKey: "subscription_expires_at")
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AdaptiveColors.Background.primary,
                    AdaptiveColors.Background.primary.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay(
                RadialGradient(
                    colors: [
                        AdaptiveColors.Action.coaching.opacity(0.1),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 40,
                    endRadius: 340
                )
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    
                    if hasActiveSubscription {
                        activeSubscriptionSection
                        featuresSection
                        cancelSubscriptionButton
                    } else {
                        noSubscriptionSection
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 26)
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cancel Subscription", isPresented: $showingCancelAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Yes, Cancel", role: .destructive) {
                Task {
                    await performCancellation()
                }
            }
        } message: {
            Text("Are you sure you want to cancel your subscription? You will retain access until the end of your billing period.")
        }
        .alert("Subscription Canceled", isPresented: $showingSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your subscription will remain active until the end of your billing period.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AdaptiveColors.Surface.cardElevated.opacity(0.9),
                                AdaptiveColors.Surface.cardElevated.opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .shadow(color: AdaptiveColors.Action.breathing.opacity(0.2), radius: 14, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AdaptiveColors.Action.breathing.opacity(0.35),
                                        AdaptiveColors.Action.coaching.opacity(0.22)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 62, height: 62)
                        Image(systemName: hasActiveSubscription ? "crown.fill" : "crown")
                            .font(.quicksand(size: 28, weight: .medium))
                            .foregroundColor(hasActiveSubscription ? AdaptiveColors.Action.breathing : AdaptiveColors.Text.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(hasActiveSubscription ? "Premium Active" : "No Active Subscription")
                            .font(.quicksand(size: 22, weight: .bold))
                            .foregroundColor(AdaptiveColors.Text.primary)

                        if hasActiveSubscription {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(AdaptiveColors.Action.progress)
                                    .frame(width: 8, height: 8)

                                Text("Full access to all features")
                                    .font(.quicksand(size: 13.5, weight: .medium))
                                    .foregroundColor(AdaptiveColors.Text.secondary)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
            }
        }
        .padding(.bottom, 6)
    }
    
    private var activeSubscriptionSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CURRENT PLAN")
                        .font(.quicksand(size: 11, weight: .bold))
                        .foregroundColor(AdaptiveColors.Text.tertiary)
                        .tracking(0.5)
                    
                    Text(subscriptionPlan?.capitalized ?? "Premium")
                        .font(.quicksand(size: 22, weight: .bold))
                        .foregroundColor(AdaptiveColors.Text.primary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AdaptiveColors.Action.progress.opacity(0.16))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.quicksand(size: 20, weight: .bold))
                        .foregroundColor(AdaptiveColors.Action.progress)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            
            if let expiresAtString = expiresAt,
               let expiresDate = ISO8601DateFormatter().date(from: expiresAtString) {
                Divider()
                    .background(AdaptiveColors.Text.tertiary.opacity(0.12))
                
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AdaptiveColors.Action.breathing.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "calendar")
                            .font(.quicksand(size: 18))
                            .foregroundColor(AdaptiveColors.Action.breathing)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next Billing Date")
                            .font(.quicksand(size: 13, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                        
                        Text(formatDate(expiresDate))
                            .font(.quicksand(size: 15, weight: .bold))
                            .foregroundColor(AdaptiveColors.Text.primary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AdaptiveColors.Surface.cardElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AdaptiveColors.Surface.card, lineWidth: 1)
                )
        )
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR BENEFITS")
                .font(.quicksand(size: 13, weight: .bold))
                .foregroundColor(AdaptiveColors.Text.tertiary)
                .tracking(0.5)
                .padding(.horizontal, 4)
            
            VStack(spacing: 10) {
                SubscriptionFeatureRow(icon: "infinity", text: "Unlimited meditations & breathing exercises")
                SubscriptionFeatureRow(icon: "chart.xyaxis.line", text: "Advanced progress tracking")
                SubscriptionFeatureRow(icon: "moon.stars.fill", text: "Premium sleep content")
                SubscriptionFeatureRow(icon: "heart.text.square", text: "Personalized coaching")
            }
        }
    }
    
    private var noSubscriptionSection: some View {
        TherapeuticCard(elevation: .elevated) {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "lock.circle")
                        .font(.quicksand(size: 48))
                        .foregroundColor(AdaptiveColors.Text.tertiary)
                    
                    Text("No Active Subscription")
                        .font(.quicksand(size: 18, weight: .bold))
                        .foregroundColor(AdaptiveColors.Text.primary)
                    
                    Text("Subscribe to unlock all premium features")
                        .font(.quicksand(size: 15, weight: .medium))
                        .foregroundColor(AdaptiveColors.Text.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.quicksand(size: 16))
                        
                        Text("View Premium Plans")
                            .font(.quicksand(size: 17, weight: .bold))
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
                    .shadow(color: AdaptiveColors.Action.breathing.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(28)
        }
    }
    
    private var cancelSubscriptionButton: some View {
        VStack(spacing: 12) {
            Divider()
                .background(AdaptiveColors.Text.tertiary.opacity(0.2))
            
            Text("Need to cancel?")
                .font(.quicksand(size: 14, weight: .medium))
                .foregroundColor(AdaptiveColors.Text.secondary)
            
            Button(action: {
                showingCancelAlert = true
            }) {
                HStack(spacing: 10) {
                    if cancellationService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FF6B6B")))
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .font(.quicksand(size: 16))
                        Text("Cancel Subscription")
                            .font(.quicksand(size: 15, weight: .semibold))
                    }
                }
                .foregroundColor(Color(hex: "FF6B6B"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "FF6B6B").opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "FF6B6B").opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(cancellationService.isLoading)
            
            Text("You'll retain access until \(formatDateShort(getExpirationDate()))")
                .font(.quicksand(size: 12.5, weight: .medium))
                .foregroundColor(AdaptiveColors.Text.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }
    
    private func getExpirationDate() -> Date {
        if let expiresAtString = expiresAt,
           let expiresDate = ISO8601DateFormatter().date(from: expiresAtString) {
            return expiresDate
        }
        return Date()
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func performCancellation() async {
        debugPrint("🚫 Starting cancellation process...")
        do {
            try await cancellationService.cancelSubscription()
            debugPrint("✅ Cancellation successful")
            hasActiveSubscription = false
            showingSuccessAlert = true
        } catch {
            debugPrint("❌ Cancellation failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct SubscriptionFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AdaptiveColors.Action.breathing.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.quicksand(size: 18, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Action.breathing)
            }
            
            Text(text)
                .font(.quicksand(size: 15, weight: .semibold))
                .foregroundColor(AdaptiveColors.Text.primary)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AdaptiveColors.Surface.cardElevated)
        )
    }
}

#Preview {
    NavigationView {
        SubscriptionManagementView()
    }
}
