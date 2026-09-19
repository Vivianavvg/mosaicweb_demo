import SwiftUI
import Auth0

struct MainTabView: View {
    let user: UserInfo?
    let onLogout: () -> Void
    let webAuth: () -> WebAuth

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            OverviewView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Overview")
                }
                .tag(0)

            ScanView()
                .tabItem {
                    Image(systemName: "doc.viewfinder.fill")
                    Text("Scan")
                }
                .tag(1)

            RecoveryView()
                .tabItem {
                    Image(systemName: "shield.lefthalf.filled")
                    Text("Recovery")
                }
                .tag(2)

            LearnView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Learn")
                }
                .tag(3)

            SettingsView(onLogout: onLogout)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
        }
        .tint(Color.mosaicAccent)
        .toolbarBackground(Color.mosaicNavy, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
