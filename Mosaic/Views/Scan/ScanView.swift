import SwiftUI
import UniformTypeIdentifiers

struct ScanView: View {
    @EnvironmentObject private var appState: AppState
    @State private var range = "WEEK"
    @State private var showPDFModal = false
    @State private var pdfURLForModal: URL? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        MosaicSheet {
                            VStack(alignment: .leading, spacing: 22) {
                                ZStack(alignment: .topTrailing) {
                                    LinearGradient(
                                        colors: [Color.mosaicHeroMid.opacity(0.55), Color.mosaicHeroMint.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .overlay(alignment: .trailing) {
                                        Text("$")
                                            .font(MosaicFont.bold(86))
                                            .foregroundColor(.white.opacity(0.18))
                                            .padding(.trailing, 12)
                                    }

                                    VStack(alignment: .leading, spacing: 14) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Review changes")
                                                .font(MosaicFont.medium(22))
                                                .foregroundColor(Color.mosaicInk)
                                            Text("GET EACH ITEM CLASSIFIED")
                                                .font(MosaicFont.medium(10))
                                                .tracking(0.7)
                                                .foregroundColor(Color.mosaicSubtle)
                                        }

                                        if appState.currentSnapshot != nil {
                                            NavigationLink(destination: CompareView()) {
                                                HStack {
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 12, weight: .bold))
                                                    Text("REVIEW NOW")
                                                        .font(MosaicFont.medium(13))
                                                        .tracking(0.8)
                                                }
                                                .foregroundColor(Color.mosaicInk)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                                .background(Color.white.opacity(0.72))
                                                .clipShape(Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            Button {
                                                appState.loadSyntheticDemo()
                                            } label: {
                                                HStack {
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 12, weight: .bold))
                                                    Text("LOAD SAMPLE REPORT")
                                                        .font(MosaicFont.medium(13))
                                                        .tracking(0.8)
                                                }
                                                .foregroundColor(Color.mosaicInk)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                                .background(Color.white.opacity(0.72))
                                                .clipShape(Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(18)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .liquidGlass(cornerRadius: 24, shadowRadius: 10)

                                HStack {
                                    Text("Transactions")
                                        .font(MosaicFont.medium(24))
                                        .foregroundColor(Color.mosaicInk)
                                    Spacer()
                                    Text("FEB 22–28, 2026")
                                        .font(MosaicFont.medium(11))
                                        .tracking(0.6)
                                        .foregroundColor(Color.mosaicMuted)
                                }

                                MosaicSegmentedPills(
                                    items: ["DAY", "WEEK", "MONTH", "YEAR"],
                                    selected: $range
                                )

                                if appState.changeItems.isEmpty {
                                    Text("No report changes yet. Load a sample or import a PDF.")
                                        .font(MosaicFont.regular(14))
                                        .foregroundColor(Color.mosaicMuted)
                                        .padding(.vertical, 12)
                                } else {
                                    VStack(spacing: 0) {
                                        Text("TODAY, FEB 28")
                                            .font(MosaicFont.medium(11))
                                            .tracking(0.8)
                                            .foregroundColor(Color.mosaicMuted)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.bottom, 8)

                                        ForEach(Array(appState.changeItems.prefix(4))) { item in
                                            NavigationLink(destination: CompareView()) {
                                                MosaicTransactionRow(
                                                    icon: icon(for: item),
                                                    iconColor: Color.mosaicInk,
                                                    title: item.issuerName ?? item.changeType.displayName,
                                                    subtitle: item.changeType.displayName,
                                                    amount: amount(for: item),
                                                    time: "12:18 PM"
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                                Button {
                                    pdfURLForModal = SyntheticDataService.shared.generateSyntheticPDFFile(isCurrentReport: true)
                                    showPDFModal = true
                                } label: {
                                    Text("View clean report PDF")
                                        .font(MosaicFont.medium(13))
                                        .foregroundColor(Color.mosaicSubtle)
                                        .frame(maxWidth: .infinity)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showPDFModal) {
                if let url = pdfURLForModal {
                    PDFViewerModal(url: url, title: "Report Document")
                }
            }
        }
    }

    private func icon(for item: ChangeItem) -> String {
        switch item.changeType {
        case .collectionOrChargeoffChange: return "exclamationmark.circle"
        case .balanceIncrease, .balanceDecrease: return "creditcard"
        case .newInquiry: return "magnifyingglass"
        default: return "arrow.up.right"
        }
    }

    private func amount(for item: ChangeItem) -> String {
        item.deltaSummary?.split(separator: " ").first.map(String.init) ?? "—"
    }
}
