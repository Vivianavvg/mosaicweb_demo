import SwiftUI

struct MosaicVoiceButton: View {
    @ObservedObject var microphone: MicrophoneController
    var isProcessing: Bool = false

    private var isActive: Bool {
        microphone.state == .live || isProcessing
    }

    var body: some View {
        VoiceBeam(
            type: .pill,
            level: microphone.level,
            processing: isActive,
            colorVariant: .ocean,
            strength: isActive ? 0.86 : 0.32,
            reach: isActive ? 1 : 0.7,
            spread: 0.82
        ) {
            BorderBeam(
                size: .pulseOutside,
                colorVariant: .ocean,
                strength: isActive ? 0.95 : 0.65,
                active: true,
                theme: .light,
                cornerRadius: 34
            ) {
                Button(action: microphone.toggle) {
                    Image(systemName: microphone.state == .live ? "stop.fill" : "mic.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isActive ? .white : Color.mosaicInk)
                        .frame(width: 66, height: 66)
                        .liquidGlass(
                            tint: isActive ? Color.mosaicViolet : .clear,
                            cornerRadius: 33,
                            shadowRadius: 12
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(microphone.state == .live ? "Stop listening" : "Ask Mosaic by voice")
            }
        }
        .frame(width: 82, height: 82)
    }
}
