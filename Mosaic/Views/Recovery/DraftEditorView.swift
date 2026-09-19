import SwiftUI
import UIKit

struct DraftEditorView: View {
    @Binding var document: PacketDocument
    @EnvironmentObject private var appState: AppState

    @State private var showMailUnavailable = false
    @State private var mailMessage = ""
    @State private var recipientEmail = ""
    @State private var showProfileEditor = false
    @State private var profileDraft = LetterUserProfile()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Review before sending")
                        .font(MosaicFont.medium(22))
                        .foregroundColor(Color.mosaicInk)
                    Text("Mosaic prepares a draft. You choose the recipient and decide whether to send it.")
                        .font(MosaicFont.regular(13))
                        .foregroundColor(Color.mosaicSubtle)
                    TextField("Recipient email", text: $recipientEmail)
                        .font(MosaicFont.regular(14))
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                    Button("Confirm or edit your details") {
                        profileDraft = appState.letterProfile
                        showProfileEditor = true
                    }
                    .font(MosaicFont.medium(13))
                    .foregroundColor(Color.mosaicViolet)
                    Text("Draft for review. Mosaic does not send anything unless you choose to open it in Mail.")
                        .font(MosaicFont.regular(12))
                        .foregroundColor(Color.mosaicMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)

                Divider().overlay(Color.mosaicLine)

                // Email-style letter body on white — editable before Open in Mail
                TextEditor(text: $document.draftText)
                    .font(.system(size: 15, design: .default))
                    .foregroundColor(Color.mosaicInk)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                Divider().overlay(Color.mosaicLine)

                Button(action: openInDefaultMail) {
                    Label("Open in Mail", systemImage: "arrow.up.right.square")
                        .font(MosaicFont.medium(15))
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .background(Color.white)
            }
        }
        .hidesFloatingTabBar()
        .navigationTitle("Letter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Email app unavailable", isPresented: $showMailUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(mailMessage)
        }
        .sheet(isPresented: $showProfileEditor) {
            NavigationStack {
                Form {
                    Section("Your details") {
                        TextField("Full name", text: $profileDraft.fullName)
                        TextField("Mailing address", text: $profileDraft.mailingAddress, axis: .vertical)
                        TextField("Phone", text: $profileDraft.phone)
                        TextField("Email", text: $profileDraft.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    }
                    Section {
                        Text("Mosaic inserts these details into drafts. Check every field before exporting or mailing.")
                            .font(MosaicFont.regular(12))
                            .foregroundColor(Color.mosaicSubtle)
                    }
                }
                .navigationTitle("Your details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showProfileEditor = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            appState.letterProfile = profileDraft
                            document.draftText = GeminiService.shared.fillUserInfo(in: document.draftText, profile: profileDraft)
                            showProfileEditor = false
                        }
                    }
                }
            }
        }
        .onAppear {
            recipientEmail = ""
            profileDraft = appState.letterProfile
            document.draftText = GeminiService.shared.fillUserInfo(
                in: document.draftText,
                profile: appState.letterProfile
            )
        }
    }

    private func openInDefaultMail() {
        let trimmedRecipient = recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedRecipient.contains("@") else {
            mailMessage = "Add the bureau or creditor email address before opening Mail."
            showMailUnavailable = true
            return
        }
        guard appState.letterProfile.isComplete else {
            profileDraft = appState.letterProfile
            showProfileEditor = true
            return
        }

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = trimmedRecipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: emailSubject),
            URLQueryItem(name: "body", value: document.draftText)
        ]

        guard let url = components.url else {
            mailMessage = "Mosaic could not prepare that email address."
            showMailUnavailable = true
            return
        }

        UIApplication.shared.open(url) { didOpen in
            if !didOpen {
                mailMessage = "No default email app could open this letter."
                showMailUnavailable = true
            }
        }
    }

    private var emailSubject: String {
        if let topicLine = document.draftText.split(separator: "\n").first(where: { $0.uppercased().hasPrefix("TOPIC:") }) {
            return String(topicLine.dropFirst(6)).trimmingCharacters(in: .whitespaces)
        }
        return document.title
    }
}
