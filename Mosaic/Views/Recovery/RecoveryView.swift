import SwiftUI

struct RecoveryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var highlightedPacketID: UUID?

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("These are editable drafts. Mosaic will not send them for you.")
                            .font(MosaicFont.regular(16))
                            .foregroundColor(Color.mosaicSubtle)
                            .lineSpacing(3)
                            .padding(.top, 8)

                        if highlightedPacketID != nil {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Draft created · pending your approval. Review the facts, edit the letter, then choose Open in Mail.")
                                    .font(MosaicFont.medium(14))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundColor(Color.mosaicViolet)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .liquidGlass(tint: Color.mosaicLavender.opacity(0.55), cornerRadius: 16, shadowRadius: 0)
                        }

                        if appState.recoveryPackets.isEmpty {
                            Text("Nothing here yet. Mark something as Not mine in Review, and the letter will show up here.")
                                .font(MosaicFont.regular(16))
                                .foregroundColor(Color.mosaicInk)
                        } else {
                            ForEach(displayedPacketIndices, id: \.self) { index in
                                if let binding = primaryLetterBinding(for: index) {
                                    let packet = appState.recoveryPackets[index]
                                    NavigationLink {
                                        DraftEditorView(document: binding)
                                    } label: {
                                        letterCard(
                                            packet,
                                            account: account(for: packet),
                                            change: change(for: packet),
                                            isHighlighted: packet.id == highlightedPacketID
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .id(packet.id)
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
                .onAppear {
                    focusRequestedDraft(using: proxy)
                }
                .onChange(of: appState.requestedRecoveryPacketID) { _ in
                    focusRequestedDraft(using: proxy)
                }
            }
            .background(MosaicPageBackground(opacity: 0.3))
            .navigationTitle("Your letters")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var displayedPacketIndices: [Int] {
        appState.recoveryPackets.indices.sorted { lhs, rhs in
            let leftPacket = appState.recoveryPackets[lhs]
            let rightPacket = appState.recoveryPackets[rhs]
            let leftPriority = packetPriority(leftPacket)
            let rightPriority = packetPriority(rightPacket)
            if leftPriority != rightPriority {
                return leftPriority < rightPriority
            }
            return leftPacket.updatedAt > rightPacket.updatedAt
        }
    }

    private func packetPriority(_ packet: RecoveryPacket) -> Int {
        switch change(for: packet)?.changeType {
        case .collectionOrChargeoffChange: return 0
        case .newInquiry: return 1
        case .balanceIncrease, .balanceDecrease: return 2
        case .jointOrAuthorizedUserChange: return 3
        case .newAddress: return 4
        default: return 5
        }
    }

    private func focusRequestedDraft(using proxy: ScrollViewProxy) {
        guard let requestedID = appState.requestedRecoveryPacketID,
              appState.recoveryPackets.contains(where: { $0.id == requestedID }) else { return }
        highlightedPacketID = requestedID
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(requestedID, anchor: .top)
            }
        }
    }

    private func account(for packet: RecoveryPacket) -> ReportAccount? {
        if let last4 = packet.itemLast4 {
            return appState.currentSnapshot?.accounts.first { $0.accountLast4 == last4 }
        }
        return nil
    }

    private func change(for packet: RecoveryPacket) -> ChangeItem? {
        appState.changeItems.first { $0.id == packet.changeItemId }
    }

    private func primaryLetterBinding(for index: Int) -> Binding<PacketDocument>? {
        let packet = appState.recoveryPackets[index]
        guard let docIndex = packet.documents.firstIndex(where: { $0.documentType == .bureauDispute })
                ?? packet.documents.indices.first else { return nil }
        return $appState.recoveryPackets[index].documents[docIndex]
    }

    private func letterCard(
        _ packet: RecoveryPacket,
        account: ReportAccount?,
        change: ChangeItem?,
        isHighlighted: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if isHighlighted {
                Label("Review this first", systemImage: "sparkles")
                    .font(MosaicFont.medium(13))
                    .foregroundColor(Color.mosaicViolet)
            }

            // One-word label so the amount has meaning
            Text(categoryLabel(for: change, account: account, packet: packet))
                .font(MosaicFont.medium(12))
                .tracking(1.2)
                .foregroundColor(Color.mosaicSubtle)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(primaryValue(for: change, account: account))
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
                    Text(referenceLabel(for: change, packet: packet))
                        .font(MosaicFont.regular(13))
                        .foregroundColor(Color.mosaicSubtle)
                }
            }

            HStack(spacing: 5) {
                Text("Review draft")
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
            }
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
                .stroke(isHighlighted ? Color.mosaicViolet : Color.mosaicLine, lineWidth: isHighlighted ? 2 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func categoryLabel(for change: ChangeItem?, account: ReportAccount?, packet: RecoveryPacket) -> String {
        if let change {
            switch change.changeType {
            case .collectionOrChargeoffChange: return "Debt"
            case .balanceIncrease, .balanceDecrease: return "Balance"
            case .newInquiry: return "Inquiry"
            case .newAddress: return "Address"
            case .jointOrAuthorizedUserChange: return "Account"
            case .newAccount, .closedAccount, .statusChange: return "Account"
            case .duplicateOrInconsistentEntry: return "Review"
            }
        }

        let type = account?.accountType.lowercased() ?? ""
        if type.contains("collection") { return "Debt" }
        if type.contains("revolving") || type.contains("card") { return "Balance" }
        if type.contains("mortgage") || type.contains("loan") { return "Loan" }
        let itemName = packet.itemName.lowercased()
        if itemName.contains("inquiry") { return "Inquiry" }
        if itemName.contains("address") { return "Address" }
        switch packet.classificationAtCreation {
        case .unrecognized, .someoneElseOpened, .pressuredOrNotFreelyAgreed: return "Debt"
        case .jointOrShared, .authorizedUser: return "Review"
        case .recognized: return "Saved"
        case .notSure: return "Hold"
        case .ignored: return "Skip"
        }
    }

    private func primaryValue(for change: ChangeItem?, account: ReportAccount?) -> String {
        if let account {
            return account.formattedBalance
        }
        switch change?.changeType {
        case .newInquiry: return "New"
        case .newAddress: return "Added"
        default: return "Review"
        }
    }

    private func referenceLabel(for change: ChangeItem?, packet: RecoveryPacket) -> String {
        if let last4 = packet.itemLast4 {
            return "Account ending \(last4)"
        }
        switch change?.changeType {
        case .newInquiry: return "Hard inquiry · Page \(packet.sourcePage)"
        case .newAddress: return "Address record · Page \(packet.sourcePage)"
        default: return "Source page \(packet.sourcePage)"
        }
    }
}
