import SwiftUI

@main
struct MosaicApp: App {
    init() {
        MosaicFont.registerBundledFonts()

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(red: 0.957, green: 0.961, blue: 0.969, alpha: 1)
        nav.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.067, green: 0.067, blue: 0.067, alpha: 1),
            .font: UIFont(name: MosaicFont.mediumName, size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor(red: 0.067, green: 0.067, blue: 0.067, alpha: 1),
            .font: UIFont(name: MosaicFont.mediumName, size: 32) ?? .systemFont(ofSize: 32, weight: .semibold)
        ]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(red: 0.067, green: 0.067, blue: 0.067, alpha: 1)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}
