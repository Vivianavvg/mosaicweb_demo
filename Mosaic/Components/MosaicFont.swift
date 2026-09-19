import SwiftUI
import CoreText

enum MosaicFont {
    static let lightName = "NeueMontreal-Light"
    static let lightItalicName = "NeueMontreal-LightItalic"
    static let regularName = "NeueMontreal-Regular"
    static let italicName = "NeueMontreal-Italic"
    static let mediumName = "NeueMontreal-Medium"
    static let mediumItalicName = "NeueMontreal-MediumItalic"
    static let boldName = "NeueMontreal-Bold"
    static let boldItalicName = "NeueMontreal-BoldItalic"

    static func light(_ size: CGFloat) -> Font { .custom(lightName, size: size) }
    static func lightItalic(_ size: CGFloat) -> Font { .custom(lightItalicName, size: size) }
    static func regular(_ size: CGFloat) -> Font { .custom(regularName, size: size) }
    static func italic(_ size: CGFloat) -> Font { .custom(italicName, size: size) }
    static func medium(_ size: CGFloat) -> Font { .custom(mediumName, size: size) }
    static func mediumItalic(_ size: CGFloat) -> Font { .custom(mediumItalicName, size: size) }
    static func bold(_ size: CGFloat) -> Font { .custom(boldName, size: size) }
    static func boldItalic(_ size: CGFloat) -> Font { .custom(boldItalicName, size: size) }

    static func registerBundledFonts() {
        let bundle = Bundle.main
        let urls = [
            bundle.urls(forResourcesWithExtension: "otf", subdirectory: nil) ?? [],
            bundle.urls(forResourcesWithExtension: "otf", subdirectory: "Fonts") ?? [],
            bundle.urls(forResourcesWithExtension: "otf", subdirectory: "Resources/Fonts") ?? []
        ].flatMap { $0 }
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
