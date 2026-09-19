import SwiftUI

struct SyntheticBadge: View {
    var text: String = "SYNTHETIC DEMO DATA"

    var body: some View {
        LiquidGlassBadge(text: text, icon: "sparkles", tint: Color.mosaicAmber)
    }
}
