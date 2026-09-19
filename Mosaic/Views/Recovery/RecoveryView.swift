import SwiftUI

struct RecoveryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header with Quick Exit
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Dispute Letters & Recovery")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                Text("Your customized legal dispute letters and action packets.")
                                    .font(.footnote)
                                    .foregroundColor(Color.mosaicMuted)
                            }
                            Spacer()
                            QuickExitButton()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // 30-Day Legal Deadline Card
                        NavigationLink(destination: DeadlineTrackerView()) {
                            LiquidGlassCard(tint: Color.mosaicAmber, cornerRadius: 18, borderOpacity: 0.3, contentPadding: 16) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.mosaicAmber.opacity(0.18))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "calendar.badge.clock")
                                            .font(.system(size: 22))
                                            .foregroundColor(Color.mosaicAmber)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("30-Day Statutory Deadlines")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        Text("\(appState.tasks.filter { !$0.isCompleted }.count) open response windows • Federal FCRA protections")
                                            .font(.caption)
                                            .foregroundColor(Color.mosaicMuted)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundColor(Color.mosaicMuted)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)

                        // Recovery Packets List
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Your Dispute Packets")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(appState.recoveryPackets.count) Ready")
                                    .font(.caption.bold())
                                    .foregroundColor(Color.mosaicAccent)
                            }
                            .padding(.horizontal, 20)

                            if appState.recoveryPackets.isEmpty {
                                LiquidGlassCard(tint: Color.mosaicIndigo, cornerRadius: 18, borderOpacity: 0.25, contentPadding: 24) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "envelope.badge.shield.half.filled")
                                            .font(.system(size: 36))
                                            .foregroundColor(Color.mosaicMuted)
                                        Text("No Dispute Packets Generated Yet")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("Review your credit report changes in the Scan tab and select 'I was pressured' or 'I didn't authorize this' to create your customized legal letters.")
                                            .font(.footnote)
                                            .foregroundColor(Color.mosaicMuted)
                                            .multilineTextAlignment(.center)
                                            .lineSpacing(3)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.horizontal, 20)
                            } else {
                                ForEach($appState.recoveryPackets) { $packet in
                                    NavigationLink(destination: PacketDetailView(packet: $packet)) {
                                        PacketSummaryCard(packet: packet)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Evidence & Safety Tips
                        NavigationLink(destination: InteractiveChecklistView()) {
                            LiquidGlassCard(tint: Color.mosaicTeal, cornerRadius: 16, borderOpacity: 0.25, contentPadding: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.mosaicTeal)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Dispute Evidence & Records Checklist")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        Text("Keep proof of mailing and copy required ID documents before sending.")
                                            .font(.caption)
                                            .foregroundColor(Color.mosaicMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundColor(Color.mosaicMuted)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 96)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct PacketSummaryCard: View {
    let packet: RecoveryPacket

    var body: some View {
        LiquidGlassCard(tint: Color.mosaicAccent, cornerRadius: 18, borderOpacity: 0.3, contentPadding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(packet.itemName)
                            .font(.headline)
                            .foregroundColor(.white)
                        if let last4 = packet.itemLast4 {
                            Text("Account: **** \(last4)")
                                .font(.caption)
                                .foregroundColor(Color.mosaicMuted)
                        }
                    }
                    Spacer()
                    Text(packet.status.displayName)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.mosaicTeal.opacity(0.18))
                        .foregroundColor(Color.mosaicTeal)
                        .cornerRadius(6)
                }

                Divider().background(Color.white.opacity(0.12))

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.fill")
                            .font(.caption2)
                        Text("\(packet.documents.count) Legal Letters & Checklists")
                            .font(.caption.bold())
                    }
                    .foregroundColor(Color.mosaicAccent)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Review & Export")
                            .font(.caption.bold())
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                    }
                    .foregroundColor(Color.mosaicAccent)
                }
            }
        }
    }
}
