import SwiftUI

struct MosaicCircleButton: View {
    let systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.mosaicInk)
                .frame(width: 44, height: 44)
                .liquidGlass(cornerRadius: 22, shadowRadius: 10)
        }
        .buttonStyle(.plain)
    }
}

struct MosaicProfilePill: View {
    var title: String = "PERSONAL"
    var initials: String = "M"

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.mosaicInk)
                    .frame(width: 28, height: 28)
                Text(initials)
                    .font(MosaicFont.medium(12))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(MosaicFont.medium(12))
                .tracking(0.8)
                .foregroundColor(Color.mosaicInk)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color.mosaicMuted)
        }
        .padding(.leading, 6)
        .padding(.trailing, 12)
        .padding(.vertical, 6)
        .liquidGlass(cornerRadius: 100, shadowRadius: 10)
    }
}

struct MosaicTopBar: View {
    var profileTitle: String = "PERSONAL"
    var initials: String = "M"
    var onMenu: (() -> Void)? = nil

    var body: some View {
        HStack {
            MosaicCircleButton(systemName: "square.grid.2x2") {
                onMenu?()
            }
            Spacer()
            MosaicProfilePill(title: profileTitle, initials: initials)
            Spacer()
            QuickExitButton()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

struct MosaicSegmentedPills: View {
    let items: [String]
    @Binding var selected: String

    var body: some View {
        HStack(spacing: 18) {
            ForEach(items, id: \.self) { item in
                Button {
                    selected = item
                } label: {
                    Text(item)
                        .font(MosaicFont.medium(12))
                        .tracking(0.6)
                        .foregroundColor(selected == item ? Color.mosaicInk : Color.mosaicMuted)
                        .padding(.horizontal, selected == item ? 12 : 0)
                        .padding(.vertical, 6)
                        .background {
                            if selected == item {
                                Capsule(style: .continuous)
                                    .fill(Color.mosaicFill)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct MosaicMetricTile: View {
    let eyebrow: String
    let value: String
    let detail: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(eyebrow.uppercased())
                    .font(MosaicFont.medium(11))
                    .tracking(0.8)
                    .foregroundColor(Color.mosaicMuted)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.mosaicInk.opacity(0.7))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(MosaicFont.medium(26))
                    .foregroundColor(Color.mosaicInk)
                Text(detail)
                    .font(MosaicFont.regular(12))
                    .foregroundColor(Color.mosaicMuted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: 22, shadowRadius: 8)
    }
}

struct MosaicPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                }
                Text(title)
                    .font(MosaicFont.medium(14))
                    .tracking(0.4)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(Color.mosaicInk)
            .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct MosaicGhostButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                }
                Text(title)
                    .font(MosaicFont.medium(14))
                    .tracking(0.4)
            }
            .foregroundColor(Color.mosaicInk)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .liquidGlass(cornerRadius: 100, shadowRadius: 8)
        }
        .buttonStyle(.plain)
    }
}

struct MosaicSheet<Content: View>: View {
    var topPadding: CGFloat = 22
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.top, topPadding)
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color.mosaicSheet)
                .shadow(color: Color.black.opacity(0.06), radius: 24, y: -4)
        )
        .overlay(alignment: .top) {
            Capsule()
                .fill(Color.mosaicLine)
                .frame(width: 36, height: 4)
                .padding(.top, 10)
        }
    }
}

struct MosaicBarChart: View {
    let values: [CGFloat]
    var highlightIndex: Int = 4

    var body: some View {
        GeometryReader { geo in
            let maxVal = max(values.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    Capsule(style: .continuous)
                        .fill(Color.mosaicInk.opacity(index == highlightIndex ? 1 : 0.85))
                        .frame(width: max((geo.size.width - 10 * CGFloat(values.count - 1)) / CGFloat(values.count), 6), height: max(8, geo.size.height * (value / maxVal)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

struct MosaicTransactionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let amount: String
    let time: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.mosaicFill)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(MosaicFont.medium(16))
                    .foregroundColor(Color.mosaicInk)
                Text(subtitle.uppercased())
                    .font(MosaicFont.medium(10))
                    .tracking(0.6)
                    .foregroundColor(Color.mosaicMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(amount)
                    .font(MosaicFont.medium(16))
                    .foregroundColor(Color.mosaicInk)
                Text(time)
                    .font(MosaicFont.regular(11))
                    .foregroundColor(Color.mosaicMuted)
            }
        }
        .padding(.vertical, 10)
    }
}
