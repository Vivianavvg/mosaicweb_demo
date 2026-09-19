import SwiftUI

struct ChangeCardView: View {
    let item: ChangeItem
    let onClassify: (UserClassification) -> Void
    let onCreatePacket: () -> Void

    @State private var showWhy: Bool = false

    var body: some View {
        LiquidGlassCard(
            tint: item.severity == .urgentReview ? Color.mosaicRose : Color.mosaicAccent,
            cornerRadius: 18,
            borderOpacity: 0.28,
            contentPadding: 16
        ) {
            VStack(alignment: .leading, spacing: 14) {
                // Header: Type + Severity Badge + Source Page
                HStack {
                    Text(item.changeType.displayName)
                        .font(.headline)
                        .foregroundColor(Color.mosaicInk)

                    Spacer()

                    HStack(spacing: 6) {
                        Text("Page \(item.sourcePages.map(String.init).joined(separator: ", "))")
                            .font(.caption2.bold())
                            .foregroundColor(Color.mosaicAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.mosaicAccent.opacity(0.15))
                            .cornerRadius(6)

                        SeverityBadge(severity: item.severity)
                    }
                }

                // Summary
                Text(item.summary)
                    .font(.subheadline.bold())
                    .foregroundColor(Color.mosaicAccent)

                // Delta Summary
                if let delta = item.deltaSummary {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.caption)
                            .foregroundColor(Color.mosaicIndigo)
                            .padding(.top, 2)
                        Text(delta)
                            .font(.caption)
                            .foregroundColor(Color.mosaicSubtle)
                    }
                }

                // Plain English explanation toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showWhy.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showWhy ? "chevron.down.circle.fill" : "questionmark.circle")
                        Text(showWhy ? "Hide context" : "Why did Mosaic highlight this?")
                        Spacer()
                    }
                    .font(.caption.bold())
                    .foregroundColor(Color.mosaicMuted)
                }

                if showWhy {
                    Text(item.whySeeingThis)
                        .font(.caption)
                        .foregroundColor(Color.mosaicMuted)
                        .padding(10)
                        .background(Color.mosaicFill)
                        .cornerRadius(8)
                }

                Divider().background(Color.white.opacity(0.10))

                // Classification Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Which description fits your records?")
                        .font(.caption.bold())
                        .foregroundColor(Color.mosaicMuted)

                    // 5 classification buttons
                    VStack(spacing: 6) {
                        ClassificationButton(
                            title: "Mine",
                            subtitle: "I recognize opening and using this account",
                            icon: "checkmark.seal.fill",
                            isSelected: item.classification == .recognized,
                            action: { onClassify(.recognized) }
                        )
                        ClassificationButton(
                            title: "Not mine",
                            subtitle: "I do not recognize opening or using this account",
                            icon: "shield.slash.fill",
                            isSelected: item.classification == .unrecognized,
                            action: { onClassify(.unrecognized) }
                        )
                        ClassificationButton(
                            title: "No safe consent",
                            subtitle: "I was pressured or did not freely agree",
                            icon: "person.crop.circle.badge.exclamationmark.fill",
                            isSelected: item.classification == .pressuredOrNotFreelyAgreed,
                            action: { onClassify(.pressuredOrNotFreelyAgreed) }
                        )
                        HStack(spacing: 8) {
                            ClassificationButton(
                                title: "Not Sure",
                                subtitle: "Need to verify",
                                icon: "questionmark.circle",
                                isSelected: item.classification == .notSure,
                                action: { onClassify(.notSure) }
                            )
                            ClassificationButton(
                                title: "Ignore",
                                subtitle: "Skip for now",
                                icon: "eye.slash",
                                isSelected: item.classification == .ignored,
                                action: { onClassify(.ignored) }
                            )
                        }
                    }
                }

                // Calm transition & Packet Creation Prompt
                if item.classification == .unrecognized || item.classification == .pressuredOrNotFreelyAgreed {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("This may need a closer review. Keep your records together and consider asking the bureau or creditor to investigate. Mosaic cannot determine fraud or guarantee a removal.")
                            .font(.caption)
                            .foregroundColor(Color.mosaicAccent)
                            .lineSpacing(2)

                        Button(action: onCreatePacket) {
                            HStack {
                                Image(systemName: "folder.badge.plus")
                                Text("Prepare a reviewable dispute packet")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.mosaicInk)
                            .cornerRadius(10)
                        }
                    }
                    .padding(12)
                    .background(Color.mosaicAccent.opacity(0.12))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.mosaicAccent.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
}

private struct SeverityBadge: View {
    let severity: ChangeSeverity

    var body: some View {
        Text(severity.label)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }

    var color: Color {
        switch severity {
        case .informational: return Color.mosaicIndigo
        case .review: return Color.mosaicAmber
        case .urgentReview: return Color.mosaicRose
        }
    }
}

private struct ClassificationButton: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : (icon ?? "circle"))
                    .foregroundColor(isSelected ? Color.mosaicAccent : Color.mosaicMuted)
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption.weight(isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? Color.mosaicInk : Color.mosaicMuted)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 9))
                            .foregroundColor(isSelected ? Color.mosaicSubtle : Color.mosaicMuted.opacity(0.7))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? Color.mosaicFill : Color.mosaicPage)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.mosaicAccent.opacity(0.6) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
