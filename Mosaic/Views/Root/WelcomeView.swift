import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    let onLogin: () -> Void
    let onSignup: () -> Void

    @State private var showPrivacyNotice: Bool = false
    @State private var appear: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.mosaicNavy, Color(hex: "090D16")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Brand Mark & Copy
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color.mosaicAccent.opacity(0.2), Color.mosaicIndigo.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 88, height: 88)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.mosaicAccent.opacity(0.4), lineWidth: 1.5)
                            )

                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.mosaicAccent, Color.mosaicTeal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.bottom, 8)

                    Text("Mosaic")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("See what changed on your credit report.")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Text("Mosaic helps you review report changes and organize next steps. It does not decide what happened or submit anything for you.")
                        .font(.subheadline)
                        .foregroundColor(Color.mosaicMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                }
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
                            LinearGradient(
                                colors: [Color.mosaicAccent, Color(hex: "0284C7")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(Color.mosaicNavy)
                        .cornerRadius(14)
                        .shadow(color: Color.mosaicAccent.opacity(0.25), radius: 10, y: 4)
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
                        .background(Color.mosaicCardBg)
                        .foregroundColor(Color.mosaicAmber)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.mosaicAmber.opacity(0.3), lineWidth: 1)
                        )
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
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 28)
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
