import SwiftUI

@main
struct MosaicApp: App {
    init() {
        MosaicFont.registerBundledFonts()

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor.white
        nav.titleTextAttributes = [
            .foregroundColor: UIColor(red: 23 / 255, green: 23 / 255, blue: 56 / 255, alpha: 1),
            .font: UIFont(name: MosaicFont.mediumName, size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor(red: 23 / 255, green: 23 / 255, blue: 56 / 255, alpha: 1),
            .font: UIFont(name: MosaicFont.mediumName, size: 32) ?? .systemFont(ofSize: 32, weight: .semibold)
        ]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(red: 52 / 255, green: 35 / 255, blue: 166 / 255, alpha: 1)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}
