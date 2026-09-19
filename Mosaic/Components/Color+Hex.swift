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

    // MARK: - Twilight Purple Dreams palette

    public static let mosaicPage = Color.white
    public static let mosaicSheet = Color(hex: "FFFFFF")
    public static let mosaicFill = Color(hex: "DFF3E4")
    public static let mosaicInk = Color(hex: "171738")
    public static let mosaicSubtle = Color(hex: "7180B9")
    public static let mosaicLine = Color(hex: "E7E4F2")
    public static let mosaicHeroTop = Color(hex: "171738")
    public static let mosaicHeroMid = Color(hex: "3423A6")
    public static let mosaicHeroMint = Color(hex: "DFF3E4")
    public static let mosaicPurple = Color(hex: "2E1760")
    public static let mosaicViolet = Color(hex: "3423A6")
    public static let mosaicMint = Color(hex: "DFF3E4")

    public static let mosaicNavy = Color(hex: "171738")
    public static let mosaicDarkBg = Color.white
    public static let mosaicCardBg = Color(hex: "FFFFFF")
    public static let mosaicCardBorder = Color(hex: "E7E4F2")
    public static let mosaicAccent = Color(hex: "3423A6")
    public static let mosaicRoseGold = Color(hex: "7180B9")
    public static let mosaicTeal = Color(hex: "3423A6")
    public static let mosaicIndigo = Color(hex: "7180B9")
    public static let mosaicAmber = Color(hex: "2E1760")
    public static let mosaicRose = Color(hex: "2E1760")
    public static let mosaicMuted = Color(hex: "7180B9")
    public static let mosaicTextPrimary = Color(hex: "171738")

    // MARK: - Home background palette

    public static let mosaicBlush = Color(hex: "FFD6FF")
    public static let mosaicLavender = Color(hex: "E7C6FF")
    public static let mosaicLilac = Color(hex: "C8B6FF")
    public static let mosaicPeriwinkle = Color(hex: "B8C0FF")
    public static let mosaicSky = Color(hex: "BBD0FF")
    public static let mosaicHomeGradientColors: [Color] = [
        mosaicBlush,
        mosaicLavender,
        mosaicLilac,
        mosaicPeriwinkle,
        mosaicSky
    ]
}
