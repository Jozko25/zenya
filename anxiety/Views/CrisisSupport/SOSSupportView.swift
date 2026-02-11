//
//  SOSSupportView.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI
import MessageUI

struct SOSSupportView: View {
    @State private var showingEmergencyCall = false
    @State private var showingQuickCalm = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                AdaptiveColors.Background.primary
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection

                        emergencyActionsSection

                        quickCalmSection

                        resourcesSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingQuickCalm) {
            EmergencyBreathingView()
        }
        .alert("Emergency Call", isPresented: $showingEmergencyCall) {
            Button("Call 988 (Crisis Line)", role: .destructive) {
                if let url = URL(string: "tel://988") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Call 911 (Emergency)", role: .destructive) {
                if let url = URL(string: "tel://911") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("If you're in immediate danger, call 911. For mental health crisis support, call 988.")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FF5C7A").opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "heart.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(Color(hex: "FF5C7A"))
            }

            VStack(spacing: 10) {
                Text("You're Safe Here")
                    .font(.instrumentSerif(size: 30))
                    .foregroundColor(AdaptiveColors.Text.primary)

                Text("Help is available 24/7. You don't have to face this alone.")
                    .font(.quicksand(size: 15, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var emergencyActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Get Help Now")
                .font(.instrumentSerif(size: 20))
                .foregroundColor(AdaptiveColors.Text.primary)

            VStack(spacing: 10) {
                // Primary - Call Crisis Line
                Button(action: { showingEmergencyCall = true }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "FF5C7A"))
                                .frame(width: 48, height: 48)

                            Image(systemName: "phone.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Call Crisis Line")
                                .font(.quicksand(size: 16, weight: .bold))
                                .foregroundColor(AdaptiveColors.Text.primary)

                            Text("988 • Free 24/7 support")
                                .font(.quicksand(size: 13, weight: .medium))
                                .foregroundColor(AdaptiveColors.Text.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.tertiary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.Surface.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "FF5C7A").opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Text Support
                Button(action: {
                    if let url = URL(string: "sms:741741&body=HOME") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "FF5C7A").opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: "message.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(hex: "FF5C7A"))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Text Support")
                                .font(.quicksand(size: 16, weight: .bold))
                                .foregroundColor(AdaptiveColors.Text.primary)

                            Text("Text HOME to 741741")
                                .font(.quicksand(size: 13, weight: .medium))
                                .foregroundColor(AdaptiveColors.Text.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.tertiary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.Surface.card)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // 911
                Button(action: {
                    if let url = URL(string: "tel://911") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "FF2E50").opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: "cross.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(hex: "FF2E50"))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Emergency 911")
                                .font(.quicksand(size: 16, weight: .bold))
                                .foregroundColor(AdaptiveColors.Text.primary)

                            Text("Immediate danger only")
                                .font(.quicksand(size: 13, weight: .medium))
                                .foregroundColor(AdaptiveColors.Text.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.tertiary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.Surface.card)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var quickCalmSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Calm")
                .font(.quicksand(size: 18, weight: .bold))
                .foregroundColor(AdaptiveColors.Text.primary)

            // Single breathing button - 3D style
            Button(action: { showingQuickCalm = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "wind")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Emergency Breathing")
                        .font(.quicksand(size: 16, weight: .semibold))

                    Spacer()

                    Text("2 min")
                        .font(.quicksand(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "FF5C7A"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(hex: "FF5C7A").opacity(0.15))
                        )
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    ZStack {
                        // Shadow layer
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "C83555"))
                            .offset(y: 3)

                        // Main gradient
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "FF7A95"),
                                        Color(hex: "FF5C7A"),
                                        Color(hex: "D94467")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // Highlight
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: Color(hex: "FF5C7A").opacity(0.4), radius: 12, x: 0, y: 6)
            }
        }
    }
    
    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("More Resources")
                .font(.quicksand(size: 18, weight: .bold))
                .foregroundColor(AdaptiveColors.Text.primary)

            VStack(spacing: 0) {
                // Trans Lifeline
                Button(action: {
                    if let url = URL(string: "tel://877-565-8860") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text("Trans Lifeline")
                            .font(.quicksand(size: 15, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.primary)

                        Spacer()

                        Text("877-565-8860")
                            .font(.quicksand(size: 13, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.secondary)

                        Image(systemName: "phone.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "FF5C7A"))
                    }
                    .padding(.vertical, 14)
                }

                Divider()
                    .background(AdaptiveColors.Surface.cardElevated)

                // SAMHSA
                Button(action: {
                    if let url = URL(string: "tel://1-800-662-4357") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text("SAMHSA Helpline")
                            .font(.quicksand(size: 15, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.primary)

                        Spacer()

                        Text("1-800-662-4357")
                            .font(.quicksand(size: 13, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.secondary)

                        Image(systemName: "phone.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "FF5C7A"))
                    }
                    .padding(.vertical, 14)
                }

                Divider()
                    .background(AdaptiveColors.Surface.cardElevated)

                // International
                Button(action: {
                    if let url = URL(string: "https://www.iasp.info/resources/Crisis_Centres/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text("International Crisis Centers")
                            .font(.quicksand(size: 15, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.primary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "FF5C7A"))
                    }
                    .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AdaptiveColors.Surface.card)
            )

            // Safety note - simplified
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "FF5C7A"))

                Text("These feelings are temporary. Help is always available.")
                    .font(.quicksand(size: 13, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "FF5C7A").opacity(0.1))
            )
        }
    }
}

#Preview {
    SOSSupportView()
}