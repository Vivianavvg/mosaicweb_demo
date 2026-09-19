import SwiftUI

/// Native SwiftUI translation of the pink-salt treatment using Mosaic's palette.
struct MosaicPaletteBackground: View {
    var opacity: Double = 0.3

    var body: some View {
        ZStack {
            Color.white

            LinearGradient(
                colors: Color.mosaicHomeGradientColors.map { $0.opacity(opacity) },
                startPoint: .top,
                endPoint: .bottom
            )

            // Keep the texture subtle, but visible enough to preserve the pink-salt reference.
            MosaicGrainOverlay(opacity: opacity > 0.7 ? 0.035 : 0.018)
        }
        .ignoresSafeArea()
    }
}

/// A tiny deterministic two-tone grain pattern, equivalent to the reference's noise overlay.
private struct MosaicGrainOverlay: View {
    let opacity: Double

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 5
            let columns = Int(size.width / step) + 1
            let rows = Int(size.height / step) + 1

            for row in 0..<rows {
                for column in 0..<columns {
                    let seed = (column * 73 + row * 151 + column * row * 17) % 29
                    guard seed < 9 else { continue }

                    let x = CGFloat(column) * step
                    let y = CGFloat(row) * step
                    let radius: CGFloat = seed % 3 == 0 ? 1.35 : 0.7
                    let dot = CGRect(x: x, y: y, width: radius, height: radius)
                    let grainColor: Color = seed.isMultiple(of: 2) ? .white : .black
                    context.fill(Path(ellipseIn: dot), with: .color(grainColor.opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

typealias MosaicPageBackground = MosaicPaletteBackground
