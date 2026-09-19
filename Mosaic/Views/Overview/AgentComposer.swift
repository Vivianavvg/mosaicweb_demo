import SwiftUI

struct AgentComposer: View {
    @Binding var text: String
    @ObservedObject var mic: MicrophoneController
    var isProcessing: Bool
    var onSend: (String) -> Void

    var body: some View {
        VoiceBeam(
            type: .mobile,
            level: mic.level,
            processing: isProcessing || mic.state == .live,
            colorVariant: .ocean,
            strength: mic.state == .live || isProcessing ? 0.68 : 0.28,
            reach: mic.state == .live || isProcessing ? 1 : 0.72,
            spread: 0.82
        ) {
            VStack(alignment: .leading, spacing: 8) {
                if mic.state == .live {
                    Text(mic.transcript.isEmpty ? "Listening…" : mic.transcript)
                        .font(MosaicFont.regular(13))
                        .foregroundColor(Color.mosaicSubtle)
                        .lineLimit(2)
                } else if let errorMessage = mic.errorMessage {
                    Text(errorMessage)
                        .font(MosaicFont.regular(12))
                        .foregroundColor(Color.mosaicPurple)
                }

                HStack(spacing: 10) {
                    Button(action: mic.toggle) {
                        Image(systemName: mic.state == .live ? "stop.fill" : "mic.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(mic.state == .live ? .white : Color.mosaicInk)
                            .frame(width: 42, height: 42)
                            .background(mic.state == .live ? Color.mosaicViolet : Color.mosaicMint)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(mic.state == .live ? "Stop" : "Listen")

                    TextField(placeholder, text: $text, axis: .vertical)
                        .font(MosaicFont.regular(16))
                        .foregroundColor(Color.mosaicInk)
                        .lineLimit(1...3)
                        .disabled(isProcessing)
                        .onSubmit(send)

                    Button(action: send) {
                        Image(systemName: isProcessing ? "ellipsis" : "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(canSend || isProcessing ? Color.mosaicViolet : Color.mosaicSubtle)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend || isProcessing)
                    .accessibilityLabel("Send")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .liquidGlass(cornerRadius: 28, shadowRadius: 16)
        }
    }

    private var placeholder: String {
        if mic.state == .live { return "Speak what you want Mosaic to remember" }
        if isProcessing { return "Mosaic is thinking…" }
        return "Tell Mosaic what changed, or what to remember"
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        text = ""
        onSend(value)
    }
}
