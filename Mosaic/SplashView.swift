import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.92
    @State private var opacity: Double = 0.4

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            VStack(spacing: 18) {
                Text("Mosaic")
                    .font(MosaicFont.medium(42))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 12, y: 4)

                ProgressView()
                    .tint(.white.opacity(0.85))
            }
            .padding(28)
            .liquidGlass(cornerRadius: 32, shadowRadius: 20)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.55)) {
                    scale = 1
                    opacity = 1
                }
            }
        }
    }
}
