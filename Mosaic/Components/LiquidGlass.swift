import SwiftUI

// MARK: - Apple Liquid Glass Design System (iOS 16.0+)
// Implements frosted translucency, specular edge reflections, luminous borders,
// and ambient depth blending seamlessly with Mosaic brand colors.

public struct LiquidGlassModifier: ViewModifier {
    public var tint: Color
    public var cornerRadius: CGFloat
    public var borderOpacity: CGFloat
    public var material: Material
    public var shadowRadius: CGFloat

    public init(
        tint: Color = .clear,
        cornerRadius: CGFloat = 16,
        borderOpacity: CGFloat = 0.28,
        material: Material = .ultraThinMaterial,
        shadowRadius: CGFloat = 12
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
        self.material = material
        self.shadowRadius = shadowRadius
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 1. Native frosted ultra-thin material base
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(material)

                    // 2. Liquid glass tint layer (subtle brand wash)
                    if tint != .clear {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tint.opacity(0.14),
                                        tint.opacity(0.04)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    // 3. Ambient inner sheen (subtle brightness gradient)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    Color.white.opacity(0.02),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // 4. Specular edge reflection & luminous border stroke
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(borderOpacity * 1.4), location: 0.0),
                                    .init(color: tint != .clear ? tint.opacity(borderOpacity) : Color.white.opacity(borderOpacity * 0.7), location: 0.35),
                                    .init(color: Color.white.opacity(borderOpacity * 0.25), location: 0.75),
                                    .init(color: Color.white.opacity(borderOpacity * 0.4), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(0.25),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius > 0 ? shadowRadius / 2.5 : 0
            )
    }
}

// MARK: - View Extension
public extension View {
    /// Applies the Apple Liquid Glass frosted material and specular highlights
    func liquidGlass(
        tint: Color = .clear,
        cornerRadius: CGFloat = 16,
        borderOpacity: CGFloat = 0.28,
        material: Material = .ultraThinMaterial,
        shadowRadius: CGFloat = 12
    ) -> some View {
        self.modifier(
            LiquidGlassModifier(
                tint: tint,
                cornerRadius: cornerRadius,
                borderOpacity: borderOpacity,
                material: material,
                shadowRadius: shadowRadius
            )
        )
    }

    /// Alias matching watcher.md specification for `.glassEffect()`
    func glassEffect(
        tint: Color = .clear,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self.liquidGlass(tint: tint, cornerRadius: cornerRadius)
    }
}

// MARK: - Liquid Glass Card Container
public struct LiquidGlassCard<Content: View>: View {
    public let tint: Color
    public let cornerRadius: CGFloat
    public let borderOpacity: CGFloat
    public let contentPadding: CGFloat
    public let content: Content

    public init(
        tint: Color = .clear,
        cornerRadius: CGFloat = 16,
        borderOpacity: CGFloat = 0.28,
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
                borderOpacity: borderOpacity
            )
    }
}

// MARK: - Liquid Glass Button Style
public struct LiquidGlassButtonStyle: ButtonStyle {
    public var tint: Color
    public var cornerRadius: CGFloat
    public var isProminent: Bool

    public init(tint: Color = .mosaicAccent, cornerRadius: CGFloat = 12, isProminent: Bool = false) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.isProminent = isProminent
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    if isProminent {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tint.opacity(configuration.isPressed ? 0.7 : 0.9),
                                        tint.opacity(configuration.isPressed ? 0.5 : 0.75)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(configuration.isPressed ? 0.22 : 0.12))
                    }

                    // Top specular rim
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(configuration.isPressed ? 0.2 : 0.5),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == LiquidGlassButtonStyle {
    static var liquidGlass: LiquidGlassButtonStyle {
        LiquidGlassButtonStyle()
    }
    static func liquidGlass(tint: Color = .mosaicAccent, cornerRadius: CGFloat = 12, isProminent: Bool = false) -> LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(tint: tint, cornerRadius: cornerRadius, isProminent: isProminent)
    }
}

// MARK: - Ambient Liquid Glass Background
/// Provides the luminous canvas with ambient color glows that refract beautifully through `.ultraThinMaterial`.
public struct LiquidGlassBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            // Deep velvet base
            Color.mosaicNavy.ignoresSafeArea()

            // Top-left luminous warm rose & lilac ambient glow
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.mosaicAccent.opacity(0.18),
                                Color.mosaicIndigo.opacity(0.10),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: geo.size.width * 0.75
                        )
                    )
                    .frame(width: geo.size.width * 1.2, height: geo.size.width * 1.2)
                    .offset(x: -geo.size.width * 0.35, y: -geo.size.height * 0.12)
                    .blur(radius: 50)

                // Bottom-right calming sage & warm gold glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.mosaicTeal.opacity(0.14),
                                Color.mosaicAmber.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: geo.size.width * 0.70
                        )
                    )
                    .frame(width: geo.size.width * 1.1, height: geo.size.width * 1.1)
                    .offset(x: geo.size.width * 0.35, y: geo.size.height * 0.50)
                    .blur(radius: 50)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Liquid Glass Badge
public struct LiquidGlassBadge: View {
    public let text: String
    public let icon: String?
    public let tint: Color

    public init(text: String, icon: String? = nil, tint: Color = .mosaicAccent) {
        self.text = text
        self.icon = icon
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .liquidGlass(tint: tint, cornerRadius: 100, borderOpacity: 0.45, shadowRadius: 0)
    }
}

