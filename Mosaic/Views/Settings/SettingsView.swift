import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    let onLogout: () -> Void

    @State private var notificationWording: String = "Neutral ('Mosaic Update')"
    @State private var showDeleteConfirm: Bool = false
    @State private var showExportSheet: Bool = false
    @State private var exportedDataString: String = ""
    @State private var toastMessage: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Settings & Privacy")
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text("Manage device security, app lock & local storage")
                                .font(.subheadline)
                                .foregroundColor(Color.mosaicMuted)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    if let toast = toastMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.mosaicTeal)
                            Text(toast)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.mosaicTeal.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                    }

                    // Account & Session
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Session & Account")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(spacing: 10) {
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color.mosaicAccent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(appState.userName ?? "Mosaic User")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text(appState.userEmail ?? "demo@hackhers.org")
                                        .font(.caption)
                                        .foregroundColor(Color.mosaicMuted)
                                }
                                Spacer()
                                if appState.isDemoMode {
                                    SyntheticBadge()
                                }
                            }
                            .padding(14)
                            .background(Color.mosaicCardBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))

                            Button(action: {
                                if appState.isDemoMode {
                                    appState.isDemoMode = false
                                    appState.isAuthenticated = false
                                } else {
                                    onLogout()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                    Spacer()
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(Color.mosaicRose)
                                .padding(14)
                                .background(Color.mosaicCardBg)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Sponsor Integrations Status
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sponsor Integrations")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(spacing: 10) {
                            IntegrationRow(
                                name: "Auth0 Universal Login",
                                status: "Configured (skmpe.us.auth0.com)",
                                icon: "key.fill",
                                color: Color.mosaicAccent
                            )
                            IntegrationRow(
                                name: "Google Gemini 3.6 Flash",
                                status: "Active (Schema-Constrained Drafting)",
                                icon: "sparkles",
                                color: Color.mosaicTeal
                            )
                            IntegrationRow(
                                name: "Tiger Data (Timescale)",
                                status: "Live Time-Series & 90d Cache",
                                icon: "cylinder.split.1x2.fill",
                                color: Color.mosaicAmber
                            )
                            IntegrationRow(
                                name: "Backboard.io",
                                status: "Active (Privacy-Bounded Memory)",
                                icon: "memorychip.fill",
                                color: Color.mosaicIndigo
                            )
                        }
                        .padding(14)
                        .background(Color.mosaicCardBg)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
                    }
                    .padding(.horizontal, 20)

                    // Security & App Lock
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Privacy & Device Protection")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(spacing: 0) {
                            Toggle(isOn: $appState.isBiometricLockEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("App Lock (Face ID / Passcode)")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text("Require biometric authentication on launch")
                                        .font(.caption)
                                        .foregroundColor(Color.mosaicMuted)
                                }
                            }
                            .tint(Color.mosaicAccent)
                            .padding(14)

                            Divider().background(Color.mosaicCardBorder)

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Notification Content")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text("Masks details in push notifications")
                                        .font(.caption)
                                        .foregroundColor(Color.mosaicMuted)
                                }
                                Spacer()
                                Menu {
                                    Button("Neutral ('Mosaic update')") { notificationWording = "Neutral ('Mosaic update')" }
                                    Button("Off (No notifications)") { notificationWording = "Off (No notifications)" }
                                } label: {
                                    Text(notificationWording)
                                        .font(.caption.bold())
                                        .foregroundColor(Color.mosaicAccent)
                                }
                            }
                            .padding(14)
                        }
                        .background(Color.mosaicCardBg)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
                    }
                    .padding(.horizontal, 20)

                    // Data Management
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data Storage & Export")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(spacing: 10) {
                            Button(action: exportAllData) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(Color.mosaicAccent)
                                    Text("Export All Mosaic Data (JSON)")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.mosaicMuted)
                                }
                                .padding(14)
                                .background(Color.mosaicCardBg)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
                            }

                            Button(action: {
                                appState.loadSyntheticDemo()
                                showToast("Reset to Synthetic Demo Data")
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(Color.mosaicAmber)
                                    Text("Reset Synthetic Demo Data")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(14)
                                .background(Color.mosaicCardBg)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
                            }

                            Button(action: { showDeleteConfirm = true }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(Color.mosaicRose)
                                    Text("Delete All Local Mosaic Data")
                                        .font(.subheadline.bold())
                                        .foregroundColor(Color.mosaicRose)
                                    Spacer()
                                }
                                .padding(14)
                                .background(Color.mosaicCardBg)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Safety Limitation Notice
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color.mosaicAmber)
                            Text("Important Security Limitation")
                                .font(.caption.bold())
                                .foregroundColor(Color.mosaicAmber)
                        }
                        Text("Deleting Mosaic data permanently wipes all local credit items, drafts, and caches from this device. It cannot delete copies or letters you already exported or mailed. In addition, an app cannot protect against spyware or device-level monitoring.")
                            .font(.caption2)
                            .foregroundColor(Color.mosaicMuted)
                            .lineSpacing(2)
                    }
                    .padding(14)
                    .background(Color.mosaicAmber.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicAmber.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.mosaicNavy.ignoresSafeArea())
            .navigationBarHidden(true)
            .confirmationDialog(
                "Delete All Local Data?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Wipe All Data", role: .destructive) {
                    appState.deleteAllData()
                    showToast("All local credit reports, packets, and tasks deleted.")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all imported reports, extracted facts, recovery packets, and deadline tasks from your iPhone.")
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(activityItems: [exportedDataString])
            }
        }
    }

    private func showToast(_ msg: String) {
        withAnimation {
            toastMessage = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                toastMessage = nil
            }
        }
    }

    private func exportAllData() {
        let exportObj: [String: Any] = [
            "export_date": ISO8601DateFormatter().string(from: Date()),
            "total_accounts": appState.currentSnapshot?.accounts.count ?? 0,
            "total_changes": appState.changeItems.count,
            "total_packets": appState.recoveryPackets.count,
            "total_tasks": appState.tasks.count,
            "analytics_summary": [
                "scans": appState.analytics.totalScans,
                "reviewed": appState.analytics.changesReviewed,
                "packets": appState.analytics.packetsCreated,
                "open_tasks": appState.analytics.openTasks,
                "resolved_tasks": appState.analytics.completedTasks
            ]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: exportObj, options: .prettyPrinted),
           let jsonString = String(data: data, encoding: .utf8) {
            exportedDataString = jsonString
            showExportSheet = true
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct IntegrationRow: View {
    let name: String
    let status: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(status)
                    .font(.caption2)
                    .foregroundColor(Color.mosaicMuted)
            }
            Spacer()
            Circle()
                .fill(Color.mosaicTeal)
                .frame(width: 6, height: 6)
        }
        .padding(4)
    }
}
