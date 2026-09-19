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

                // Brand Mark & Copy in Glass Hero Card
                LiquidGlassCard(tint: Color.mosaicAccent, cornerRadius: 28, borderOpacity: 0.35, contentPadding: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.mosaicAccent.opacity(0.25), Color.mosaicIndigo.opacity(0.12)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 84, height: 84)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.5), Color.mosaicAccent.opacity(0.3)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )

                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.mosaicAccent, Color.mosaicTeal],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.bottom, 4)

                        Text("Mosaic")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("See what changed on your credit report.")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)

                        Text("Mosaic helps you review report changes and organize next steps. It does not decide what happened or submit anything for you.")
                            .font(.subheadline)
                            .foregroundColor(Color.mosaicMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, 24)
                .offset(y: appear ? 0 : 25)
                .opacity(appear ? 1 : 0)

                Spacer()

                // Action Buttons
                VStack(spacing: 14) {
                    // Auth0 Sign In
                    Button(action: onLogin) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.key.fill")
                            Text("Continue with Auth0")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            ZStack {
                                LinearGradient(
                                    colors: [Color.mosaicAccent, Color(hex: "0284C7")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                            }
                        )
                        .foregroundColor(Color.mosaicNavy)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.mosaicAccent.opacity(0.35), radius: 14, y: 4)
                    }

                    // Synthetic Demo Data Bypass (for evaluation & offline judging)
                    Button(action: {
                        withAnimation {
                            appState.startDemoMode()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Use Synthetic Demo Data")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(Color.mosaicAmber)
                        .liquidGlass(tint: Color.mosaicAmber, cornerRadius: 16, borderOpacity: 0.38)
                    }

                    // Privacy Explanation
                    Button(action: {
                        showPrivacyNotice = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "shield.lefthalf.filled")
                            Text("How Mosaic protects your privacy")
                        }
                        .font(.footnote)
                        .foregroundColor(Color.mosaicMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .liquidGlass(tint: Color.clear, cornerRadius: 100, borderOpacity: 0.20, shadowRadius: 0)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .offset(y: appear ? 0 : 30)
                .opacity(appear ? 1 : 0)
            }
        }
        .sheet(isPresented: $showPrivacyNotice) {
            PrivacyNoticeSheet()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appear = true
            }
        }
    }
}
