//
//  Font+App.swift
//  anxiety
//
//  Modern font system using Quicksand (Soft, Rounded, Friendly) for wellness app
//  with Instrument Serif for elegant display typography
//

import SwiftUI

extension Font {
    // MARK: - Instrument Serif Font Family (Display/Headlines)

    static func instrumentSerif(size: CGFloat, italic: Bool = false) -> Font {
        // Try multiple naming conventions iOS might use
        let possibleNames = italic
            ? ["InstrumentSerif-Italic", "Instrument Serif Italic", "InstrumentSerif Italic"]
            : ["InstrumentSerif-Regular", "Instrument Serif Regular", "InstrumentSerif Regular", "Instrument Serif"]

        for fontName in possibleNames {
            if UIFont(name: fontName, size: size) != nil {
                return Font.custom(fontName, size: size)
            }
        }

        // Fallback to system serif
        return Font.system(size: size, weight: .regular, design: .serif)
    }

    // MARK: - Quicksand Font Family (Primary)
    
    static func quicksand(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName: String
        
        switch weight {
        case .ultraLight, .thin, .light:
            fontName = "Quicksand-Light"
        case .regular:
            fontName = "Quicksand-Regular"
        case .medium:
            fontName = "Quicksand-Medium"
        case .semibold:
            fontName = "Quicksand-SemiBold"
        case .bold, .heavy, .black:
            fontName = "Quicksand-Bold"
        default:
            fontName = "Quicksand-Regular"
        }
        
        // Try custom font first, fallback to system font
        if UIFont(name: fontName, size: size) != nil {
            return Font.custom(fontName, size: size)
        } else {
            return Font.system(size: size, weight: weight, design: .rounded)
        }
    }
    
    // MARK: - Raleway Compatibility (Alias to Quicksand)
    // We alias this back to Quicksand since we are replacing Raleway
    static func raleway(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return quicksand(size: size, weight: weight)
    }
    
    // MARK: - Design System Fonts (Quicksand)
    
    static func appTitle() -> Font {
        return quicksand(size: 28, weight: .bold)
    }
    
    static func appTitle2() -> Font {
        return quicksand(size: 24, weight: .bold)
    }
    
    static func appTitle3() -> Font {
        return quicksand(size: 20, weight: .semibold)
    }
    
    static func appHeadline() -> Font {
        return quicksand(size: 18, weight: .semibold)
    }
    
    static func appSubheadline() -> Font {
        return quicksand(size: 16, weight: .medium)
    }
    
    static func appBody() -> Font {
        return quicksand(size: 16, weight: .regular)
    }
    
    static func appCallout() -> Font {
        return quicksand(size: 14, weight: .medium)
    }
    
    static func appCaption() -> Font {
        return quicksand(size: 12, weight: .medium)
    }
    
    static func appCaption2() -> Font {
        return quicksand(size: 10, weight: .medium)
    }
    
    static func appButton() -> Font {
        return quicksand(size: 16, weight: .semibold)
    }
}

// MARK: - UIKit Integration

extension UIFont {
    static func instrumentSerif(size: CGFloat, italic: Bool = false) -> UIFont? {
        let possibleNames = italic
            ? ["InstrumentSerif-Italic", "Instrument Serif Italic", "InstrumentSerif Italic"]
            : ["InstrumentSerif-Regular", "Instrument Serif Regular", "InstrumentSerif Regular", "Instrument Serif"]

        for fontName in possibleNames {
            if let font = UIFont(name: fontName, size: size) {
                return font
            }
        }
        return UIFont.systemFont(ofSize: size)
    }

    static func quicksand(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont? {
        let fontName: String
        
        switch weight {
        case .ultraLight, .thin, .light:
            fontName = "Quicksand-Light"
        case .regular:
            fontName = "Quicksand-Regular"
        case .medium:
            fontName = "Quicksand-Medium"
        case .semibold:
            fontName = "Quicksand-SemiBold"
        case .bold, .heavy, .black:
            fontName = "Quicksand-Bold"
        default:
            fontName = "Quicksand-Regular"
        }
        
        return UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size, weight: weight)
    }
    
    static func raleway(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont? {
        return quicksand(size: size, weight: weight)
    }
}