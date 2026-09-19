import SwiftUI

struct DraftEditorView: View {
    @Binding var document: PacketDocument
    @Environment(\.dismiss) private var dismiss

    @State private var isCopied: Bool = false
    @State private var showShareSheet: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Legal & Consumer Protection Disclaimer Banner
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(Color.mosaicAmber)
                    Text("Draft For Personal Review")
                        .font(.caption.bold())
                        .foregroundColor(Color.mosaicAmber)
                    Spacer()
                    if let reviewed = document.reviewedByUserAt {
                        Text("Reviewed \(reviewed, style: .date)")
                            .font(.caption2)
                            .foregroundColor(Color.mosaicTeal)
                    }
                }
                Text("Mosaic is not a lawyer or credit-repair company. Confirm the facts, replace all [bracketed prompts], and verify bureau submission rules before sending.")
                    .font(.caption2)
                    .foregroundColor(Color.mosaicMuted)
                    .lineLimit(2)
            }
            .padding(12)
            .background(Color.mosaicAmber.opacity(0.12))

            // Text Editor for Draft Content
            TextEditor(text: $document.draftText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color.mosaicInk)
                .scrollContentBackground(.hidden)
                .background(Color.mosaicPage)
                .padding(12)

            Divider().background(Color.mosaicCardBorder)

            // Action Toolbar (Copy, Share, Mark Reviewed)
            HStack(spacing: 12) {
                Button(action: {
                    UIPasteboard.general.string = document.draftText
                    isCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                    }
                }) {
                    HStack {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied" : "Copy")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(Color.mosaicInk)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.mosaicCardBg)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mosaicCardBorder, lineWidth: 1))
                }

                Button(action: {
                    showShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share / Export")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(Color.mosaicInk)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.mosaicCardBg)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mosaicCardBorder, lineWidth: 1))
                }

                Spacer()

                Button(action: {
                    document.reviewedByUserAt = Date()
                    dismiss()
                }) {
                    Text("Save & Close")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(Color.mosaicInk)
                        .cornerRadius(8)
                }
            }
            .padding(14)
            .background(Color.mosaicDarkBg)
        }
        .background(Color.mosaicPage.ignoresSafeArea())
        .hidesFloatingTabBar()
        .navigationTitle(document.documentType.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [document.draftText])
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
