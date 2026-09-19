import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    let onLogin: () -> Void
    let isAuthenticating: Bool
    let authErrorMessage: String?

    @State private var showPrivacyNotice = false
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.mosaicPage.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.mosaicViolet)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text("Mosaic")
                            .font(MosaicFont.medium(24))
                            .foregroundColor(Color.mosaicInk)
                    }
                    .padding(.top, 24)

                    Spacer(minLength: 112)

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
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 18)

                    Spacer(minLength: 56)

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

                        Button {
                            withAnimation { appState.startDemoMode() }
                        } label: {
                            HStack(spacing: 9) {
                                Image(systemName: "sparkles")
                                Text("Explore synthetic demo")
                                    .font(MosaicFont.medium(15))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .foregroundColor(Color.mosaicInk)
                        .buttonStyle(.liquidGlass(tint: Color.mosaicMint))

                        Button { showPrivacyNotice = true } label: {
                            Text("How Mosaic protects your privacy")
                                .font(MosaicFont.medium(12))
                                .foregroundColor(Color.mosaicSubtle)
                        }
                        .padding(.top, 4)
                    }
                    .opacity(appear ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
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
