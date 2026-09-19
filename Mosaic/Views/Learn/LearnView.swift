import SwiftUI

struct LearnView: View {
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
                    VStack(spacing: 18) {
                        MosaicTopBar(profileTitle: "PERSONAL", initials: initials)

                        MosaicSheet {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Learn")
                                    .font(MosaicFont.medium(28))
                                    .foregroundColor(Color.mosaicInk)
                                Text("Rights, coerced debt, and next steps")
                                    .font(MosaicFont.regular(14))
                                    .foregroundColor(Color.mosaicMuted)

                                EducationGlassCard(
                                    icon: "shield.lefthalf.filled",
                                    title: "Coerced debt protections",
                                    sourceCitation: "CFPB · CA SB 975 · NY · ME",
                                    summary: "Debt incurred through threat, force, fraud, or duress can be disputed and separated.",
                                    bullets: [
                                        "Bureaus must review claims where consent was involuntary.",
                                        "You can demand removal from accounts you did not open.",
                                        "Mosaic drafts cite these protections for your review."
                                    ],
                                    linkTitle: "NNEDV financial abuse guide",
                                    urlString: "https://nnedv.org/content/about-financial-abuse/"
                                )

                                EducationGlassCard(
                                    icon: "person.crop.circle.badge.minus",
                                    title: "Joint accounts & authorized users",
                                    sourceCitation: "Consumer Financial Protection Bureau",
                                    summary: "If an ex-partner added you or pressured a joint card, you can freeze or unlink liability.",
                                    bullets: [
                                        "Authorized users can request immediate issuer removal.",
                                        "Removal can delete that card’s history from your file.",
                                        "Joint accounts can be frozen to stop new charges."
                                    ],
                                    linkTitle: "CFPB authorized user guide",
                                    urlString: "https://www.consumerfinance.gov/ask-cfpb/am-i-responsible-for-debt-on-a-credit-card-account-if-i-am-only-an-authorized-user-en-1367/"
                                )

                                EducationGlassCard(
                                    icon: "lock.shield.fill",
                                    title: "Credit freezes are free",
                                    sourceCitation: "Federal Trade Commission",
                                    summary: "A freeze blocks new creditors from pulling your file so nobody can open accounts in your name.",
                                    bullets: [
                                        "Place separately at Equifax, Experian, and TransUnion.",
                                        "Placing and lifting a freeze is free by federal law.",
                                        "It does not change your existing score."
                                    ],
                                    linkTitle: "FTC freeze portal",
                                    urlString: "https://consumer.ftc.gov/articles/credit-freezes-and-fraud-alerts"
                                )

                                EducationGlassCard(
                                    icon: "doc.text.fill",
                                    title: "30-day dispute rights",
                                    sourceCitation: "FCRA § 611 · 15 U.S.C. § 1681i",
                                    summary: "After a written dispute, the bureau has 30 days to verify the debt or delete it.",
                                    bullets: [
                                        "Send Certified Mail with return receipt.",
                                        "Include copies of ID and a utility bill.",
                                        "Never send original documents."
                                    ],
                                    linkTitle: "CFPB dispute instructions",
                                    urlString: "https://www.consumerfinance.gov/ask-cfpb/how-do-i-dispute-an-error-on-my-credit-report-en-314/"
                                )

                                EducationGlassCard(
                                    icon: "heart.text.square.fill",
                                    title: "Confidential help",
                                    sourceCitation: "NDVH · NFCC",
                                    summary: "Skip paid credit-repair shops. Non-profit counselors and hotlines are free and confidential.",
                                    bullets: [
                                        "Hotline: 1-800-799-7233 or text START to 88788.",
                                        "NFCC offers free budget and debt advocacy.",
                                        "Legal aid can help with coerced-debt cases."
                                    ],
                                    linkTitle: "Find an NFCC counselor",
                                    urlString: "https://www.nfcc.org/"
                                )
                            }
                        }
                        .padding(.bottom, 128)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct EducationGlassCard: View {
    let icon: String
    let title: String
    let sourceCitation: String
    let summary: String
    let bullets: [String]
    let linkTitle: String
    let urlString: String

    var body: some View {
        LiquidGlassCard(cornerRadius: 24, contentPadding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.mosaicInk)
                        .frame(width: 40, height: 40)
                        .background(Color.mosaicFill)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(MosaicFont.medium(16))
                            .foregroundColor(Color.mosaicInk)
                        Text(sourceCitation.uppercased())
                            .font(MosaicFont.medium(10))
                            .tracking(0.5)
                            .foregroundColor(Color.mosaicMuted)
                    }
                }

                Text(summary)
                    .font(MosaicFont.regular(13))
                    .foregroundColor(Color.mosaicSubtle)
                    .lineSpacing(3)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.mosaicInk)
                                .frame(width: 4, height: 4)
                                .padding(.top, 6)
                            Text(bullet)
                                .font(MosaicFont.regular(12))
                                .foregroundColor(Color.mosaicMuted)
                        }
                    }
                }

                if let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack {
                            Text(linkTitle)
                                .font(MosaicFont.medium(12))
                                .foregroundColor(Color.mosaicInk)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.mosaicMuted)
                        }
                    }
                }
            }
        }
    }
}
