import SwiftUI

enum BorderBeamSize {
    case md
    case sm
    case line
    case pulseInner
    case pulseOutside

    var lineWidth: CGFloat {
        switch self {
        case .md: return 1.35
        case .sm: return 1
        case .line: return 0.8
        case .pulseInner: return 1.1
        case .pulseOutside: return 1.6
        }
    }

    var blurRadius: CGFloat {
        switch self {
        case .md: return 5
        case .sm: return 3
        case .line: return 2
        case .pulseInner: return 4
        case .pulseOutside: return 8
        }
    }
}

enum BorderBeamColorVariant {
    case colorful
    case mono
    case ocean
    case sunset

    var colors: [Color] {
        switch self {
        case .colorful:
            return [
                Color(hex: "3423A6"),
                Color(hex: "7180B9"),
                Color(hex: "DFF3E4"),
                Color(hex: "2E1760"),
                Color(hex: "3423A6")
            ]
        case .mono:
            return [Color.mosaicInk, Color.mosaicSubtle, Color.white, Color.mosaicInk]
        case .ocean:
            return [Color(hex: "3423A6"), Color(hex: "7180B9"), Color(hex: "DFF3E4"), Color(hex: "3423A6")]
        case .sunset:
            return [Color(hex: "2E1760"), Color(hex: "7180B9"), Color(hex: "DFF3E4"), Color(hex: "3423A6")]
        }
    }
}

enum BorderBeamTheme {
    case light
    case dark
}

/// Native SwiftUI equivalent of the Libraries.dev BorderBeam effect.
/// It keeps the animation local and dependency-free for the iOS app.
struct BorderBeam<Content: View>: View {
    var size: BorderBeamSize = .md
    var colorVariant: BorderBeamColorVariant = .colorful
    var strength: CGFloat = 0.7
    var active: Bool = true
    var theme: BorderBeamTheme = .light
    var cornerRadius: CGFloat = 24

    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .overlay {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let time = active ? timeline.date.timeIntervalSinceReferenceDate : 0
                    let pulse = 0.78 + 0.22 * sin(time * 2.1)
                    let opacity = active ? min(1, max(0, strength)) * pulse : 0
                    let gradient = AngularGradient(
                        colors: colorVariant.colors,
                        center: .center,
                        angle: .degrees(time * 48)
                    )

                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(gradient, lineWidth: size.lineWidth * 2.8)
                            .blur(radius: size.blurRadius)
                            .opacity(opacity * (theme == .dark ? 0.76 : 0.58))

                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(gradient, lineWidth: size.lineWidth)
                            .opacity(opacity)
                    }
                }
                .allowsHitTesting(false)
            }
    }
}
