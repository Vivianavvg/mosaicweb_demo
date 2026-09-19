import SwiftUI

extension View {
    /// Hides the system tab bar on pushed screens so Apple's glass bar cannot cover the page.
    func hidesFloatingTabBar() -> some View {
        toolbar(.hidden, for: .tabBar)
    }
}
