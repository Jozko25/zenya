//
//  FontLoader.swift
//  anxiety
//
//  Handles font loading and prevents duplicate registration warnings
//

import UIKit

class FontLoader {
    static let shared = FontLoader()
    private var loadedFonts: Set<String> = []
    
    private init() {
        loadCustomFonts()
    }
    
    private func loadCustomFonts() {
        let fontNames = [
            "Raleway-Light",
            "Raleway-Regular",
            "Raleway-Medium",
            "Raleway-SemiBold",
            "Raleway-Bold"
        ]
        
        for fontName in fontNames {
            if UIFont.fontNames(forFamilyName: "Raleway").contains(fontName) {
                loadedFonts.insert(fontName)
            }
        }
        
        if !loadedFonts.isEmpty {
            debugPrint("✅ Loaded \(loadedFonts.count) Raleway fonts")
        }
    }
    
    func isFontLoaded(_ fontName: String) -> Bool {
        return loadedFonts.contains(fontName)
    }
}
