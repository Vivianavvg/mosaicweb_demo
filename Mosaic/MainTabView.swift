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

            // Frosted Floating Liquid Glass Tab Bar
            HStack(spacing: 4) {
                LiquidGlassTabButton(
                    icon: "house.fill",
                    title: "Overview",
                    isSelected: selectedTab == 0
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = 0
                    }
                }

                LiquidGlassTabButton(
                    icon: "doc.viewfinder.fill",
                    title: "Scan",
                    isSelected: selectedTab == 1
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = 1
                    }
                }

                LiquidGlassTabButton(
                    icon: "shield.lefthalf.filled",
                    title: "Recovery",
                    isSelected: selectedTab == 2
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = 2
                    }
                }

                LiquidGlassTabButton(
                    icon: "book.fill",
                    title: "Learn",
                    isSelected: selectedTab == 3
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = 3
                    }
                }

                LiquidGlassTabButton(
                    icon: "gearshape.fill",
                    title: "Settings",
                    isSelected: selectedTab == 4
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = 4
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.mosaicNavy.opacity(0.4),
                                    Color.mosaicNavy.opacity(0.65)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.45), location: 0),
                                    .init(color: Color.mosaicAccent.opacity(0.3), location: 0.35),
                                    .init(color: Color.white.opacity(0.12), location: 0.8),
                                    .init(color: Color.white.opacity(0.25), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 6)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

private struct LiquidGlassTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? Color.mosaicAccent : Color.mosaicMuted)

                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : Color.mosaicMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.mosaicAccent.opacity(0.22),
                                        Color.mosaicAccent.opacity(0.06)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.mosaicAccent.opacity(0.5),
                                                Color.mosaicAccent.opacity(0.15)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    } else {
                        Color.clear
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

