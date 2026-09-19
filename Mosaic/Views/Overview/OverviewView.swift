import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedTab: Int
    @State private var range = "MONTH"

    private var initials: String {
        let name = appState.userName ?? "Mosaic"
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "M" : String(letters)
    }

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    MosaicTopBar(profileTitle: "PERSONAL", initials: initials)
                        .id("overview_top")

                    MosaicSheet {
                        VStack(alignment: .leading, spacing: 22) {
                            MosaicSegmentedPills(
                                items: ["DAY", "WEEK", "MONTH", "YEAR"],
                                selected: $range
                            )

                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Overview")
                                        .font(MosaicFont.medium(28))
                                        .foregroundColor(Color.mosaicInk)
                                    Text("FEB 1–28, 2026")
                                        .font(MosaicFont.medium(11))
                                        .tracking(0.8)
                                        .foregroundColor(Color.mosaicMuted)
                                }
                                Spacer()
                                Button {
                                    selectedTab = 1
                                } label: {
                                    Text("VIEW HISTORY")
                                        .font(MosaicFont.medium(11))
                                        .tracking(0.8)
                                        .foregroundColor(Color.mosaicMuted)
                                }
                                .buttonStyle(.plain)
                            }

                            ZStack(alignment: .top) {
                                MosaicBarChart(
                                    values: chartValues,
                                    highlightIndex: 4
                                )
                                .frame(height: 120)

                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.mosaicInk)
                                        .frame(width: 6, height: 6)
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("$1,240")
                                            .font(MosaicFont.medium(13))
                                            .foregroundColor(Color.mosaicInk)
                                        Text("FEB 15")
                                            .font(MosaicFont.medium(9))
                                            .foregroundColor(Color.mosaicMuted)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .liquidGlass(cornerRadius: 12, shadowRadius: 8)
                                .offset(x: 18, y: -8)
                            }
                            .padding(.top, 8)

                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                MosaicMetricTile(eyebrow: "Disputed", value: "$9,940", detail: "2 coerced items", icon: "exclamationmark.circle")
                                MosaicMetricTile(eyebrow: "Letters", value: "\(appState.recoveryPackets.count)", detail: "Ready to send", icon: "envelope")
                                MosaicMetricTile(eyebrow: "Changes", value: "\(appState.changeItems.count)", detail: "Need review", icon: "arrow.triangle.2.circlepath")
                                MosaicMetricTile(eyebrow: "Tasks", value: "\(appState.tasks.filter { !$0.isCompleted }.count)", detail: "Open windows", icon: "checkmark.circle")
                            }

                            LiquidGlassCard(cornerRadius: 22, contentPadding: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color.mosaicInk)
                                        .frame(width: 40, height: 40)
                                        .background(Color.mosaicFill)
                                        .clipShape(Circle())
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Confidential support")
                                            .font(MosaicFont.medium(15))
                                            .foregroundColor(Color.mosaicInk)
                                        Text("24/7 hotline · 1-800-799-7233")
                                            .font(MosaicFont.regular(12))
                                            .foregroundColor(Color.mosaicMuted)
                                    }
                                    Spacer()
                                    if let url = URL(string: "tel:18007997233") {
                                        Link("CALL", destination: url)
                                            .font(MosaicFont.medium(12))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Color.mosaicInk)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 128)
                }
            }
        }
    }

    private var chartValues: [CGFloat] {
        switch range {
        case "DAY": return [4, 6, 5, 9, 12, 7, 8, 6]
        case "WEEK": return [8, 10, 7, 14, 18, 11, 9]
        case "YEAR": return [6, 8, 7, 10, 16, 12, 9, 11, 8, 14, 10, 7]
        default: return [6, 9, 7, 11, 16, 10, 8, 5, 7, 9, 6, 4]
        }
    }
}
