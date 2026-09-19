import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedTab: Int
    @State private var assistantSummary = "Your latest report is ready for a calm, item-by-item review."
    @State private var isLoadingSummary = false

    private var initials: String {
        let name = appState.userName ?? "Mosaic"
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "M" : String(letters)
    }

    private var displayName: String {
        appState.userName?.split(separator: " ").first.map(String.init) ?? "there"
    }

    var body: some View {
        ZStack {
            Color.mosaicPage.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    MosaicTopBar(profileTitle: "PERSONAL", initials: initials)
                        .id("overview_top")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Good morning")
                            .font(MosaicFont.regular(17))
                            .foregroundColor(Color.mosaicSubtle)
                        Text(displayName)
                            .font(MosaicFont.medium(36))
                            .foregroundColor(Color.mosaicInk)
                    }
                    .padding(.horizontal, 24)

                    LiquidGlassCard(tint: Color.mosaicMint, cornerRadius: 28, contentPadding: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.mosaicViolet)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.72))
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Mosaic brief")
                                        .font(MosaicFont.medium(17))
                                        .foregroundColor(Color.mosaicInk)
                                    Text("A short read on what needs your attention")
                                        .font(MosaicFont.regular(12))
                                        .foregroundColor(Color.mosaicSubtle)
                                }
                            }

                            if isLoadingSummary {
                                ProgressView()
                                    .tint(Color.mosaicViolet)
                            } else {
                                Text(assistantSummary)
                                    .font(MosaicFont.regular(16))
                                    .foregroundColor(Color.mosaicInk)
                                    .lineSpacing(4)
                            }

                            Button {
                                selectedTab = 1
                            } label: {
                                Label("Review changes", systemImage: "arrow.right")
                                    .font(MosaicFont.medium(14))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.liquidGlass(tint: Color.mosaicViolet, isProminent: true))
                        }
                    }
                    .padding(.horizontal, 24)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        OverviewMetric(icon: "arrow.triangle.2.circlepath", title: "Changes", value: "\(appState.changeItems.count)", detail: "to review")
                        OverviewMetric(icon: "checkmark.circle", title: "Open tasks", value: "\(appState.tasks.filter { !$0.isCompleted }.count)", detail: "next steps")
                    }
                    .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Next step")
                            .font(MosaicFont.medium(20))
                            .foregroundColor(Color.mosaicInk)
                        HStack(spacing: 12) {
                            Image(systemName: appState.tasks.first(where: { !$0.isCompleted }) == nil ? "checkmark.seal" : "calendar.badge.clock")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color.mosaicViolet)
                                .frame(width: 42, height: 42)
                                .background(Color.mosaicMint)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(appState.tasks.first(where: { !$0.isCompleted })?.title ?? "You are all caught up")
                                    .font(MosaicFont.medium(15))
                                    .foregroundColor(Color.mosaicInk)
                                Text(appState.tasks.first(where: { !$0.isCompleted }) == nil ? "No open tasks right now." : "Review the draft before sending anything.")
                                    .font(MosaicFont.regular(13))
                                    .foregroundColor(Color.mosaicSubtle)
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass(cornerRadius: 24, shadowRadius: 8)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 128)
                }
            }
        }
        .task(id: appState.changeItems.count) {
            await refreshAssistantSummary()
        }
    }

    private func refreshAssistantSummary() async {
        isLoadingSummary = true
        assistantSummary = await GeminiService.shared.generateOverviewSummary(
            changeItems: appState.changeItems,
            openTaskCount: appState.tasks.filter { !$0.isCompleted }.count
        )
        isLoadingSummary = false
    }
}

private struct OverviewMetric: View {
    let icon: String
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.mosaicViolet)
            Text(title)
                .font(MosaicFont.regular(13))
                .foregroundColor(Color.mosaicSubtle)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value)
                    .font(MosaicFont.medium(26))
                    .foregroundColor(Color.mosaicInk)
                Text(detail)
                    .font(MosaicFont.regular(12))
                    .foregroundColor(Color.mosaicSubtle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.mosaicLine, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
