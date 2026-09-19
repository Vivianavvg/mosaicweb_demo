import SwiftUI

struct RecoveryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dispute Recovery")
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text("Draft dispute letters, worksheets & statutory deadlines")
                                .font(.subheadline)
                                .foregroundColor(Color.mosaicMuted)
                        }
                        Spacer()
                        if appState.currentSnapshot?.isSynthetic ?? false {
                            SyntheticBadge()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Deadline Tracker Quick Access Card
                    NavigationLink(destination: DeadlineTrackerView()) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.mosaicAmber.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.mosaicAmber)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Deadline & Response Tracker")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("\(appState.tasks.filter { !$0.isCompleted }.count) open deadlines • 30-day FCRA windows")
                                    .font(.caption)
                                    .foregroundColor(Color.mosaicMuted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.mosaicMuted)
                        }
                        .padding(16)
                        .background(Color.mosaicCardBg)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mosaicCardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)

                    // Recovery Packets List
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Active Recovery Packets")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(appState.recoveryPackets.count) Total")
                                .font(.caption.bold())
                                .foregroundColor(Color.mosaicAccent)
                        }

                        if appState.recoveryPackets.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "folder.badge.questionmark")
                                    .font(.system(size: 36))
                                    .foregroundColor(Color.mosaicMuted)
                                Text("No Recovery Packets Created Yet")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Mark unfamiliar or pressured items on your report to organize draft materials and official next steps.")
                                    .font(.subheadline)
                                    .foregroundColor(Color.mosaicMuted)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(28)
                            .background(Color.mosaicCardBg)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mosaicCardBorder, lineWidth: 1))
                        } else {
                            ForEach($appState.recoveryPackets) { $packet in
                                NavigationLink(destination: PacketDetailView(packet: $packet)) {
                                    PacketSummaryCard(packet: packet)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Consumer Disclaimer Banner
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(Color.mosaicTeal)
                            Text("Consumer Protection Notice")
                                .font(.caption.bold())
                                .foregroundColor(Color.mosaicTeal)
                        }
                        Text("Mosaic organizes materials for your personal review. You decide what to send, when to send it, and how to verify information. Mosaic never submits disputes automatically.")
                            .font(.caption2)
                            .foregroundColor(Color.mosaicMuted)
                            .lineSpacing(2)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.mosaicNavy.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

private struct PacketSummaryCard: View {
    let packet: RecoveryPacket

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(packet.itemName)
                        .font(.headline)
                        .foregroundColor(.white)
                    if let last4 = packet.itemLast4 {
                        Text("Account Identifier: **** \(last4)")
                            .font(.caption)
                            .foregroundColor(Color.mosaicMuted)
                    }
                }
                Spacer()
                Text(packet.status.displayName)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.mosaicTeal.opacity(0.15))
                    .foregroundColor(Color.mosaicTeal)
                    .cornerRadius(6)
            }

            Divider().background(Color.mosaicCardBorder)

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.caption2)
                    Text("\(packet.documents.count) Drafts & Checklists")
                        .font(.caption)
                }
                .foregroundColor(Color.mosaicAccent)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "book.pages")
                        .font(.caption2)
                    Text("Page \(packet.sourcePage)")
                        .font(.caption)
                }
                .foregroundColor(Color.mosaicMuted)

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(Color.mosaicAccent)
                    .padding(.leading, 6)
            }
        }
        .padding(16)
        .background(Color.mosaicCardBg)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mosaicCardBorder, lineWidth: 1))
    }
}
