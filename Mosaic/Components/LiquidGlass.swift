import SwiftUI

// MARK: - Apple Liquid Glass (light canvas, iOS 26 API when present)

public struct LiquidGlassModifier: ViewModifier {
    public var tint: Color
    public var cornerRadius: CGFloat
    public var borderOpacity: CGFloat
    public var material: Material
    public var shadowRadius: CGFloat

    public init(
        tint: Color = .clear,
        cornerRadius: CGFloat = 24,
        borderOpacity: CGFloat = 0.7,
        material: Material = .ultraThinMaterial,
        shadowRadius: CGFloat = 18
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
        self.material = material
        self.shadowRadius = shadowRadius
    }

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(tint == .clear ? nil : tint), in: shape)
                .shadow(
                    color: Color.black.opacity(shadowRadius > 0 ? 0.07 : 0),
                    radius: shadowRadius,
                    x: 0,
                    y: shadowRadius > 0 ? 8 : 0
                )
        } else {
            content
                .background(glassLayers(in: shape))
                .clipShape(shape)
                .shadow(
                    color: Color.black.opacity(shadowRadius > 0 ? 0.07 : 0),
                    radius: shadowRadius,
                    x: 0,
                    y: shadowRadius > 0 ? 8 : 0
                )
        }
    }

    private func glassLayers(in shape: RoundedRectangle) -> some View {
        ZStack {
            shape.fill(material)
            shape.fill(Color.white.opacity(0.62))
            if tint != .clear {
                shape.fill(
                    LinearGradient(
                        colors: [tint.opacity(0.10), tint.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            shape.fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.55), Color.white.opacity(0.08), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            shape.strokeBorder(
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(borderOpacity), location: 0),
                        .init(color: Color.white.opacity(0.35), location: 0.45),
                        .init(color: Color.black.opacity(0.06), location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.8
            )
        }
    }
}

public extension View {
    func liquidGlass(
        tint: Color = .clear,
        cornerRadius: CGFloat = 24,
        borderOpacity: CGFloat = 0.7,
        material: Material = .ultraThinMaterial,
        shadowRadius: CGFloat = 18
    ) -> some View {
        modifier(
            LiquidGlassModifier(
                tint: tint,
                cornerRadius: cornerRadius,
                borderOpacity: borderOpacity,
                material: material,
                shadowRadius: shadowRadius
            )
        )
    }

    func glassEffect(
        tint: Color = .clear,
        cornerRadius: CGFloat = 24
    ) -> some View {
        liquidGlass(tint: tint, cornerRadius: cornerRadius)
    }
}

public struct LiquidGlassCard<Content: View>: View {
    public let tint: Color
    public let cornerRadius: CGFloat
    public let borderOpacity: CGFloat
    public let contentPadding: CGFloat
    public let content: Content

    public init(
        tint: Color = .clear,
        cornerRadius: CGFloat = 24,
        borderOpacity: CGFloat = 0.7,
        contentPadding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
        self.contentPadding = contentPadding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(contentPadding)
            .liquidGlass(
                tint: tint,
                cornerRadius: cornerRadius,
                borderOpacity: borderOpacity,
                shadowRadius: 14
            )
    }
}

public struct LiquidGlassButtonStyle: ButtonStyle {
    public var tint: Color
    public var cornerRadius: CGFloat
    public var isProminent: Bool

    public init(tint: Color = .mosaicInk, cornerRadius: CGFloat = 100, isProminent: Bool = false) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.isProminent = isProminent
    }

    public func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .glassEffect(
                    .regular
                        .tint(isProminent ? tint : nil)
                        .interactive(),
                    in: Capsule(style: .continuous)
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        } else {
            configuration.label
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background {
                    if isProminent {
                        Capsule(style: .continuous)
                            .fill(tint.opacity(configuration.isPressed ? 0.82 : 1))
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.32), lineWidth: 0.8)
                            }
                    } else {
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.55))
                            }
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.7), lineWidth: 0.8)
                            }
                    }
                }
                .clipShape(Capsule(style: .continuous))
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

public extension ButtonStyle where Self == LiquidGlassButtonStyle {
    static var liquidGlass: LiquidGlassButtonStyle { LiquidGlassButtonStyle() }
    static func liquidGlass(tint: Color = .mosaicInk, cornerRadius: CGFloat = 100, isProminent: Bool = false) -> LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(tint: tint, cornerRadius: cornerRadius, isProminent: isProminent)
    }
}

public struct LiquidGlassBackground: View {
    public var showsHero: Bool = true

    public init(showsHero: Bool = true) {
        self.showsHero = showsHero
    }

    public var body: some View {
        ZStack {
            Color.mosaicPage.ignoresSafeArea()

            if showsHero {
                LinearGradient(
                    stops: [
                        .init(color: Color.mosaicHeroTop, location: 0),
                        .init(color: Color.mosaicHeroMid, location: 0.38),
                        .init(color: Color.mosaicHeroMint, location: 0.72),
                        .init(color: Color.mosaicPage, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 420)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(edges: .top)
            }
        }
    }
}

public struct LiquidGlassBadge: View {
    public let text: String
    public let icon: String?
    public let tint: Color

    public init(text: String, icon: String? = nil, tint: Color = .mosaicInk) {
        self.text = text
        self.icon = icon
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(MosaicFont.medium(10))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .liquidGlass(tint: tint, cornerRadius: 100, borderOpacity: 0.8, shadowRadius: 0)
    }
}
