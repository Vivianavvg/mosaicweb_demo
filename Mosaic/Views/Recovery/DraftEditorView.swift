import SwiftUI
import UIKit

struct DraftEditorView: View {
    @Binding var document: PacketDocument
    @EnvironmentObject private var appState: AppState

    @State private var showMailUnavailable = false
    @State private var mailMessage = ""
    @State private var showProfileEditor = false
    @State private var profileDraft = LetterUserProfile()
    @State private var recipientContact: RecipientContact?
    @State private var isResolvingRecipient = false
    @State private var hasReviewed = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Review before sending")
                        .font(MosaicFont.medium(24))
                        .foregroundColor(Color.mosaicInk)
                    Text("Review every fact before sending. Mosaic never sends anything automatically.")
                        .font(MosaicFont.regular(13))
                        .foregroundColor(Color.mosaicSubtle)

                    recipientSection
                    reviewAcknowledgement
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 18)

                Divider().overlay(Color.mosaicLine)

                renderedLetter
                    .padding(.horizontal, 22)
                    .padding(.top, 22)
                    .padding(.bottom, 156)
            }
        }
        .overlay(alignment: .bottom) {
            Button(action: openInDefaultMail) {
                Label("Open in Mail", systemImage: "envelope.fill")
                    .font(MosaicFont.medium(15))
                    .foregroundColor(.white)
                    .frame(maxWidth: 260)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
            .disabled(!hasReviewed)
            .opacity(hasReviewed ? 1 : 0.45)
            .background(Color.mosaicViolet)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.16), radius: 18, y: 8)
            .padding(.horizontal, 22)
            .padding(.bottom, 14)
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
                        TextField("Your email", text: $profileDraft.email)
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
            hasReviewed = document.reviewedByUserAt != nil
            document.draftText = GeminiService.shared.fillUserInfo(
                in: document.draftText,
                profile: appState.letterProfile
            )
        }
        .onDisappear {
            Task { @MainActor in
                await appState.syncToCloud()
            }
        }
        .task(id: document.id) {
            await resolveRecipientContact()
        }
    }

    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Recipient")
                .font(MosaicFont.medium(12))
                .tracking(0.8)
                .foregroundColor(Color.mosaicSubtle)
                .textCase(.uppercase)

            if isResolvingRecipient {
                Label("Finding a verified contact…", systemImage: "magnifyingglass")
                    .font(MosaicFont.regular(14))
                    .foregroundColor(Color.mosaicSubtle)
            } else if let recipientContact {
                VStack(alignment: .leading, spacing: 4) {
                    Label(recipientContact.email, systemImage: "envelope.fill")
                        .font(MosaicFont.medium(15))
                        .foregroundColor(Color.mosaicInk)
                    Text(recipientContact.sourceLabel)
                        .font(MosaicFont.regular(12))
                        .foregroundColor(Color.mosaicSubtle)

                    if let sourceURL = URL(string: recipientContact.sourceURL), !recipientContact.sourceURL.isEmpty {
                        Link("View contact source", destination: sourceURL)
                            .font(MosaicFont.medium(12))
                            .foregroundColor(Color.mosaicViolet)
                    }
                }
            } else if appState.isDemoMode {
                Label("Demo recipient · demo@mosaic.invalid", systemImage: "testtube.2")
                    .font(MosaicFont.regular(14))
                    .foregroundColor(Color.mosaicSubtle)
                Text("Demo only — no message is sent automatically.")
                    .font(MosaicFont.regular(12))
                    .foregroundColor(Color.mosaicMuted)
            } else {
                Label("No verified contact found yet", systemImage: "exclamationmark.triangle")
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

    private var reviewAcknowledgement: some View {
        Button {
            hasReviewed.toggle()
            document.reviewedByUserAt = hasReviewed ? Date() : nil
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: hasReviewed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(hasReviewed ? Color.mosaicViolet : Color.mosaicMuted)
                Text("I reviewed the letter and recipient")
                    .font(MosaicFont.medium(13))
                    .foregroundColor(Color.mosaicInk)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .accessibilityValue(hasReviewed ? "Checked" : "Not checked")
    }

    private func resolveRecipientContact() async {
        isResolvingRecipient = true
        defer { isResolvingRecipient = false }

        let userEmails = Set([
            appState.userEmail,
            appState.letterProfile.email
        ].compactMap { $0?.lowercased() })
        recipientContact = await TigerDataService.shared.resolveRecipient(
            issuerName: documentChange?.issuerName ?? appState.currentSnapshot?.accounts.first(where: { $0.accountLast4 == documentAccountLast4 })?.issuerName,
            reportEmailCandidates: appState.reportEmailCandidates,
            excludedEmails: userEmails
        )
    }

    private var documentChange: ChangeItem? {
        guard let packet = appState.recoveryPackets.first(where: { packet in
            packet.documents.contains(where: { $0.id == document.id })
        }) else { return nil }
        return appState.changeItems.first { $0.id == packet.changeItemId }
    }

    private var documentAccountLast4: String? {
        appState.recoveryPackets
            .first(where: { $0.documents.contains(where: { $0.id == document.id }) })?
            .itemLast4
    }

    private var officialDestination: (title: String, url: URL)? {
        guard let url = URL(string: document.documentType.defaultSourceUrl) else { return nil }
        return ("Open official dispute instructions", url)
    }

    @ViewBuilder
    private var renderedLetter: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(letterLines.enumerated()), id: \.offset) { _, line in
                renderedLine(line)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.mosaicLine, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var letterLines: [String] {
        document.draftText.components(separatedBy: .newlines)
    }

    @ViewBuilder
    private func renderedLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            Spacer().frame(height: 9)
        } else if line.uppercased().hasPrefix("TOPIC:") {
            Text(value(after: "TOPIC:", in: line))
                .font(MosaicFont.medium(22))
                .foregroundColor(Color.mosaicInk)
                .padding(.bottom, 10)
        } else if line.uppercased().hasPrefix("ISSUE:") {
            Text(value(after: "ISSUE:", in: line))
                .font(MosaicFont.medium(15))
                .foregroundColor(Color.mosaicViolet)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 8)
        } else if line.uppercased().hasPrefix("NOTICE:") {
            Text("Notice: \(value(after: "NOTICE:", in: line))")
                .font(MosaicFont.regular(12))
                .foregroundColor(Color.mosaicSubtle)
                .lineSpacing(3)
                .padding(12)
                .background(Color.mosaicWarmBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 8)
        } else if line.hasPrefix("- ") || line.hasPrefix("• ") {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 5))
                    .padding(.top, 8)
                Text(String(line.dropFirst(2)))
                    .font(MosaicFont.regular(16))
                    .foregroundColor(Color.mosaicInk)
                    .lineSpacing(4)
            }
        } else if ["DATE:", "TO:", "FROM:", "SUBJECT:"].contains(where: { line.uppercased().hasPrefix($0) }) {
            Text(line)
                .font(MosaicFont.regular(13))
                .foregroundColor(Color.mosaicSubtle)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(line.replacingOccurrences(of: "**", with: ""))
                .font(MosaicFont.regular(16))
                .foregroundColor(Color.mosaicInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func value(after prefix: String, in line: String) -> String {
        String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func openInDefaultMail() {
        guard hasReviewed else {
            mailMessage = "Check the review box after confirming the letter and recipient."
            showMailUnavailable = true
            return
        }
        let trimmedRecipient = recipientContact?.email ?? (appState.isDemoMode ? "demo@mosaic.invalid" : nil)
        guard let trimmedRecipient else {
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
