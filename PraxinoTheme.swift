import SwiftUI

extension Color {
    static let praxinoTheme = PraxinoTheme()
}

struct PraxinoTheme {
    // Base Palette
    let brandBlue = Color(hex: 0x4693D5)
    let appGreen = Color(hex: 0x92FC60)
    let appGreen2 = Color(hex: 0x8AD64E)
    let mediumGrey = Color(hex: 0xB3B3B3)
    let mediumGrey2 = Color(hex: 0x5A5A5A)
    let appBlack = Color(hex: 0x000000)
    let appLightGrey = Color(hex: 0xFAF9F6)
    let appWhite = Color(hex: 0xFFFFFF)
    let appDarkGrey = Color(hex: 0x121212)
    let poisonPill = Color(hex: 0xFF0202)  // AppRed
    
    // Helper for dynamic UI colors
    private func dynamicColor(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
    
    // Semantic Colors (Mapped dynamically for Light/Dark mode)
    var background: Color { brandBlue }
    var surface: Color { dynamicColor(light: appLightGrey, dark: appDarkGrey) }
    var textPrimary: Color { dynamicColor(light: appBlack, dark: appWhite) }
    var textSecondary: Color { dynamicColor(light: mediumGrey2, dark: mediumGrey) }
    var textAccent: Color { dynamicColor(light: Color(hex: 0x2A7512), dark: appGreen) }
    var trackInactive: Color { dynamicColor(light: Color(hex: 0xE5E5E5), dark: mediumGrey) }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
