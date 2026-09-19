import SwiftUI

struct CompareView: View {
    @EnvironmentObject private var appState: AppState
    @State private var filterMode: Int = 0
    @State private var createdPacketFeedback: String? = nil

    var filteredChanges: [ChangeItem] {
        switch filterMode {
        case 1: // Needs Classification
            return appState.changeItems.filter { $0.classification == nil }
        case 2: // Unrecognized / Pressured
            return appState.changeItems.filter { $0.classification == .unrecognized || $0.classification == .pressuredOrNotFreelyAgreed }
        case 3: // Recognized / Ignored
            return appState.changeItems.filter { $0.classification == .recognized || $0.classification == .ignored }
        default:
            return appState.changeItems
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Comparison Context Banner
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Normalized Report Differences")
                            .font(MosaicFont.medium(18))
                            .foregroundColor(Color.mosaicInk)
                        Text("Current (March 2026) vs Prior (December 2025)")
                            .font(MosaicFont.regular(12))
                            .foregroundColor(Color.mosaicMuted)
                    }
                    Spacer()
                    if appState.currentSnapshot?.isSynthetic ?? false {
                        SyntheticBadge()
                    }
                }

                // Filter Picker
                Picker("Filter", selection: $filterMode) {
                    Text("All (\(appState.changeItems.count))").tag(0)
                    Text("Unclassified").tag(1)
                    Text("Unrecognized").tag(2)
                    Text("Resolved").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.mosaicPage)

            if let feedback = createdPacketFeedback {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.mosaicTeal)
                    Text(feedback)
                        .font(.caption.bold())
                        .foregroundColor(Color.mosaicInk)
                    Spacer()
                }
                .padding(12)
                .background(Color.mosaicTeal.opacity(0.2))
                .transition(.slide)
            }

            ScrollView {
                VStack(spacing: 16) {
                    if filteredChanges.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 36))
                                .foregroundColor(Color.mosaicMuted)
                            Text("No changes in this filter")
                                .font(.subheadline)
                                .foregroundColor(Color.mosaicMuted)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredChanges) { item in
                            ChangeCardView(
                                item: item,
                                onClassify: { classification in
                                    appState.classifyItem(itemId: item.id, classification: classification)
                                },
                                onCreatePacket: {
                                    Task {
                                        await appState.createRecoveryPacket(for: item)
                                        withAnimation {
                                            createdPacketFeedback = "Recovery Packet generated for \(item.issuerName ?? "item"). View in Recovery tab."
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                            withAnimation {
                                                createdPacketFeedback = nil
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color.mosaicPage.ignoresSafeArea())
        .navigationTitle("Change Inbox")
        .navigationBarTitleDisplayMode(.inline)
    }
}
