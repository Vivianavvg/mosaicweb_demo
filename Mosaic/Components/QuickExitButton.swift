import SwiftUI

/// One-tap lock. Styled as the circular glass control from the reference screens.
public struct QuickExitButton: View {
    @EnvironmentObject private var appState: AppState

    public init() {}

    public var body: some View {
        MosaicCircleButton(systemName: "lock.fill") {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.isAppLocked = true
            }
        }
        .accessibilityLabel("Quick Exit and Lock App")
        .accessibilityHint("Instantly locks the application to protect your privacy")
    }
}
