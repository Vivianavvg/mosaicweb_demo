import SwiftUI

struct SyntheticBadge: View {
    var text: String = "SYNTHETIC DEMO DATA"

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundColor(Color.mosaicAmber)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.mosaicAmber.opacity(0.15))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.mosaicAmber.opacity(0.35), lineWidth: 1)
        )
    }
}
