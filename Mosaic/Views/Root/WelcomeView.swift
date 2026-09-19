import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    let onLogin: () -> Void
    let onSignup: () -> Void

    @State private var showPrivacyNotice: Bool = false
    @State private var appear: Bool = false

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 14) {
                    Text("Mosaic")
                        .font(MosaicFont.medium(42))
                        .foregroundColor(.white)

                    Text("See what changed on your credit report.")
                        .font(MosaicFont.medium(18))
                        .foregroundColor(.white.opacity(0.92))
                        .multilineTextAlignment(.center)

                    Text("Review report changes and organize next steps. Mosaic does not decide what happened or submit anything for you.")
                        .font(MosaicFont.regular(14))
                        .foregroundColor(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(24)
                .liquidGlass(cornerRadius: 32, shadowRadius: 18)
                .padding(.horizontal, 24)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 18)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onLogin) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.right")
                            Text("Continue with Auth0")
                                .font(MosaicFont.medium(15))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.mosaicInk)
                        .clipShape(Capsule(style: .continuous))
                    }

                    Button {
                        withAnimation { appState.startDemoMode() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Use Synthetic Demo Data")
                                .font(MosaicFont.medium(15))
                        }
                        .foregroundColor(Color.mosaicInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .liquidGlass(cornerRadius: 100, shadowRadius: 10)
                    }

                    Button { showPrivacyNotice = true } label: {
                        Text("How Mosaic protects your privacy")
                            .font(MosaicFont.medium(12))
                            .foregroundColor(Color.mosaicSubtle)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appear ? 1 : 0)
            }
        }
        .sheet(isPresented: $showPrivacyNotice) {
            PrivacyNoticeSheet()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) { appear = true }
        }
    }
}
