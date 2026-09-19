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

    static let mosaicNavy = Color(hex: "0F172A")
    static let mosaicDarkBg = Color(hex: "111827")
    static let mosaicCardBg = Color(hex: "1F2937")
    static let mosaicCardBorder = Color(hex: "374151")
    static let mosaicAccent = Color(hex: "38BDF8") // calming cyan/sky
    static let mosaicTeal = Color(hex: "2DD4BF")
    static let mosaicIndigo = Color(hex: "6366F1")
    static let mosaicAmber = Color(hex: "F59E0B")
    static let mosaicRose = Color(hex: "F43F5E")
    static let mosaicMuted = Color(hex: "9CA3AF")
}
