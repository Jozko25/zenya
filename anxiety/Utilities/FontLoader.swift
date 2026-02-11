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
        // Check Raleway fonts
        let ralewayFonts = UIFont.fontNames(forFamilyName: "Raleway")
        for fontName in ralewayFonts {
            loadedFonts.insert(fontName)
        }

        // Check Quicksand fonts
        let quicksandFonts = UIFont.fontNames(forFamilyName: "Quicksand")
        for fontName in quicksandFonts {
            loadedFonts.insert(fontName)
        }

        // Check Instrument Serif fonts
        let instrumentSerifFonts = UIFont.fontNames(forFamilyName: "Instrument Serif")
        for fontName in instrumentSerifFonts {
            loadedFonts.insert(fontName)
        }

        debugPrint("✅ Loaded fonts: \(loadedFonts)")

        // Debug: Print all available font families
        #if DEBUG
        if instrumentSerifFonts.isEmpty {
            debugPrint("⚠️ Instrument Serif not found. Available families:")
            for family in UIFont.familyNames.sorted() {
                let names = UIFont.fontNames(forFamilyName: family)
                if !names.isEmpty {
                    debugPrint("  - \(family): \(names)")
                }
            }
        }
        #endif
    }

    func isFontLoaded(_ fontName: String) -> Bool {
        return loadedFonts.contains(fontName)
    }
}
