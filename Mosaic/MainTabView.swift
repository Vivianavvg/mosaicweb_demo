import SwiftUI

struct MainTabView: View {
    let onLogout: () -> Void

    @State private var selectedTab: Int = {
        if CommandLine.arguments.contains("--tab=1") { return 1 }
        if CommandLine.arguments.contains("--tab=2") { return 2 }
        if CommandLine.arguments.contains("--tab=3") { return 3 }
        if CommandLine.arguments.contains("--tab=4") { return 3 }
        return 0
    }()

    init(onLogout: @escaping () -> Void) {
        self.onLogout = onLogout
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            OverviewView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            RecoveryView()
                .tabItem { Label("Letters", systemImage: "envelope.fill") }
                .tag(1)

            LearnView()
                .tabItem { Label("Learn", systemImage: "book.closed.fill") }
                .tag(2)

            SettingsView(onLogout: onLogout)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(Color.mosaicViolet)
        .mosaicSystemTabBar()
    }
}

private extension View {
    @ViewBuilder
    func mosaicSystemTabBar() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}
