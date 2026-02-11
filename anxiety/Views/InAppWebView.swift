//
//  InAppWebView.swift
//  anxiety
//
//  In-app web browser for purchasing/recovering codes
//

import SwiftUI
import WebKit

// Identifiable wrapper for activation code
struct ActivationCodeItem: Identifiable {
    let id = UUID()
    let code: String?
}

struct InAppWebView: View {
    let url: URL
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var activationCodeItem: ActivationCodeItem? = nil
    @State private var webViewReference: WKWebView?

    var body: some View {
        ZStack {
            AdaptiveColors.Background.primary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                WebView(
                    url: url,
                    isLoading: $isLoading,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    activationCodeItem: $activationCodeItem,
                    webViewRef: $webViewReference
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 4)
                .ignoresSafeArea(.container, edges: .bottom)
            }

            if isLoading {
                loadingOverlay
            }
        }
        .sheet(item: $activationCodeItem) { item in
            ActivationCodeView(prefillCode: item.code)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
        }
    }
}

// MARK: - WebKit WebView

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var activationCodeItem: ActivationCodeItem?
    @Binding var webViewRef: WKWebView?
    @Environment(\.colorScheme) var colorScheme
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // Performance optimizations
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.suppressesIncrementalRendering = false

        // MARK: - iOS Bridge - Register Message Handler
        // This allows the web app to communicate with the native iOS app
        configuration.userContentController.add(context.coordinator, name: "openRedeemModal")

        // Inject viewport meta tag for proper responsive scaling
        let viewportScript = """
        (function() {
            // Remove any existing viewport meta tags
            var existingViewport = document.querySelector('meta[name="viewport"]');
            if (existingViewport) {
                existingViewport.remove();
            }

            // Add responsive viewport meta tag
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes, viewport-fit=cover';
            document.head.appendChild(meta);

            // Ensure body and html are full width
            document.documentElement.style.width = '100%';
            document.documentElement.style.overflow = 'auto';
            document.body.style.width = '100%';
            document.body.style.overflow = 'auto';
        })();
        """

        let viewportUserScript = WKUserScript(source: viewportScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(viewportUserScript)

        // Inject theme detection script
        let themeScript = """
        // Wait for DOM to be ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', applyTheme);
        } else {
            applyTheme();
        }

        function applyTheme() {
            const isDark = '\(colorScheme == .dark ? "true" : "false")' === 'true';

            // Method 1: Set data attribute on HTML element
            document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');

            // Method 2: Add/remove dark class
            if (isDark) {
                document.documentElement.classList.add('dark');
                document.body.classList.add('dark');
            } else {
                document.documentElement.classList.remove('dark');
                document.body.classList.remove('dark');
            }

            // Method 3: Set CSS custom property
            document.documentElement.style.setProperty('--app-theme', isDark ? 'dark' : 'light');

            // Method 4: Dispatch custom event for React/Vue apps
            window.dispatchEvent(new CustomEvent('themeChange', {
                detail: { theme: isDark ? 'dark' : 'light' }
            }));

            // Method 5: Set global variable
            window.APP_THEME = isDark ? 'dark' : 'light';
        }
        """

        let userScript = WKUserScript(source: themeScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(userScript)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        DispatchQueue.main.async {
            self.webViewRef = webView
        }

        // Responsive webview optimizations
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.scrollView.bounces = true
        webView.allowsLinkPreview = false

        // Enable automatic content scaling for different device sizes
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        // Setup notifications for back/forward buttons
        context.coordinator.setupNotifications(webView: webView)

        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url == nil {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        // Update theme when color scheme changes
        let themeUpdateScript = """
        (function() {
            const isDark = '\(colorScheme == .dark ? "true" : "false")' === 'true';
            
            document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
            
            if (isDark) {
                document.documentElement.classList.add('dark');
                document.body.classList.add('dark');
            } else {
                document.documentElement.classList.remove('dark');
                document.body.classList.remove('dark');
            }
            
            document.documentElement.style.setProperty('--app-theme', isDark ? 'dark' : 'light');
            
            window.dispatchEvent(new CustomEvent('themeChange', { 
                detail: { theme: isDark ? 'dark' : 'light' } 
            }));
            
            window.APP_THEME = isDark ? 'dark' : 'light';
        })();
        """
        
        webView.evaluateJavaScript(themeUpdateScript) { _, error in
            if let error = error {
                print("Theme update error: \(error)")
            }
        }
        
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func setupNotifications(webView: WKWebView) {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("WebViewGoBack"),
                object: nil,
                queue: .main
            ) { _ in
                webView.goBack()
            }
            
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("WebViewGoForward"),
                object: nil,
                queue: .main
            ) { _ in
                webView.goForward()
            }
        }
        
        // MARK: - WKScriptMessageHandler - iOS Bridge
        // This receives messages from the web app
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "openRedeemModal" else { return }
            
            debugPrint("🌉 iOS Bridge: Received message from web to open redeem modal")
            
            // Parse the message body and extract code
            var extractedCode: String? = nil
            if let messageBody = message.body as? [String: Any] {
                debugPrint("🌉 iOS Bridge: Message body: \(messageBody)")
                
                // Extract optional prefill code
                if let code = messageBody["code"] as? String {
                    debugPrint("🌉 iOS Bridge: Prefill code: \(code)")
                    extractedCode = code
                }
            }
            
            // Show modal on main thread with the extracted code
            DispatchQueue.main.async {
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                debugPrint("✅ iOS Bridge: About to show modal with prefill: \(extractedCode ?? "none")")
                
                // Create the item which will trigger the sheet to appear
                self.parent.activationCodeItem = ActivationCodeItem(code: extractedCode)
            }
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

// MARK: - Web View Sheet Modifier

struct WebViewSheet: ViewModifier {
    let url: URL?
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                if let url = url {
                    InAppWebView(url: url)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.hidden)
                        .interactiveDismissDisabled(false)
                }
            }
    }
}

extension View {
    func webViewSheet(url: URL?, isPresented: Binding<Bool>) -> some View {
        modifier(WebViewSheet(url: url, isPresented: isPresented))
    }
}
