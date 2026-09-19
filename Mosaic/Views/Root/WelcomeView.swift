import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    let onLogin: () -> Void
    let onDemo: () -> Void
    let isAuthenticating: Bool
    let authErrorMessage: String?

    @State private var showPrivacyNotice = false
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.mosaicPage.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Image("MosaicLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 36)
                    .accessibilityLabel("Mosaic")
                    .padding(.top, 24)

                VStack(alignment: .leading, spacing: 16) {
                    Text("See what changed on your credit report.")
                        .font(MosaicFont.medium(38))
                        .foregroundColor(Color.mosaicInk)
                        .lineSpacing(-2)

                    Text("Review report changes and organize your next step. Mosaic keeps you in control and never submits anything for you.")
                        .font(MosaicFont.regular(16))
                        .foregroundColor(Color.mosaicSubtle)
                        .lineSpacing(4)
                }
                .padding(.top, 28)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 18)

                Spacer(minLength: 24)

                VStack(spacing: 12) {
                    if let authErrorMessage {
                        Label(authErrorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(MosaicFont.regular(13))
                            .foregroundColor(Color.mosaicPurple)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color.mosaicMint.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Button(action: onLogin) {
                        HStack(spacing: 9) {
                            if isAuthenticating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                            }
                            Text(isAuthenticating ? "Signing in…" : "Sign in to Mosaic")
                                .font(MosaicFont.medium(16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.liquidGlass(tint: Color.mosaicViolet, isProminent: true))
                    .disabled(isAuthenticating)

                    Button(action: onDemo) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Try a private sample")
                                .font(MosaicFont.medium(15))
                        }
                        .foregroundColor(Color.mosaicViolet)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.liquidGlass(tint: Color.mosaicLavender))

                    Text("Uses clearly labeled synthetic data on this device. It is not your credit report.")
                        .font(MosaicFont.regular(11))
                        .foregroundColor(Color.mosaicSubtle)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)

                    Button { showPrivacyNotice = true } label: {
                        Text("How Mosaic protects your privacy")
                            .font(MosaicFont.medium(14))
                            .foregroundColor(Color.mosaicInk)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.liquidGlass(tint: Color.mosaicMint))
                }
                .opacity(appear ? 1 : 0)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showPrivacyNotice) {
            PrivacyNoticeSheet()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) { appear = true }
        }
    }
}
