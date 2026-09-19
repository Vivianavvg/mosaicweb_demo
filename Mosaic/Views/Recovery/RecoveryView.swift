import SwiftUI

struct RecoveryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                        Text("These are editable drafts. Mosaic will not send them for you.")
                        .font(MosaicFont.regular(16))
                        .foregroundColor(Color.mosaicSubtle)
                        .lineSpacing(3)
                        .padding(.top, 8)

                    if appState.recoveryPackets.isEmpty {
                        Text("Nothing here yet. Mark something as Not mine in Review, and the letter will show up here.")
                            .font(MosaicFont.regular(16))
                            .foregroundColor(Color.mosaicInk)
                    } else {
                        ForEach(appState.recoveryPackets.indices, id: \.self) { index in
                            if let binding = primaryLetterBinding(for: index) {
                                NavigationLink {
                                    DraftEditorView(document: binding)
                                } label: {
                                    letterCard(
                                        appState.recoveryPackets[index],
                                        account: account(for: appState.recoveryPackets[index])
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if !appState.savedItems.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Saved as yours")
                                .font(MosaicFont.medium(18))
                                .foregroundColor(Color.mosaicInk)
                            ForEach(appState.savedItems) { item in
                                Text(item.issuerName ?? item.summary)
                                    .font(MosaicFont.regular(14))
                                    .foregroundColor(Color.mosaicSubtle)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(MosaicPageBackground(opacity: 0.3))
            .navigationTitle("Your letters")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func account(for packet: RecoveryPacket) -> ReportAccount? {
        if let last4 = packet.itemLast4 {
            return appState.currentSnapshot?.accounts.first { $0.accountLast4 == last4 }
        }
        return appState.currentSnapshot?.accounts.first {
            $0.accountType.localizedCaseInsensitiveContains("collection")
        }
    }

    private func primaryLetterBinding(for index: Int) -> Binding<PacketDocument>? {
        let packet = appState.recoveryPackets[index]
        guard let docIndex = packet.documents.firstIndex(where: { $0.documentType == .bureauDispute })
                ?? packet.documents.indices.first else { return nil }
        return $appState.recoveryPackets[index].documents[docIndex]
    }

    private func letterCard(_ packet: RecoveryPacket, account: ReportAccount?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // One-word label so the amount has meaning
            Text(amountLabel(for: account, packet: packet))
                .font(MosaicFont.medium(12))
                .tracking(1.2)
                .foregroundColor(Color.mosaicSubtle)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(account?.formattedBalance ?? "—")
                    .font(MosaicFont.medium(40))
                    .foregroundColor(Color.mosaicInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(packet.itemName)
                        .font(MosaicFont.medium(16))
                        .foregroundColor(Color.mosaicInk)
                        .multilineTextAlignment(.trailing)
                    Text(packet.itemLast4.map { "**** \($0)" } ?? "Masked account")
                        .font(MosaicFont.regular(13))
                        .foregroundColor(Color.mosaicSubtle)
                }
            }

            Text("Tap to open the letter")
                .font(MosaicFont.medium(13))
                .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))

            Text("Draft ready · Review before mailing")
                .font(MosaicFont.regular(12))
                .foregroundColor(Color.mosaicMuted)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.mosaicLine, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func amountLabel(for account: ReportAccount?, packet: RecoveryPacket) -> String {
        let type = account?.accountType.lowercased() ?? ""
        if type.contains("collection") { return "Debt" }
        if type.contains("revolving") || type.contains("card") { return "Balance" }
        if type.contains("mortgage") || type.contains("loan") { return "Loan" }
        switch packet.classificationAtCreation {
        case .unrecognized, .someoneElseOpened, .pressuredOrNotFreelyAgreed: return "Debt"
        case .jointOrShared, .authorizedUser: return "Review"
        case .recognized: return "Saved"
        case .notSure: return "Hold"
        case .ignored: return "Skip"
        }
    }
}
