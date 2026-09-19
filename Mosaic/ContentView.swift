import SwiftUI
import Auth0

struct ContentView: View {
    @StateObject private var appState = AppState.shared
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

    @State private var user: UserInfo?
    @State private var isLoading = true

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
                // App Lock Barrier
                VStack(spacing: 20) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color.mosaicAccent)

                    Text("Mosaic is Locked")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Unlock with Face ID or your device passcode")
                        .font(.subheadline)
                        .foregroundColor(Color.mosaicMuted)

                    Button("Unlock Now") {
                        appState.requestUnlock()
                    }
                    .font(.headline)
                    .foregroundColor(Color.mosaicNavy)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.mosaicAccent)
                    .cornerRadius(12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.mosaicNavy.ignoresSafeArea())
            } else if appState.isAuthenticated {
                MainTabView(
                    user: user,
                    onLogout: logout,
                    webAuth: webAuth
                )
                .transition(.opacity)
            } else {
                WelcomeView(
                    onLogin: { login() },
                    onSignup: { login(screenHint: "signup") }
                )
                .transition(.opacity)
            }
        }
        .environmentObject(appState)
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .onAppear {
            guard credentialsManager.canRenew() else {
                isLoading = false
                return
            }
            credentialsManager.credentials { result in
                if case .success = result {
                    self.user = credentialsManager.user
                    if let user = self.user {
                        appState.userEmail = user.email
                        appState.userName = user.name
                        appState.userSub = user.sub
                        appState.isAuthenticated = true
                        appState.loadSyntheticDemo()
                    }
                }
                isLoading = false
            }
        }
    }

    private func login(screenHint: String? = nil) {
        var wa = webAuth()
            .scope("openid profile email offline_access")
        if let screenHint {
            wa = wa.parameters(["screen_hint": screenHint])
        }
        wa.start { result in
            switch result {
            case .success(let credentials):
                _ = credentialsManager.store(credentials: credentials)
                self.user = credentialsManager.user
                if let u = self.user {
                    appState.userEmail = u.email
                    appState.userName = u.name
                    appState.userSub = u.sub
                }
                appState.isAuthenticated = true
                appState.loadSyntheticDemo()
            case .failure(let error):
                print("Auth0 Login failed or cancelled: \(error)")
            }
        }
    }

    private func logout() {
        webAuth()
            .clearSession { result in
                _ = credentialsManager.clear()
                self.user = nil
                appState.isAuthenticated = false
                appState.isDemoMode = false
            }
    }
}
