import SwiftUI

enum ThinkingOrbState {
    case working
    case searching
    case solving
    case listening
    case connecting
    case weaving
    case composing
    case breathing
    case shaping

    var systemImage: String {
        switch self {
        case .working: return "gearshape.2"
        case .searching: return "magnifyingglass"
        case .solving: return "wand.and.stars"
        case .listening: return "waveform"
        case .connecting: return "arrow.triangle.2.circlepath"
        case .weaving: return "square.grid.2x2"
        case .composing: return "pencil"
        case .breathing: return "sparkles"
        case .shaping: return "circle.hexagongrid"
        }
    }

    var colors: [Color] {
        switch self {
        case .listening:
            return [Color(hex: "3423A6"), Color(hex: "7180B9"), Color(hex: "DFF3E4")]
        case .solving, .working:
            return [Color(hex: "2E1760"), Color(hex: "3423A6"), Color(hex: "7180B9")]
        default:
            return [Color(hex: "3423A6"), Color(hex: "7180B9"), Color(hex: "DFF3E4")]
        }
    }

    var speed: Double {
        switch self {
        case .working, .solving: return 1.3
        case .searching, .connecting, .weaving: return 1.05
        case .listening: return 1.5
        case .composing, .shaping: return 0.9
        case .breathing: return 0.55
        }
    }
}

/// Native SwiftUI equivalent of the Libraries.dev ThinkingOrb effect.
/// The orb gives the assistant a readable state without turning the Home screen into a chat clone.
struct ThinkingOrb: View {
    var state: ThinkingOrbState = .breathing
    var size: CGFloat = 48
    var speed: Double = 1
    var dark: Bool = false
    var paused: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let rawTime = timeline.date.timeIntervalSinceReferenceDate
            let time = paused ? 0 : rawTime * state.speed * speed
            let palette = state.colors
            let breathe = 0.92 + 0.08 * sin(time * 2.4)

            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    let ringScale = 0.72 + CGFloat(index) * 0.12
                    Circle()
                        .stroke(
                            palette[index].opacity(dark ? 0.52 : 0.34),
                            lineWidth: max(1, size * 0.025)
                        )
                        .frame(width: size * ringScale, height: size * ringScale)
                        .scaleEffect(1 + 0.06 * sin(time * (1.2 + Double(index) * 0.3) + Double(index)))
                        .rotationEffect(.degrees(time * (18 + Double(index) * 12)))
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                palette.first?.opacity(dark ? 0.96 : 0.88) ?? Color.mosaicViolet,
                                palette.dropFirst().first?.opacity(0.72) ?? Color.mosaicSubtle,
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.48
                        )
                    )
                    .frame(width: size * 0.68, height: size * 0.68)
                    .scaleEffect(breathe)
                    .blur(radius: size * 0.05)

                Image(systemName: state.systemImage)
                    .font(.system(size: size * 0.24, weight: .semibold))
                    .foregroundStyle(dark ? Color.white : Color.mosaicInk)
            }
            .frame(width: size, height: size)
        }
        .accessibilityLabel("Mosaic assistant (String(describing: state))")
    }
}
