import SwiftUI

struct RecoveryView: View {
    @EnvironmentObject private var appState: AppState

    private var initials: String {
        let name = appState.userName ?? "Mosaic"
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "M" : String(letters)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        MosaicTopBar(profileTitle: "PERSONAL", initials: initials)

                        VStack(spacing: 10) {
                            Text("DISPUTED BALANCE")
                                .font(MosaicFont.medium(11))
                                .tracking(1.2)
                                .foregroundColor(.white.opacity(0.8))
                            Text("$9,940.00")
                                .font(MosaicFont.medium(44))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
                        }
                        .padding(.top, 8)

                        HStack(spacing: 12) {
                            NavigationLink(destination: DeadlineTrackerView()) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.right")
                                    Text("TRACK")
                                        .font(MosaicFont.medium(13))
                                        .tracking(0.6)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 14)
                                .background(Color.mosaicInk)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: InteractiveChecklistView()) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down")
                                    Text("PREPARE")
                                        .font(MosaicFont.medium(13))
                                        .tracking(0.6)
                                }
                                .foregroundColor(Color.mosaicInk)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 14)
                                .liquidGlass(cornerRadius: 100, shadowRadius: 8)
                            }
                            .buttonStyle(.plain)
                        }

                        HStack(spacing: 10) {
                            miniCard(title: "LETTERS", value: "\(appState.recoveryPackets.count)", bars: [4, 7, 6, 9, 8])
                            miniCard(title: "OPEN TASKS", value: "\(appState.tasks.filter { !$0.isCompleted }.count)", bars: [3, 5, 8, 6, 10])
                            miniCard(title: "DONE", value: "\(appState.tasks.filter { $0.isCompleted }.count)", bars: [2, 3, 4, 6, 5])
                        }
                        .padding(.horizontal, 20)

                        MosaicSheet {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Packets")
                                        .font(MosaicFont.medium(24))
                                        .foregroundColor(Color.mosaicInk)
                                    Spacer()
                                    Text("\(appState.recoveryPackets.count) READY")
                                        .font(MosaicFont.medium(11))
                                        .tracking(0.7)
                                        .foregroundColor(Color.mosaicMuted)
                                }

                                if appState.recoveryPackets.isEmpty {
                                    Text("Classify an unauthorized item in Scan to generate dispute letters.")
                                        .font(MosaicFont.regular(14))
                                        .foregroundColor(Color.mosaicMuted)
                                } else {
                                    ForEach($appState.recoveryPackets) { $packet in
                                        NavigationLink(destination: PacketDetailView(packet: $packet)) {
                                            MosaicTransactionRow(
                                                icon: "envelope",
                                                iconColor: Color.mosaicInk,
                                                title: packet.itemName,
                                                subtitle: packet.status.displayName,
                                                amount: packet.itemLast4.map { "**** \($0)" } ?? "",
                                                time: "Review"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 128)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func miniCard(title: String, value: String, bars: [CGFloat]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(MosaicFont.medium(10))
                .tracking(0.7)
                .foregroundColor(Color.mosaicMuted)
            MosaicBarChart(values: bars, highlightIndex: bars.count - 1)
                .frame(height: 36)
            Text(value)
                .font(MosaicFont.medium(22))
                .foregroundColor(Color.mosaicInk)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: 22, shadowRadius: 10)
    }
}
