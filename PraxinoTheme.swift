import SwiftUI

extension Color {
    static let praxinoTheme = PraxinoTheme()
}

struct PraxinoTheme {
    // Mapped 1-to-1 from Android Color.kt
    let background = Color(hex: 0x4693D5)  // BrandBlue
    let surface = Color(hex: 0x121212)     // AppDarkGrey
    let textPrimary = Color(hex: 0xFFFFFF) // AppWhite
    let textSecondary = Color(hex: 0xB3B3B3) // MediumGrey
    
    let brandBlue = Color(hex: 0x4693D5)
    let appGreen = Color(hex: 0x92FC60)
    let appGreen2 = Color(hex: 0x8AD64E)
    let mediumGrey = Color(hex: 0xB3B3B3)
    let mediumGrey2 = Color(hex: 0x5A5A5A)
    let appBlack = Color(hex: 0x000000)
    let appLightGrey = Color(hex: 0xFAF9F6)
    let poisonPill = Color(hex: 0xFF0202)  // AppRed
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
