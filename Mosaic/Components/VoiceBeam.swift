import SwiftUI

enum VoiceBeamType: String {
    case `default`
    case pill
    case mobile
}

enum VoiceBeamColorVariant: String {
    case colorful, mono, ocean, sunset, forest, candy, ice, gold
}

/// Native port of Libraries.dev `voice-glow` / `VoiceBeam`.
/// Wraps a child and paints a sound-reactive glow along its bottom edge.
struct VoiceBeam<Content: View>: View {
    var type: VoiceBeamType = .mobile
    var level: CGFloat = 0
    var processing: Bool = false
    var colorVariant: VoiceBeamColorVariant = .colorful
    var strength: CGFloat = 0.92
    var reach: CGFloat = 1
    var spread: CGFloat = 1
    var idle: CGFloat = 0.18

    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .overlay(alignment: .bottom) {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { context, size in
                        drawGlow(in: &context, size: size, time: t)
                    }
                }
                .frame(height: glowHeight)
                .blur(radius: type == .pill ? 10 : 16)
                .opacity(strength)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottom) {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { context, size in
                        drawCore(in: &context, size: size, time: t)
                    }
                }
                .frame(height: glowHeight * 0.55)
                .opacity(min(1, strength + 0.08))
                .allowsHitTesting(false)
            }
    }

    private var glowHeight: CGFloat {
        switch type {
        case .pill: return 36
        case .mobile: return 78
        case .default: return 56
        }
    }

    private var colors: [Color] {
        switch colorVariant {
        case .colorful:
            return [
                Color(hex: "FF4D8D"),
                Color(hex: "FF7A45"),
                Color(hex: "FFD24A"),
                Color(hex: "5CFF9A"),
                Color(hex: "3CD4FF"),
                Color(hex: "5B7CFF"),
                Color(hex: "B24CFF")
            ]
        case .mono:
            return [Color.mosaicInk, Color.mosaicSubtle, Color.white]
        case .ocean:
            return [Color(hex: "3423A6"), Color(hex: "7180B9"), Color(hex: "3CD4FF"), Color(hex: "DFF3E4")]
        case .sunset:
            return [Color(hex: "FF4D8D"), Color(hex: "FF7A45"), Color(hex: "FFD24A"), Color(hex: "B24CFF")]
        case .forest:
            return [Color(hex: "34D399"), Color(hex: "059669"), Color(hex: "DFF3E4"), Color(hex: "171738")]
        case .candy:
            return [Color(hex: "FF4D8D"), Color(hex: "B24CFF"), Color(hex: "3CD4FF"), Color(hex: "FFD24A")]
        case .ice:
            return [Color(hex: "E0F2FE"), Color(hex: "3CD4FF"), Color(hex: "7180B9"), Color.white]
        case .gold:
            return [Color(hex: "FBBF24"), Color(hex: "F59E0B"), Color(hex: "FFF7D6"), Color(hex: "171738")]
        }
    }

    private func drawGlow(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let clamped = min(1, max(0, level))
        let breathe = idle + 0.08 * (0.5 + 0.5 * sin(time * 2.2))
        let energy = processing ? 0.72 : max(breathe, clamped)
        let lobes = colors
        let count = max(lobes.count, 3)
        let travel = processing ? 0.5 + 0.42 * sin(time * 2.6) : 0.5

        for (index, color) in lobes.enumerated() {
            let slot = CGFloat(index + 1) / CGFloat(count + 1)
            let x = processing
                ? size.width * (travel + CGFloat(index - count / 2) * 0.035)
                : size.width * (0.22 + slot * 0.56 * spread)
            let bloom = energy * reach
            let width = size.width * (processing ? 0.18 : 0.20 + 0.04 * CGFloat(index % 3)) * spread
            let height = size.height * (0.45 + bloom * 0.7)
            let rect = CGRect(
                x: x - width / 2,
                y: size.height - height,
                width: width,
                height: height * 1.35
            )
            let path = Ellipse().path(in: rect)
            context.fill(path, with: .color(color.opacity(0.22 + energy * 0.38)))
        }
    }

    private func drawCore(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let clamped = min(1, max(0, level))
        let energy = processing ? 0.85 : max(idle, clamped)
        let travel = processing ? 0.5 + 0.38 * sin(time * 2.6) : 0.5
        let width = size.width * (processing ? 0.42 : 0.34 + energy * 0.28) * spread
        let height = size.height * (0.35 + energy * 0.55) * reach
        let x = size.width * travel - width / 2
        let rect = CGRect(x: x, y: size.height - height, width: width, height: height * 1.2)
        let path = Capsule().path(in: rect)
        context.fill(path, with: .color(Color.white.opacity(0.55 + energy * 0.25)))
        if let first = colors.first {
            context.fill(path, with: .color(first.opacity(0.35)))
        }
    }
}
