import SwiftUI

struct ChangeCardView: View {
    let item: ChangeItem
    let onClassify: (UserClassification) -> Void
    let onCreatePacket: () -> Void

    @State private var showWhy: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Type + Severity Badge + Source Page
            HStack {
                Text(item.changeType.displayName)
                    .font(.headline)
                    .foregroundColor(.white)

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
                        .foregroundColor(Color.mosaicAmber)
                        .padding(.top, 2)
                    Text(delta)
                        .font(.caption)
                        .foregroundColor(Color.mosaicMuted)
                }
            }

            // Extraction Confidence & Expandable "Why am I seeing this?"
            HStack {
                Text("Confidence: \(Int(item.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(Color.mosaicMuted)

                Spacer()

                Button(action: { showWhy.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                        Text(showWhy ? "Hide Explanation" : "Why am I seeing this?")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color.mosaicAccent)
                }
            }

            if showWhy {
                Text(item.whySeeingThis)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.85))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(8)
            }

            Divider().background(Color.mosaicCardBorder)

            // Classification Section
            VStack(alignment: .leading, spacing: 8) {
                Text("How do you classify this item?")
                    .font(.caption.bold())
                    .foregroundColor(Color.mosaicMuted)

                // 5 classification buttons
                VStack(spacing: 6) {
                    ClassificationButton(
                        classification: .recognized,
                        isSelected: item.classification == .recognized,
                        action: { onClassify(.recognized) }
                    )
                    ClassificationButton(
                        classification: .unrecognized,
                        isSelected: item.classification == .unrecognized,
                        action: { onClassify(.unrecognized) }
                    )
                    ClassificationButton(
                        classification: .pressuredOrNotFreelyAgreed,
                        isSelected: item.classification == .pressuredOrNotFreelyAgreed,
                        action: { onClassify(.pressuredOrNotFreelyAgreed) }
                    )
                    HStack(spacing: 8) {
                        ClassificationButton(
                            classification: .notSure,
                            isSelected: item.classification == .notSure,
                            action: { onClassify(.notSure) }
                        )
                        ClassificationButton(
                            classification: .ignored,
                            isSelected: item.classification == .ignored,
                            action: { onClassify(.ignored) }
                        )
                    }
                }
            }

            // Calm transition & Packet Creation Prompt
            if item.classification == .unrecognized || item.classification == .pressuredOrNotFreelyAgreed {
                VStack(alignment: .leading, spacing: 10) {
                    Text("You marked this item as unfamiliar or pressured. Mosaic can organize draft materials and official next steps for you to review.")
                        .font(.caption)
                        .foregroundColor(Color.mosaicAmber)
                        .lineSpacing(2)

                    Button(action: onCreatePacket) {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                            Text("Generate Recovery Packet & Dispute Drafts")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(Color.mosaicNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.mosaicAmber)
                        .cornerRadius(10)
                    }
                }
                .padding(12)
                .background(Color.mosaicAmber.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.mosaicAmber.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(16)
        .background(Color.mosaicCardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mosaicCardBorder, lineWidth: 1)
        )
    }
}

private struct SeverityBadge: View {
    let severity: ChangeSeverity

    var body: some View {
        Text(severity.label)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }

    var color: Color {
        switch severity {
        case .informational: return Color.mosaicAccent
        case .review: return Color.mosaicAmber
        case .urgentReview: return Color.mosaicRose
        }
    }
}

private struct ClassificationButton: View {
    let classification: UserClassification
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.mosaicTeal : Color.mosaicMuted)
                Text(classification.title)
                    .font(.caption.weight(isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : Color.mosaicMuted)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? Color.mosaicTeal.opacity(0.15) : Color.white.opacity(0.03))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.mosaicTeal.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
