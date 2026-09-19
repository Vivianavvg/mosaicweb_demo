import SwiftUI

/// Discreet, trauma-informed Quick Exit button.
/// Designed for women and survivors: if someone enters the room unexpectedly,
/// one tap immediately locks the application and conceals all credit report details behind Face ID / Passcode.
public struct QuickExitButton: View {
    @EnvironmentObject private var appState: AppState

    public init() {}

    public var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.isAppLocked = true
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("Quick Exit")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(Color.mosaicMuted)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .accessibilityLabel("Quick Exit and Lock App")
        .accessibilityHint("Instantly locks the application to protect your privacy")
    }
}
