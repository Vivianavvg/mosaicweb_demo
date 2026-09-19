import SwiftUI
import Auth0

struct MainTabView: View {
    let user: UserInfo?
    let onLogout: () -> Void
    let webAuth: () -> WebAuth

    @State private var selectedTab: Int = {
        if CommandLine.arguments.contains("--tab=1") { return 1 }
        if CommandLine.arguments.contains("--tab=2") { return 2 }
        if CommandLine.arguments.contains("--tab=3") { return 3 }
        if CommandLine.arguments.contains("--tab=4") { return 4 }
        return 0
    }()

    init(user: UserInfo?, onLogout: @escaping () -> Void, webAuth: @escaping () -> WebAuth) {
        self.user = user
        self.onLogout = onLogout
        self.webAuth = webAuth
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                OverviewView(selectedTab: $selectedTab)
                    .tag(0)
                ScanView()
                    .tag(1)
                RecoveryView()
                    .tag(2)
                LearnView()
                    .tag(3)
                SettingsView(onLogout: onLogout)
                    .tag(4)
            }

            HStack(spacing: 0) {
                tabButton(icon: "house.fill", outline: "house", index: 0)
                tabButton(icon: "chart.bar.fill", outline: "chart.bar", index: 1)
                tabButton(icon: "arrow.left.arrow.right", outline: "arrow.left.arrow.right", index: 2)
                tabButton(icon: "book.fill", outline: "book", index: 3)
                tabButton(icon: "gearshape.fill", outline: "gearshape", index: 4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .liquidGlass(cornerRadius: 32, shadowRadius: 20)
            .padding(.horizontal, 28)
            .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private func tabButton(icon: String, outline: String, index: Int) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: selectedTab == index ? icon : outline)
                    .font(.system(size: 18, weight: selectedTab == index ? .semibold : .regular))
                    .foregroundColor(selectedTab == index ? Color.mosaicInk : Color.mosaicMuted)
                Circle()
                    .fill(selectedTab == index ? Color.mosaicInk : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(["Overview", "Scan", "Recovery", "Learn", "Settings"][index])
    }
}
