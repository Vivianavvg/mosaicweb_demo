import SwiftUI

@main
struct MosaicApp: App {
    init() {
        MosaicFont.registerBundledFonts()

        let ink = UIColor(red: 23 / 255, green: 23 / 255, blue: 56 / 255, alpha: 1)
        let violet = UIColor(red: 52 / 255, green: 35 / 255, blue: 166 / 255, alpha: 1)
        let titleFont = UIFont(name: MosaicFont.mediumName, size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)
        let largeFont = UIFont(name: MosaicFont.mediumName, size: 32) ?? .systemFont(ofSize: 32, weight: .semibold)

        if #available(iOS 26.0, *) {
            // Leave navigation and tab bars to the system Liquid Glass layer.
            UINavigationBar.appearance().tintColor = violet
        } else {
            let nav = UINavigationBarAppearance()
            nav.configureWithDefaultBackground()
            nav.titleTextAttributes = [.foregroundColor: ink, .font: titleFont]
            nav.largeTitleTextAttributes = [.foregroundColor: ink, .font: largeFont]
            UINavigationBar.appearance().standardAppearance = nav
            UINavigationBar.appearance().scrollEdgeAppearance = nav
            UINavigationBar.appearance().compactAppearance = nav
            UINavigationBar.appearance().tintColor = violet

            let tab = UITabBarAppearance()
            tab.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = tab
            UITabBar.appearance().scrollEdgeAppearance = tab
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}
