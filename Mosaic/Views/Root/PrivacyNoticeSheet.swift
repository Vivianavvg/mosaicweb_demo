import SwiftUI

struct PrivacyNoticeSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color.mosaicAccent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Privacy & Safety Notice")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text("How Mosaic protects your information")
                                .font(.subheadline)
                                .foregroundColor(Color.mosaicMuted)
                        }
                    }
                    .padding(.top, 8)

                    Divider().background(Color.mosaicCardBorder)

                    NoticeSection(
                        icon: "doc.text.magnifyingglass",
                        title: "Credit Reports Contain Sensitive Data",
                        description: "Your credit report includes account histories and personal identifiers. Mosaic was designed from the ground up to minimize data exposure."
                    )

                    NoticeSection(
                        icon: "iphone",
                        title: "Original Documents Stay On Your Device",
                        description: "Your imported PDF files are processed locally on your iPhone using Apple's built-in PDFKit and Vision engines. The original document is never uploaded to the cloud."
                    )

                    NoticeSection(
                        icon: "eye.slash.fill",
                        title: "Strict Identifier Redaction",
                        description: "Before any AI-assisted drafting takes place, Social Security numbers, full account numbers, birth dates, phone numbers, and full street addresses are automatically masked."
                    )

                    NoticeSection(
                        icon: "exclamationmark.triangle.fill",
                        title: "Device Security Limitations",
                        description: "An app cannot guarantee complete safety if another person controls your physical device, passcode, Apple ID, or email. You can wipe your local data at any time from Settings."
                    )

                    NoticeSection(
                        icon: "trash.fill",
                        title: "You Are in Full Control",
                        description: "Mosaic does not automatically submit disputes or contact bureaus for you. All dispute letters and checklists are drafts for your personal review."
                    )
                }
                .padding(24)
            }
            .background(Color.mosaicNavy.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.mosaicAccent)
                }
            }
        }
    }
}

private struct NoticeSection: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.mosaicAccent)
                .frame(width: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.mosaicMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.mosaicCardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mosaicCardBorder, lineWidth: 1)
        )
    }
}
