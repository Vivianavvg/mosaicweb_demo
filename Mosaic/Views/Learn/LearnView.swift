import SwiftUI

struct LearnView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        // Header Bar with Quick Exit
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Your Rights & Protection")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                Text("Official legal rights, coerced debt laws, and safety guides.")
                                    .font(.footnote)
                                    .foregroundColor(Color.mosaicMuted)
                            }
                            Spacer()
                            QuickExitButton()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // Card 1: Coerced Debt & Economic Abuse Rights (Highlighted Hero Card)
                        EducationGlassCard(
                            icon: "shield.lefthalf.filled",
                            iconColor: Color.mosaicAccent,
                            title: "Coerced Debt & Economic Abuse Protections",
                            sourceCitation: "CFPB Guidance & State Protections (e.g., CA SB 975, NY, ME)",
                            summary: "Coerced debt is any debt incurred through threat, force, fraud, or emotional duress—common in domestic and financial abuse. By law, debt obtained without voluntary consent can be legally disputed and separated.",
                            bullets: [
                                "Creditors and bureaus must review claims where signature cards or consent were involuntary.",
                                "You can dispute authorized-user status and demand removal from accounts you didn't open.",
                                "Mosaic's dispute drafts cite these exact statutory protections to safeguard your independence."
                            ],
                            linkTitle: "NNEDV Financial Abuse & Coerced Debt Guide",
                            urlString: "https://nnedv.org/content/about-financial-abuse/"
                        )

                        // Card 2: Unlinking Joint Liability & Authorized Users
                        EducationGlassCard(
                            icon: "person.crop.circle.badge.minus",
                            iconColor: Color.mosaicIndigo,
                            title: "Unlinking Joint Accounts & Authorized Cards",
                            sourceCitation: "Consumer Financial Protection Bureau (CFPB)",
                            summary: "If an ex-partner added you as an authorized user or pressured you into a joint card and ran up balances, you have specific rights to protect your score.",
                            bullets: [
                                "Authorized Users: You have the legal right to contact the card issuer and request immediate removal.",
                                "Once removed, the entire payment history and balance of that card must be deleted from your credit report.",
                                "Joint Accounts: You can request account freezing or closure to prevent additional unauthorized charges."
                            ],
                            linkTitle: "CFPB Guide to Authorized User Removal",
                            urlString: "https://www.consumerfinance.gov/ask-cfpb/am-i-responsible-for-debt-on-a-credit-card-account-if-i-am-only-an-authorized-user-en-1367/"
                        )

                        // Card 3: Credit Freezes
                        EducationGlassCard(
                            icon: "lock.shield.fill",
                            iconColor: Color.mosaicTeal,
                            title: "What a Credit Freeze Does (100% Free)",
                            sourceCitation: "Federal Trade Commission (FTC) • Federal Law",
                            summary: "A credit freeze blocks potential creditors from pulling your credit report, making it impossible for anyone—including an abusive partner or identity thief—to open new accounts in your name.",
                            bullets: [
                                "Must be requested separately at Equifax, Experian, and TransUnion (takes 5 mins each).",
                                "Placing, temporarily lifting, and managing a freeze is 100% free by federal law.",
                                "Does not affect your current credit score, job search, or existing accounts."
                            ],
                            linkTitle: "FTC Official Credit Freeze Portal",
                            urlString: "https://consumer.ftc.gov/articles/credit-freezes-and-fraud-alerts"
                        )

                        // Card 4: How the 30-Day Dispute Process Works
                        EducationGlassCard(
                            icon: "doc.text.fill",
                            iconColor: Color.mosaicAmber,
                            title: "Your 30-Day Dispute Rights (FCRA § 611)",
                            sourceCitation: "Fair Credit Reporting Act • 15 U.S.C. § 1681i",
                            summary: "When you submit a written dispute, the credit bureau has 30 days to investigate with the furnisher and verify that the debt is legally yours. If they cannot verify it, they must delete it by law.",
                            bullets: [
                                "Always send disputes by Certified Mail with Return Receipt Requested to prove delivery date.",
                                "Include copies of your photo ID and utility bill to verify your address.",
                                "Never send original documents—keep your copies in a safe, private place."
                            ],
                            linkTitle: "CFPB Official Dispute Instructions",
                            urlString: "https://www.consumerfinance.gov/ask-cfpb/how-do-i-dispute-an-error-on-my-credit-report-en-314/"
                        )

                        // Card 5: Free Non-Profit Counselors & Hotlines
                        EducationGlassCard(
                            icon: "heart.text.square.fill",
                            iconColor: Color.mosaicRose,
                            title: "Confidential Help & Non-Profit Counselors",
                            sourceCitation: "National Domestic Violence Hotline & NFCC",
                            summary: "Never pay upfront fees to commercial 'credit repair' agencies. Legitimate, non-profit credit counselors and domestic safety advocates provide free, confidential advice.",
                            bullets: [
                                "National Domestic Violence Hotline: Call 1-800-799-7233 or text 'START' to 88788 (24/7, Confidential).",
                                "NFCC (National Foundation for Credit Counseling): Free budget reviews and debt advocacy.",
                                "Legal Aid: Local civil legal assistance for victims of coerced debt and divorce separation."
                            ],
                            linkTitle: "Find a Non-Profit NFCC Counselor",
                            urlString: "https://www.nfcc.org/"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 96)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct EducationGlassCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let sourceCitation: String
    let summary: String
    let bullets: [String]
    let linkTitle: String
    let urlString: String

    var body: some View {
        LiquidGlassCard(tint: iconColor, cornerRadius: 18, borderOpacity: 0.28, contentPadding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.18))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(iconColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(sourceCitation)
                            .font(.caption2)
                            .foregroundColor(iconColor)
                    }
                    Spacer()
                }

                Text(summary)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(3)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .foregroundColor(iconColor)
                                .font(.caption.bold())
                            Text(bullet)
                                .font(.caption)
                                .foregroundColor(Color.mosaicMuted)
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.12))

                if let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack {
                            Text(linkTitle)
                                .font(.caption.bold())
                                .foregroundColor(iconColor)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2.bold())
                                .foregroundColor(iconColor)
                        }
                    }
                }
            }
        }
    }
}
