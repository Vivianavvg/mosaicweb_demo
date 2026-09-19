import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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

    // MARK: - Reference fintech canvas (light, shadcn zinc + mint hero)

    public static let mosaicPage = Color(hex: "F4F5F7")
    public static let mosaicSheet = Color(hex: "FFFFFF")
    public static let mosaicFill = Color(hex: "F3F4F6")
    public static let mosaicInk = Color(hex: "111111")
    public static let mosaicSubtle = Color(hex: "6B7280")
    public static let mosaicLine = Color(hex: "E5E7EB")
    public static let mosaicHeroTop = Color(hex: "0B3A46")
    public static let mosaicHeroMid = Color(hex: "2A7A78")
    public static let mosaicHeroMint = Color(hex: "C8EBE4")

    public static let mosaicNavy = Color(hex: "0B3A46")
    public static let mosaicDarkBg = Color(hex: "F4F5F7")
    public static let mosaicCardBg = Color(hex: "FFFFFF")
    public static let mosaicCardBorder = Color(hex: "E5E7EB")
    public static let mosaicAccent = Color(hex: "111111")
    public static let mosaicRoseGold = Color(hex: "0F766E")
    public static let mosaicTeal = Color(hex: "0F766E")
    public static let mosaicIndigo = Color(hex: "334155")
    public static let mosaicAmber = Color(hex: "B45309")
    public static let mosaicRose = Color(hex: "E11D48")
    public static let mosaicMuted = Color(hex: "9CA3AF")
    public static let mosaicTextPrimary = Color(hex: "111111")
}
