import SwiftUI
import Auth0

struct ContentView: View {
    @StateObject private var appState = AppState.shared
    @Environment(\.scenePhase) private var scenePhase
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

    @State private var user: UserInfo?
    @State private var isLoading = true
    @State private var isAuthenticating = false
    @State private var authErrorMessage: String?

    private static let useUniversalLinks: Bool = {
        guard let path = Bundle.main.path(forResource: "Auth0", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path) else {
            return false
        }
        return values["CallbackMode"] as? String == "universal-links"
    }()

    func webAuth() -> WebAuth {
        let webAuth = Auth0.webAuth()
        return Self.useUniversalLinks ? webAuth.useHTTPS() : webAuth
    }

    var body: some View {
        Group {
            if isLoading {
                SplashView()
            } else if appState.isAppLocked {
                ZStack {
                    LiquidGlassBackground()
                    VStack(spacing: 18) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(Color.mosaicInk)
                            .frame(width: 64, height: 64)
                            .liquidGlass(cornerRadius: 32, shadowRadius: 12)

                        Text("Mosaic is locked")
                            .font(MosaicFont.medium(28))
                            .foregroundColor(Color.mosaicInk)

                        Text("Unlock with Face ID or your device passcode")
                            .font(MosaicFont.regular(14))
                            .foregroundColor(Color.mosaicMuted)

                        MosaicPrimaryButton(title: "Unlock now") {
                            appState.requestUnlock()
                        }
                    }
                    .padding(28)
                    .liquidGlass(cornerRadius: 32, shadowRadius: 18)
                    .padding(.horizontal, 28)
                }
            } else if appState.isAuthenticated {
                MainTabView(
                    onLogout: logout
                )
                .transition(.opacity)
            } else {
                WelcomeView(
                    onLogin: { login() },
                    isAuthenticating: isAuthenticating,
                    authErrorMessage: authErrorMessage
                )
                .transition(.opacity)
            }
        }
        .environmentObject(appState)
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive || newPhase == .background {
                appState.lockForBackground()
            }
        }
        .onAppear {
#if DEBUG
            if let importArgument = CommandLine.arguments.first(where: { $0.hasPrefix("--import-file=") }) {
                let prefix = "--import-file="
                let path = String(importArgument.dropFirst(prefix.count))
                appState.isAuthenticated = true
                isLoading = false
                Task { @MainActor in
                    _ = try? await appState.importCreditReport(from: URL(fileURLWithPath: path))
                }
                return
            }
#endif
            guard credentialsManager.canRenew() else {
                isLoading = false
                return
            }
            credentialsManager.credentials { result in
                if case .success = result {
                    self.user = credentialsManager.user
                    if let user = self.user {
                        appState.userEmail = user.email
                        appState.userName = nil
                        appState.userSub = user.sub
                        appState.isAuthenticated = true
                    }
                }
                isLoading = false
            }
        }
    }

    private func login(screenHint: String? = nil) {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authErrorMessage = nil

        var wa = webAuth()
            .scope("openid profile email offline_access")
        if let screenHint {
            wa = wa.parameters(["screen_hint": screenHint])
        }
        wa.start { result in
            switch result {
            case .success(let credentials):
                guard credentialsManager.store(credentials: credentials) else {
                    isAuthenticating = false
                    authErrorMessage = "Mosaic could not securely save your session. Please try again."
                    return
                }
                self.user = credentialsManager.user
                if let u = self.user {
                    appState.userEmail = u.email
                    appState.userName = nil
                    appState.userSub = u.sub
                }
                appState.isAuthenticated = true
                isAuthenticating = false
            case .failure(let error):
                isAuthenticating = false
                if error.localizedDescription.lowercased().contains("cancel") {
                    authErrorMessage = "Sign-in was cancelled. Tap the button to try again."
                } else {
                    authErrorMessage = "Sign-in did not finish: \(error.localizedDescription)"
                }
                print("Auth0 Login failed: \(error)")
            }
        }
    }

    private func logout() {
        webAuth()
            .clearSession { result in
                _ = credentialsManager.clear()
                self.user = nil
                self.authErrorMessage = nil
                self.isAuthenticating = false
                appState.isAuthenticated = false
                appState.isDemoMode = false
            }
    }
}
