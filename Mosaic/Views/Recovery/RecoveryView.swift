import SwiftUI

struct RecoveryView: View {
    @EnvironmentObject private var appState: AppState

    private var focusAccount: ReportAccount? {
        if let last4 = appState.recoveryPackets.first?.itemLast4 {
            return appState.currentSnapshot?.accounts.first { $0.accountLast4 == last4 }
        }
        return appState.currentSnapshot?.accounts.first {
            $0.accountType.localizedCaseInsensitiveContains("collection")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("These are letters you can mail. Mosaic will not send them for you.")
                        .font(MosaicFont.regular(16))
                        .foregroundColor(Color.mosaicSubtle)
                        .lineSpacing(3)
                        .padding(.top, 8)

                    if appState.recoveryPackets.isEmpty {
                        Text("Nothing here yet. Go to Scan, open an item you do not recognize, and come back.")
                            .font(MosaicFont.regular(16))
                            .foregroundColor(Color.mosaicInk)
                    } else {
                        ForEach(appState.recoveryPackets.indices, id: \.self) { index in
                            NavigationLink {
                                PacketDetailView(packet: $appState.recoveryPackets[index])
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
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.mosaicPage.ignoresSafeArea())
            .navigationTitle("Your letters")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func account(for packet: RecoveryPacket) -> ReportAccount? {
        if let last4 = packet.itemLast4 {
            return appState.currentSnapshot?.accounts.first { $0.accountLast4 == last4 }
        }
        return focusAccount
    }

    private func letterCard(_ packet: RecoveryPacket, account: ReportAccount?) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(account?.formattedBalance ?? "Letter")
                .font(MosaicFont.medium(40))
                .foregroundColor(Color.mosaicInk)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(minWidth: 118, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(packet.itemName)
                    .font(MosaicFont.medium(17))
                    .foregroundColor(Color.mosaicInk)
                Text(plainReason(for: packet))
                    .font(MosaicFont.regular(13))
                    .foregroundColor(Color.mosaicSubtle)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tap to open the letter")
                    .font(MosaicFont.medium(12))
                    .foregroundColor(Color.mosaicViolet)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(tint: Color.mosaicMint, cornerRadius: 28, shadowRadius: 12)
    }

    private func plainReason(for packet: RecoveryPacket) -> String {
        switch packet.classificationAtCreation {
        case .unrecognized:
            return "This showed up on your credit report. You said you did not open it."
        case .recognized:
            return "This showed up on your credit report. You said you know this account."
        case .pressuredOrNotFreelyAgreed:
            return "This showed up on your credit report. You said you did not freely agree to it."
        case .notSure:
            return "This showed up on your credit report. You were not sure about it yet."
        case .ignored:
            return "This showed up on your credit report. You chose to leave it for now."
        }
    }
}
