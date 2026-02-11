//
//  ActivationLandingView.swift
//  anxiety
//
//  Landing screen for users without activation code
//

import SwiftUI
import UIKit

struct ActivationLandingView: View {
    @State private var showCodeEntry = false
    @State private var showPurchaseWeb = false
    @State private var animateElements = false
    @Environment(\.colorScheme) var colorScheme
    
    private let starOffsets: [CGPoint] = [
        CGPoint(x: -140, y: -200),
        CGPoint(x: 110, y: -190),
        CGPoint(x: -40, y: -30),
        CGPoint(x: 140, y: 40),
        CGPoint(x: -150, y: 140),
        CGPoint(x: 40, y: 220)
    ]
    
    private var logoImage: Image {
        Image("ZenyaLogo")
    }
    
    private let theme = SoulPalette.neon
    
    private var webURL: String {
        let baseURL = "https://zenya-web.vercel.app/"
        let colorSchemeParam = colorScheme == .dark ? "dark" : "light"
        let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"
        return "\(baseURL)?theme=\(colorSchemeParam)&device=\(deviceType)&source=ios"
    }
    
    var body: some View {
        ZStack {
            backgroundDecor

            starfield

            VStack(spacing: 16) {
                Spacer()

                heroSection

                ratingRow

                minimalBenefits

                Spacer()

                ctaSection

                legalSection
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 50)
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $showCodeEntry) {
            ActivationCodeView()
                .presentationDetents([.large])
        }
        .webViewSheet(url: URL(string: webURL), isPresented: $showPurchaseWeb)
        .onAppear {
            prefetchWebsite()
        }
    }
    
    private var backgroundDecor: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "0C0208"),
                    Color(hex: "27061A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [theme.glow.opacity(0.25), Color.clear]),
                center: .topLeading,
                startRadius: 40,
                endRadius: 420
            )
            .blendMode(.screen)
            .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [theme.accentSecondary.opacity(0.12), Color.clear]),
                center: .bottomTrailing,
                startRadius: 80,
                endRadius: 440
            )
            .blendMode(.screen)
            .ignoresSafeArea()
            
            // Subtle overlay to mirror home gradient rings
            Circle()
                .fill(theme.accent.opacity(0.10))
                .frame(width: 340, height: 340)
                .blur(radius: 120)
                .offset(x: -160, y: -220)
                .allowsHitTesting(false)
            Circle()
                .fill(theme.accentSecondary.opacity(0.12))
                .frame(width: 420, height: 420)
                .blur(radius: 160)
                .offset(x: 180, y: 260)
                .allowsHitTesting(false)
        }
    }
    
    private var starfield: some View {
        ZStack {
            ForEach(Array(starOffsets.enumerated()), id: \.offset) { _, point in
                Image(systemName: "star.fill")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(theme.accent.opacity(0.16))
                    .shadow(color: theme.glow.opacity(0.18), radius: 6, x: 0, y: 0)
                    .offset(x: point.x, y: point.y)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    // MARK: - Hero Section
    
    private var logoHeader: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "2B0B1B"),
                                Color(hex: "15030D")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 134, height: 134)
                    .shadow(color: theme.glow.opacity(0.55), radius: 22, x: 0, y: 14)
                
                logoImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 134, height: 134)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
            
            Button(action: {
                showCodeEntry = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Have a code?")
                        .font(.quicksand(size: 13, weight: .medium))
                }
                .foregroundColor(theme.textPrimary)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surfaceAlt.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.outline.opacity(0.45), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            Text("$4.99 / month after trial • billed via App Store")
                .font(.quicksand(size: 12.5, weight: .medium))
                .foregroundColor(.white.opacity(0.65))
        }
    }
    
    private var heroSection: some View {
        VStack(spacing: 8) {
            Text("Zenya")
                .font(.quicksand(size: 42, weight: .bold))
                .foregroundColor(.white)

            Text("Transform your mental wellness")
                .font(.quicksand(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Text("Breathing, rhythm, and insights designed to feel like your home dashboard.")
                .font(.quicksand(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
    }
    
    private var ratingRow: some View {
        HStack(spacing: 6) {
            ForEach(0..<5) { index in
                Image(systemName: index == 4 ? "star.leadinghalf.filled" : "star.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "FFC86E"))
                    .opacity(index == 4 ? 0.85 : 1)
            }
            Text("4.8 • Loved by beta users")
                .font(.quicksand(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.78))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 18)
        .background(
            Capsule()
                .fill(theme.surface.opacity(0.5))
        )
    }
    
    // MARK: - Benefits
    private var minimalBenefits: some View {
        VStack(spacing: 12) {
            benefitRow(icon: "sparkles", title: "Daily rhythm", subtitle: "Smart nudges tuned to your habits")
            benefitRow(icon: "wind", title: "Calm breathing", subtitle: "2-min routines to recentre fast")
            benefitRow(icon: "lock.shield", title: "Privacy-first", subtitle: "Your reflections stay encrypted")
        }
    }
    
    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.accent)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.quicksand(size: 15.5, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.quicksand(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.outline.opacity(0.25), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        HStack(spacing: 16) {
            Button(action: {
                if let url = URL(string: "https://zenya-web.vercel.app/terms") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Terms of Service")
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(theme.textSecondary.opacity(0.8))
            }
            
            Text("•")
                .font(.quicksand(size: 12, weight: .medium))
                .foregroundColor(theme.textSecondary.opacity(0.5))
            
            Button(action: {
                if let url = URL(string: "https://zenya-web.vercel.app/privacy") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Privacy Policy")
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(theme.textSecondary.opacity(0.8))
            }
        }
    }
    
    // MARK: - CTA Section
    
    private var ctaSection: some View {
        VStack(spacing: 10) {
            Button(action: openWebsite) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start Your Journey")
                            .font(.quicksand(size: 16, weight: .semibold))
                        Text("7 days free • $4.99/month after")
                            .font(.quicksand(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        colors: [theme.accent, theme.accentSecondary.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: theme.accent.opacity(0.3), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            Button(action: { showCodeEntry = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Have a code?")
                        .font(.quicksand(size: 13, weight: .medium))
                }
                .foregroundColor(theme.textSecondary)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .background(theme.surfaceAlt.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.outline.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(theme.accent)
                Text("No commitment • Cancel anytime")
                    .font(.quicksand(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.surface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(theme.outline.opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helpers
    
    private func openWebsite() {
        // Immediate haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        debugPrint("🌐 Opening in-app purchase flow with theme: \(colorScheme == .dark ? "dark" : "light")")
        debugPrint("🌐 Full URL: \(webURL)")
        
        // Open immediately - no loading state
        showPurchaseWeb = true
    }
    
    // MARK: - Performance Optimization
    
    private func prefetchWebsite() {
        // Prefetch the URL to warm up DNS and connection
        guard let url = URL(string: webURL) else { return }
        
        let prefetchTask = URLSession.shared.dataTask(with: URLRequest(url: url)) { _, _, _ in
            // We don't need to handle the response, just warming up the connection
            debugPrint("🚀 Website prefetch completed")
        }
        prefetchTask.resume()
    }
}

// MARK: - Feature Row Component

struct ActivationFeatureRow: View {
    let theme: SoulPalette
    let icon: String
    let text: String
    var highlight: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.accent.opacity(0.28),
                            theme.accentSecondary.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(theme.accent)
                )
                .shadow(color: theme.accent.opacity(0.18), radius: 6, x: 0, y: 3)
            
            Text(text)
                .font(.quicksand(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            if let highlight = highlight {
                Text(highlight)
                .font(.quicksand(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(theme.surface.opacity(0.6))
                )
            }
        }
    }
}

#Preview {
    ActivationLandingView()
}
