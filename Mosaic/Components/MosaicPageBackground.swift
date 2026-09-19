import SwiftUI

/// A low-contrast version of the Home palette for secondary screens.
struct MosaicPageBackground: View {
    var opacity: Double = 0.3

    var body: some View {
        LinearGradient(
            colors: Color.mosaicHomeGradientColors.map { $0.opacity(opacity) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .background(Color.white)
        .ignoresSafeArea()
    }
}
