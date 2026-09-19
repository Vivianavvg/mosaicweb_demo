import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Women-Centered Restorative Color Palette (Inspired by Ellevest & Trauma-Informed UX)
    // Deep calming amethyst & midnight velvet background
    public static let mosaicNavy = Color(hex: "13101E")
    public static let mosaicDarkBg = Color(hex: "1A142A")
    public static let mosaicCardBg = Color(hex: "241D38")
    public static let mosaicCardBorder = Color.white.opacity(0.12)

    // Warm, empowering accents
    public static let mosaicAccent = Color(hex: "F472B6") // Soft warm rose gold
    public static let mosaicRoseGold = Color(hex: "FB7185") // Luminous coral blush
    public static let mosaicTeal = Color(hex: "34D399") // Calming sage/seafoam for restored safety
    public static let mosaicIndigo = Color(hex: "A78BFA") // Soft lavender / lilac
    public static let mosaicAmber = Color(hex: "FBBF24") // Warm honey champagne for attention
    public static let mosaicRose = Color(hex: "F43F5E") // Soft berry warning
    public static let mosaicMuted = Color(hex: "C4B5FD") // Gentle pearl lilac for secondary text
    public static let mosaicTextPrimary = Color(hex: "FAF5FF") // Crisp warm white
}
