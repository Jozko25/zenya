//
//  ProfileView.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var userName: String = SecureStorage.shared.userName ?? "User"
    @State private var showingPremiumPayment = false
    @State private var showingSubscriptionManagement = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AdaptiveColors.Background.primary
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileHeader

                        VStack(spacing: 14) {
                            subscriptionCard
                            safetySection
                        }
                        .padding(.horizontal, 20)
                        
                        // Bottom actions section
                        VStack(spacing: 24) {
                            logoutSection
                            dangerZoneSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.quicksand(size: 22))
                            .foregroundColor(AdaptiveColors.Text.tertiary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                performAccountDeletion()
            }
        } message: {
            Text("This will permanently delete all your data including journal entries, progress, and preferences. This action cannot be undone.")
        }
        .sheet(isPresented: $showingPremiumPayment) {
            PremiumPaymentView()
        }
        .sheet(isPresented: $showingSubscriptionManagement) {
            NavigationView {
                SubscriptionManagementView()
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AdaptiveColors.Surface.cardElevated.opacity(0.9),
                                AdaptiveColors.Surface.cardElevated.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 8)
                    .frame(height: 140)
                    .padding(.horizontal, 12)

                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AdaptiveColors.Action.breathing.opacity(0.35),
                                        AdaptiveColors.Action.coaching.opacity(0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 84, height: 84)
                            .shadow(color: AdaptiveColors.Action.breathing.opacity(0.25), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(userName.isEmpty ? "Welcome" : userName)
                            .font(.quicksand(size: 22, weight: .bold))
                            .foregroundColor(AdaptiveColors.Text.primary)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.quicksand(size: 13))
                            Text("Member since \(getJoinDate())")
                                .font(.quicksand(size: 14, weight: .medium))
                        }
                        .foregroundColor(AdaptiveColors.Text.secondary)
                    }
                    
                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 26)
            }
        }
        .padding(.vertical, 2)
    }
    
    private var subscriptionCard: some View {
        Button {
            showingSubscriptionManagement = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AdaptiveColors.Action.breathing.opacity(0.3),
                                    AdaptiveColors.Action.coaching.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: "crown.fill")
                        .font(.quicksand(size: 16, weight: .medium))
                        .foregroundColor(AdaptiveColors.Action.breathing)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subscription")
                        .font(.quicksand(size: 15, weight: .semibold))
                        .foregroundColor(AdaptiveColors.Text.primary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AdaptiveColors.Action.progress)
                            .frame(width: 6, height: 6)
                        
                        Text("Premium Active")
                            .font(.quicksand(size: 12.5, weight: .medium))
                            .foregroundColor(AdaptiveColors.Action.progress)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.quicksand(size: 13, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Text.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AdaptiveColors.Surface.cardElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var logoutSection: some View {
        Button {
            showingLogoutAlert = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                
                Text("Log Out")
                    .font(.quicksand(size: 15, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AdaptiveColors.Surface.cardElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Danger zone header
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.red.opacity(0.7))
                
                Text("DANGER ZONE")
                    .font(.quicksand(size: 12, weight: .bold))
                    .foregroundColor(Color.red.opacity(0.7))
                    .tracking(0.5)
            }
            .padding(.horizontal, 4)
            
            // Delete account button
            Button {
                showingDeleteAccountAlert = true
            } label: {
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.red.opacity(0.8))
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Delete Account")
                                .font(.quicksand(size: 15, weight: .semibold))
                                .foregroundColor(AdaptiveColors.Text.primary)
                            
                            Text("Permanently delete all data. This cannot be undone.")
                                .font(.quicksand(size: 12, weight: .medium))
                                .foregroundColor(AdaptiveColors.Text.tertiary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AdaptiveColors.Surface.cardElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Delete Account")
            .accessibilityHint("Permanently deletes all your data")
        }
    }

    private var safetySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SAFETY & PRIVACY")
                .font(.quicksand(size: 13, weight: .bold))
                .foregroundColor(AdaptiveColors.Text.tertiary)
                .tracking(0.5)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AdaptiveColors.Action.sos)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Not therapy or medical advice")
                            .font(.quicksand(size: 14, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.primary)
                        Text("The AI is for support only and cannot diagnose or treat.")
                            .font(.quicksand(size: 13))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                    }
                }

                Divider()
                    .background(AdaptiveColors.Surface.card)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AdaptiveColors.Action.progress)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Third parties process AI chats")
                            .font(.quicksand(size: 14, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.primary)
                        Text("Messages in the AI tab are sent to OpenAI to generate replies. Avoid sharing sensitive details you wouldn’t put in a text message.")
                            .font(.quicksand(size: 13))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AdaptiveColors.Surface.cardElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AdaptiveColors.Surface.card, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private func getJoinDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    private func performLogout() {
        // Clear user data
        UserDefaults.standard.removeObject(forKey: "has_completed_onboarding")
        UserDefaults.standard.removeObject(forKey: "user_name")
        UserDefaults.standard.removeObject(forKey: "has_active_subscription")
        UserDefaults.standard.removeObject(forKey: "subscription_start_date")
        
        // Post logout notification
        NotificationCenter.default.post(name: Notification.Name("UserDidLogout"), object: nil)

        // Dismiss profile view
        presentationMode.wrappedValue.dismiss()
    }
    
    private func performAccountDeletion() {
        // Clear all secure storage (Keychain data)
        SecureStorage.shared.clearAllSecureData()
        
        // Clear all UserDefaults data
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
        
        // Also clear specific keys that might persist
        UserDefaults.standard.removeObject(forKey: "has_completed_onboarding")
        UserDefaults.standard.removeObject(forKey: "user_name")
        UserDefaults.standard.removeObject(forKey: "has_active_subscription")
        UserDefaults.standard.removeObject(forKey: "subscription_start_date")
        UserDefaults.standard.synchronize()
        
        // Post account deletion notification (for app-wide cleanup)
        NotificationCenter.default.post(name: Notification.Name("UserDidDeleteAccount"), object: nil)
        
        // Dismiss profile view
        presentationMode.wrappedValue.dismiss()
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.quicksand(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ProfileSettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.quicksand(size: 20))
                    .foregroundColor(Color(hex: "6B73FF"))
                    .frame(width: 28)
                
                Text(title)
                    .font(.quicksand(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.quicksand(size: 14))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    UserProfileView()
}
