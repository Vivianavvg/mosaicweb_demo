import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    let onLogout: () -> Void

    @State private var notificationWording: String = "Discreet ('Mosaic update')"
    @State private var showDeleteConfirm: Bool = false
    @State private var toastMessage: String? = nil
    @State private var isDevToolsExpanded = false

    private var initials: String {
        let name = appState.userName ?? "Mosaic"
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "M" : String(letters)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mosaicPage.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Text("Settings")
                                        .font(MosaicFont.medium(28))
                                        .foregroundColor(Color.mosaicInk)
                                    Spacer()
                                    QuickExitButton()
                                }

                                if let toast = toastMessage {
                                    Text(toast)
                                        .font(MosaicFont.medium(13))
                                        .foregroundColor(Color.mosaicTeal)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .liquidGlass(cornerRadius: 16, shadowRadius: 0)
                                }

                                Text("Privacy")
                                    .font(MosaicFont.medium(13))
                                    .tracking(0.6)
                                    .foregroundColor(Color.mosaicMuted)

                                LiquidGlassCard(cornerRadius: 24, contentPadding: 16, shadowRadius: 0) {
                                    VStack(spacing: 14) {
                                        Toggle(isOn: $appState.isBiometricLockEnabled) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("App lock")
                                                    .font(MosaicFont.medium(15))
                                                    .foregroundColor(Color.mosaicInk)
                                                Text("Face ID whenever you leave the app")
                                                    .font(MosaicFont.regular(12))
                                                    .foregroundColor(Color.mosaicMuted)
                                            }
                                        }
                                        .tint(Color.mosaicInk)

                                        Divider().background(Color.mosaicLine)

                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Notification wording")
                                                    .font(MosaicFont.medium(15))
                                                    .foregroundColor(Color.mosaicInk)
                                                Text("Hide details from the lock screen")
                                                    .font(MosaicFont.regular(12))
                                                    .foregroundColor(Color.mosaicMuted)
                                            }
                                            Spacer()
                                            Menu {
                                                Button("Discreet ('Mosaic update')") { notificationWording = "Discreet ('Mosaic update')" }
                                                Button("Off (No notifications)") { notificationWording = "Off (No notifications)" }
                                            } label: {
                                                Text(notificationWording)
                                                    .font(MosaicFont.medium(11))
                                                    .foregroundColor(Color.mosaicSubtle)
                                            }
                                        }
                                    }
                                }

                                Text("Emergency")
                                    .font(MosaicFont.medium(13))
                                    .tracking(0.6)
                                    .foregroundColor(Color.mosaicMuted)

                                LiquidGlassCard(cornerRadius: 24, contentPadding: 16, shadowRadius: 0) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Erase stored reports")
                                            .font(MosaicFont.medium(15))
                                            .foregroundColor(Color.mosaicInk)
                                        Text("Removes local drafts, packets, and caches from this iPhone. This cannot be undone.")
                                            .font(MosaicFont.regular(12))
                                            .foregroundColor(Color.mosaicMuted)
                                        Button { showDeleteConfirm = true } label: {
                                            Text("Emergency wipe")
                                                .font(MosaicFont.medium(14))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(Color.mosaicRose)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }

                                Text("Account")
                                    .font(MosaicFont.medium(13))
                                    .tracking(0.6)
                                    .foregroundColor(Color.mosaicMuted)

                                LiquidGlassCard(cornerRadius: 24, contentPadding: 16, shadowRadius: 0) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 12) {
                                            Text(initials)
                                                .font(MosaicFont.medium(14))
                                                .foregroundColor(.white)
                                                .frame(width: 40, height: 40)
                                                .background(Color.mosaicInk)
                                                .clipShape(Circle())
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(appState.userName ?? "Mosaic User")
                                                    .font(MosaicFont.medium(15))
                                                    .foregroundColor(Color.mosaicInk)
                                                Text(appState.userEmail ?? "No email added")
                                                    .font(MosaicFont.regular(12))
                                                    .foregroundColor(Color.mosaicMuted)
                                            }
                                            Spacer()
                                            if appState.isDemoMode { SyntheticBadge() }
                                        }
                                        Button {
                                            if appState.isDemoMode {
                                                appState.isDemoMode = false
                                                appState.isAuthenticated = false
                                            } else {
                                                onLogout()
                                            }
                                        } label: {
                                            Text("Sign out")
                                                .font(MosaicFont.medium(14))
                                                .foregroundColor(Color.mosaicRose)
                                        }
                                    }
                                }

                                LiquidGlassCard(cornerRadius: 24, contentPadding: 16, shadowRadius: 0) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                isDevToolsExpanded.toggle()
                                            }
                                        } label: {
                                            HStack(spacing: 12) {
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text("Dev tools")
                                                        .font(MosaicFont.medium(15))
                                                        .foregroundColor(Color.mosaicInk)
                                                    Text("Connected services and integrations")
                                                        .font(MosaicFont.regular(12))
                                                        .foregroundColor(Color.mosaicMuted)
                                                }
                                                Spacer()
                                                Image(systemName: isDevToolsExpanded ? "chevron.up" : "chevron.down")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(Color.mosaicSubtle)
                                            }
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)

                                        if isDevToolsExpanded {
                                            Divider().background(Color.mosaicLine)
                                            VStack(spacing: 12) {
                                                IntegrationRow(name: "Auth0", status: "Active")
                                                IntegrationRow(name: "Mosaic AI · Backboard + Gemini", status: "Active")
                                            }
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                        }
                                    }
                                }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 80)
                }
            }
            .navigationBarHidden(true)
            .confirmationDialog("Delete all local data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Wipe all data", role: .destructive) {
                    appState.deleteAllData()
                    showToast("All local records erased.")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes credit documents, drafts, and caches from this iPhone.")
            }
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { toastMessage = nil }
        }
    }
}

private struct IntegrationRow: View {
    let name: String
    let status: String

    var body: some View {
        HStack {
            Text(name)
                .font(MosaicFont.medium(14))
                .foregroundColor(Color.mosaicInk)
            Spacer()
            Text(status.uppercased())
                .font(MosaicFont.medium(10))
                .tracking(0.6)
                .foregroundColor(Color.mosaicMuted)
        }
    }
}
