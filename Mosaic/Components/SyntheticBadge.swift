import SwiftUI

struct SyntheticBadge: View {
    var text: String = "SYNTHETIC DEMO DATA"

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(MosaicFont.medium(10))
        }
        .foregroundColor(Color.mosaicViolet)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.42))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color.mosaicViolet.opacity(0.24), lineWidth: 0.8)
        }
    }
}
