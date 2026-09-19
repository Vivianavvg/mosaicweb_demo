import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedTab: Int

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Bar with Quick Exit
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Financial Safety")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                Text("You are in control. Take it one step at a time.")
                                    .font(.footnote)
                                    .foregroundColor(Color.mosaicMuted)
                            }
                            Spacer()
                            QuickExitButton()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .id("overview_top")

                        // Hero: Independence & Disputed Debt Card
                        LiquidGlassCard(tint: Color.mosaicAccent, cornerRadius: 22, borderOpacity: 0.35, contentPadding: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("DISPUTED / COERCED DEBT IDENTIFIED")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(Color.mosaicAccent)
                                            .tracking(1)
                                        Text("$9,940")
                                            .font(.system(size: 38, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(Color.mosaicAccent.opacity(0.15))
                                            .frame(width: 52, height: 52)
                                        Image(systemName: "shield.checkered")
                                            .font(.system(size: 26))
                                            .foregroundColor(Color.mosaicAccent)
                                    }
                                }

                                Text("Mosaic identified 2 unauthorized or coerced items on your March credit report that were not on your December baseline.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineSpacing(3)

                                // Status Highlights (Replaced developer telemetry with human milestones)
                                HStack(spacing: 10) {
                                    StatusPill(icon: "doc.text.fill", text: "2 Letters Ready", color: Color.mosaicTeal)
                                    StatusPill(icon: "clock.badge.checkmark", text: "1 In Review", color: Color.mosaicAmber)
                                    StatusPill(icon: "lock.shield", text: "Report Protected", color: Color.mosaicIndigo)
                                }

                                Divider().background(Color.white.opacity(0.12))

                                // Visual 4-Step Independence Stepper
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("YOUR ROADMAP TO FREEDOM")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color.mosaicMuted)
                                        .tracking(1)

                                    HStack(spacing: 6) {
                                        StepNode(step: 1, title: "Spot Changes", isCompleted: true)
                                        StepDivider(isCompleted: true)
                                        StepNode(step: 2, title: "Classify Debt", isCompleted: true)
                                        StepDivider(isCompleted: true)
                                        StepNode(step: 3, title: "Send Letters", isCompleted: false, isActive: true)
                                        StepDivider(isCompleted: false)
                                        StepNode(step: 4, title: "Clear Record", isCompleted: false)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Section: What Needs Your Care Today
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Needs Your Care Today")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("2 items to review")
                                    .font(.caption)
                                    .foregroundColor(Color.mosaicMuted)
                            }
                            .padding(.horizontal, 20)

                            // Item 1: Harbor Recovery Collection
                            ActionItemCard(
                                icon: "exclamationmark.triangle.fill",
                                iconColor: Color.mosaicRose,
                                title: "Harbor Recovery Collections",
                                amount: "$1,240.00",
                                context: "New collection entry on page 14 that was not on your December report. You did not authorize this account.",
                                buttonLabel: "Review Removal Letter",
                                action: { selectedTab = 2 }
                            )
                            .padding(.horizontal, 20)

                            // Item 2: First National Bank Surged Balance
                            ActionItemCard(
                                icon: "creditcard.trianglebadge.exclamationmark.fill",
                                iconColor: Color.mosaicAmber,
                                title: "First National Bank Card",
                                amount: "$8,700.00 (+$7,500)",
                                context: "Balance increased sharply from $1,200. If an ex-partner or unauthorized user ran up this debt, you can contest joint liability.",
                                buttonLabel: "Protect Joint Liability",
                                action: { selectedTab = 1 }
                            )
                            .padding(.horizontal, 20)
                        }

                        // Section: 30-Day Legal Protections & Bureau Countdown
                        LiquidGlassCard(tint: Color.mosaicTeal, cornerRadius: 18, borderOpacity: 0.25, contentPadding: 16) {
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.mosaicTeal.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "hourglass.badge.plus")
                                        .font(.system(size: 22))
                                        .foregroundColor(Color.mosaicTeal)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Federal 30-Day Investigation Window")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text("By federal law (FCRA § 611), credit bureaus have 30 days to investigate your dispute and prove authorization—or remove the item permanently.")
                                        .font(.caption)
                                        .foregroundColor(Color.mosaicMuted)
                                        .lineSpacing(2)

                                    HStack(spacing: 8) {
                                        Text("TransUnion: 18 days left")
                                            .font(.caption2.bold())
                                            .foregroundColor(Color.mosaicTeal)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.mosaicTeal.opacity(0.15))
                                            .cornerRadius(6)
                                        Spacer()
                                        Button("View Tracker") {
                                            selectedTab = 2
                                        }
                                        .font(.caption2.bold())
                                        .foregroundColor(Color.mosaicAccent)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Confidential Help & Safety Resources
                        LiquidGlassCard(tint: Color.mosaicIndigo, cornerRadius: 16, borderOpacity: 0.20, contentPadding: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.bubble.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.mosaicAccent)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Confidential Support & Coerced Debt Help")
                                        .font(.footnote.bold())
                                        .foregroundColor(.white)
                                    Text("Free, safe guidance from the National Domestic Violence Hotline & NNEDV.")
                                        .font(.caption2)
                                        .foregroundColor(Color.mosaicMuted)
                                }

                                Spacer()

                                if let url = URL(string: "tel:18007997233") {
                                    Link(destination: url) {
                                        Text("Call 24/7")
                                            .font(.caption.bold())
                                            .foregroundColor(Color.mosaicNavy)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.mosaicAccent)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 96)
                    }
                }
                .onAppear {
                    proxy.scrollTo("overview_top", anchor: .top)
                }
            }
        }
    }
}

// MARK: - Subcomponents

private struct StatusPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .cornerRadius(6)
    }
}

private struct StepNode: View {
    let step: Int
    let title: String
    let isCompleted: Bool
    var isActive: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.mosaicTeal : (isActive ? Color.mosaicAccent : Color.white.opacity(0.1)))
                    .frame(width: 22, height: 22)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.mosaicNavy)
                } else {
                    Text("\(step)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isActive ? Color.mosaicNavy : Color.mosaicMuted)
                }
            }

            Text(title)
                .font(.system(size: 9, weight: isActive ? .bold : .regular))
                .foregroundColor(isActive ? .white : Color.mosaicMuted)
                .fixedSize()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StepDivider: View {
    let isCompleted: Bool

    var body: some View {
        Rectangle()
            .fill(isCompleted ? Color.mosaicTeal : Color.white.opacity(0.12))
            .frame(height: 2)
            .padding(.bottom, 14)
    }
}

private struct ActionItemCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let amount: String
    let context: String
    let buttonLabel: String
    let action: () -> Void

    var body: some View {
        LiquidGlassCard(tint: iconColor, cornerRadius: 16, borderOpacity: 0.25, contentPadding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(iconColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text(amount)
                            .font(.headline.weight(.heavy))
                            .foregroundColor(iconColor)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(Color.mosaicMuted)
                }

                Text(context)
                    .font(.footnote)
                    .foregroundColor(Color.mosaicMuted)
                    .lineSpacing(2)

                Button(action: action) {
                    HStack {
                        Text(buttonLabel)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .font(.footnote)
                    .foregroundColor(Color.mosaicNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(iconColor)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
