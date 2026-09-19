import SwiftUI
import UIKit

struct DraftEditorView: View {
    @Binding var document: PacketDocument
    @EnvironmentObject private var appState: AppState

    @State private var showMailUnavailable = false
    @State private var mailMessage = ""
    @State private var showProfileEditor = false
    @State private var profileDraft = LetterUserProfile()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Gemini draft", systemImage: "sparkles")
                        .font(MosaicFont.medium(13))
                        .foregroundColor(Color.mosaicViolet)

                    Text(document.title)
                        .font(MosaicFont.medium(24))
                        .foregroundColor(Color.mosaicInk)
                    Text("Review every fact before sending. Mosaic never sends anything automatically.")
                        .font(MosaicFont.regular(13))
                        .foregroundColor(Color.mosaicSubtle)

                    recipientSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 18)

                Divider().overlay(Color.mosaicLine)

                renderedLetter
                    .padding(.horizontal, 22)
                    .padding(.top, 22)
                    .padding(.bottom, 110)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: openInDefaultMail) {
                Label("Open in Mail", systemImage: "envelope.fill")
                    .font(MosaicFont.medium(15))
                    .foregroundColor(.white)
                    .frame(maxWidth: 260)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
            .background(Color.mosaicViolet)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.96))
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
            profileDraft = appState.letterProfile
            document.draftText = GeminiService.shared.fillUserInfo(
                in: document.draftText,
                profile: appState.letterProfile
            )
        }
    }

    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Recipient")
                .font(MosaicFont.medium(12))
                .tracking(0.8)
                .foregroundColor(Color.mosaicSubtle)
                .textCase(.uppercase)

            if let recipientEmail {
                Label(recipientEmail, systemImage: "envelope.fill")
                    .font(MosaicFont.medium(15))
                    .foregroundColor(Color.mosaicInk)
            } else {
                Label("No verified email found in this report", systemImage: "exclamationmark.triangle")
                    .font(MosaicFont.regular(14))
                    .foregroundColor(Color.mosaicSubtle)

                if let destination = officialDestination {
                    Link(destination.title, destination: destination.url)
                        .font(MosaicFont.medium(13))
                        .foregroundColor(Color.mosaicViolet)
                }
            }
        }
        .padding(.top, 10)
    }

    private var recipientEmail: String? {
        let userAddresses = Set([
            appState.userEmail,
            appState.letterProfile.email
        ].compactMap { $0?.lowercased() })

        return appState.reportEmailCandidates.first {
            !userAddresses.contains($0.lowercased())
        }
    }

    private var officialDestination: (title: String, url: URL)? {
        guard let url = URL(string: document.documentType.defaultSourceUrl) else { return nil }
        return ("Open official dispute instructions", url)
    }

    @ViewBuilder
    private var renderedLetter: some View {
        if let formatted = try? AttributedString(
            markdown: letterMarkdown(from: document.draftText),
            options: .init(interpretedSyntax: .full)
        ) {
            Text(formatted)
                .font(MosaicFont.regular(16))
                .foregroundColor(Color.mosaicInk)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(document.draftText)
                .font(MosaicFont.regular(16))
                .foregroundColor(Color.mosaicInk)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func letterMarkdown(from text: String) -> String {
        text.components(separatedBy: .newlines).map { line in
            if line.hasPrefix("TOPIC:") {
                return "# \(line.dropFirst(6).trimmingCharacters(in: .whitespaces))"
            }
            if line.hasPrefix("ISSUE:") {
                return "**Reason:** \(line.dropFirst(6).trimmingCharacters(in: .whitespaces))"
            }
            if line.hasPrefix("SUBJECT:") {
                return "**Subject:** \(line.dropFirst(8).trimmingCharacters(in: .whitespaces))"
            }
            if line.hasPrefix("NOTICE:") {
                return "> **Notice:** \(line.dropFirst(7).trimmingCharacters(in: .whitespaces))"
            }
            for label in ["DATE:", "TO:", "FROM:"] where line.uppercased().hasPrefix(label) {
                return "**\(label.dropLast()):**\(line.dropFirst(label.count))"
            }
            return line
        }
        .joined(separator: "\n")
    }

    private func openInDefaultMail() {
        guard let trimmedRecipient = recipientEmail else {
            mailMessage = "Mosaic could not find a verified recipient email in this report. Use the official dispute instructions instead of sending to an unverified address."
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
