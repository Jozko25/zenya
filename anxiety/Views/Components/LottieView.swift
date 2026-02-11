//
//  LottieView.swift
//  anxiety
//
//  SwiftUI wrapper for Lottie animations using lottie-ios
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode
    let contentMode: UIView.ContentMode
    let animationSpeed: CGFloat
    
    init(
        animationName: String,
        loopMode: LottieLoopMode = .loop,
        contentMode: UIView.ContentMode = .scaleAspectFit,
        animationSpeed: CGFloat = 1.0
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.contentMode = contentMode
        self.animationSpeed = animationSpeed
    }
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.contentMode = contentMode
        animationView.backgroundBehavior = .pauseAndRestore
        
        // Try loading animation
        var animation: LottieAnimation?
        
        // First try loading directly if full name with extension is provided
        if let url = Bundle.main.url(forResource: animationName, withExtension: nil) {
            animation = LottieAnimation.filepath(url.path)
            debugPrint("✅ Loaded animation from: \(url.path)")
        } else if let path = Bundle.main.path(forResource: animationName, ofType: "json") {
            animation = LottieAnimation.filepath(path)
            debugPrint("✅ Loaded .json animation from: \(path)")
        } else if let path = Bundle.main.path(forResource: animationName, ofType: "lottie") {
            animation = LottieAnimation.filepath(path)
            debugPrint("✅ Loaded .lottie animation from: \(path)")
        } else {
            debugPrint("❌ Could not find animation: \(animationName)")
            debugPrint("📁 Bundle path: \(Bundle.main.bundlePath)")
            if let resourcePath = Bundle.main.resourcePath {
                debugPrint("📂 Resources: \(resourcePath)")
            }
        }
        
        animationView.animation = animation
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        
        if animation != nil {
            animationView.play()
        }
        
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        // Update if needed
    }
}

