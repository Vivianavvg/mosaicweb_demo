import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    let onLogout: () -> Void

    @State private var selectedTab: Int = {
        if CommandLine.arguments.contains("--tab=1") { return 1 }
        if CommandLine.arguments.contains("--tab=2") { return 2 }
        if CommandLine.arguments.contains("--tab=3") { return 3 }
        if CommandLine.arguments.contains("--tab=4") { return 3 }
        return 0
    }()
    @State private var homeResetVersion = 0
    @State private var lastHomeTap: Date?

    init(onLogout: @escaping () -> Void) {
        self.onLogout = onLogout
    }

    var body: some View {
        TabView(selection: tabSelection) {
            OverviewView(resetToken: homeResetVersion)
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
        .onChange(of: appState.requestedTabIndex) { requestedTabIndex in
            guard let requestedTabIndex else { return }
            selectedTab = requestedTabIndex
            lastHomeTap = nil
            appState.requestedTabIndex = nil
        }
    }

    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                selectTab(newValue)
            }
        )
    }

    private func selectTab(_ newValue: Int) {
        guard newValue == 0 else {
            selectedTab = newValue
            lastHomeTap = nil
            return
        }

        let now = Date()
        if selectedTab == 0,
           let lastHomeTap,
           now.timeIntervalSince(lastHomeTap) < 0.55 {
            homeResetVersion += 1
            self.lastHomeTap = nil
        } else {
            selectedTab = 0
            lastHomeTap = now
        }
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
