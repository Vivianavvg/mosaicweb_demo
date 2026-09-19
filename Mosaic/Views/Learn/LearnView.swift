import SwiftUI

struct LearnView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                MosaicPageBackground(opacity: 0.3)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Learn")
                            .font(MosaicFont.medium(30))
                            .foregroundColor(Color.mosaicInk)

                        Text("Plain-language guidance for understanding a report, protecting your file, and choosing a next step.")
                            .font(MosaicFont.regular(15))
                            .foregroundColor(Color.mosaicSubtle)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                            .padding(.bottom, 18)

                        Divider().overlay(Color.mosaicLine)

                        LearnRow(
                            title: "Credit basics",
                            sourceCitation: "Consumer Financial Protection Bureau",
                            summary: "A credit report is a record of reported accounts and inquiries. A score is a separate calculation that may use the report to estimate repayment risk.",
                            bullets: [
                                "Check names, accounts, balances, and payment history.",
                                "Review all three bureaus because their files can differ.",
                                "Look for changes first; a change is not automatically an error."
                            ],
                            linkTitle: "Read CFPB credit basics",
                            urlString: "https://www.consumerfinance.gov/consumer-tools/credit-reports-and-scores/"
                        )

                        LearnRow(
                            title: "Budgeting with variable income",
                            sourceCitation: "Consumer Financial Protection Bureau",
                            summary: "When income changes month to month, build a plan around your reliable minimum and assign extra income deliberately.",
                            bullets: [
                                "List essential bills before flexible spending.",
                                "Keep a small buffer for low-income months.",
                                "Review the plan whenever income or due dates change."
                            ],
                            linkTitle: "Explore CFPB budgeting tools",
                            urlString: "https://www.consumerfinance.gov/consumer-tools/budgeting/"
                        )

                        LearnRow(
                            title: "Emergency funds",
                            sourceCitation: "Consumer Financial Protection Bureau",
                            summary: "A dedicated cash reserve can keep an unexpected bill from becoming high-cost debt. Start with an amount you can maintain consistently.",
                            bullets: [
                                "Choose a small first target, then build gradually.",
                                "Keep it accessible and separate from everyday spending.",
                                "Replenish it after using it for a real emergency."
                            ],
                            linkTitle: "Read about emergency savings",
                            urlString: "https://www.consumerfinance.gov/an-essential-guide-to-building-an-emergency-fund/"
                        )

                        LearnRow(
                            title: "Beginner investing",
                            sourceCitation: "Investor.gov · SEC",
                            summary: "Investing carries risk. Learn about goals, time horizon, fees, and diversification before choosing an account or investment.",
                            bullets: [
                                "Pay attention to fees and avoid promises of guaranteed returns.",
                                "Diversification can reduce the impact of one investment falling.",
                                "Use regulated sources and ask for qualified advice when needed."
                            ],
                            linkTitle: "Start with Investor.gov",
                            urlString: "https://www.investor.gov/introduction-investing"
                        )

                        LearnRow(
                            title: "Coerced debt protections",
                            sourceCitation: "CFPB · state protections",
                            summary: "If an account was opened under threat, force, fraud, or pressure, learn which records can support a factual dispute.",
                            bullets: [
                                "Write down what happened in your own words.",
                                "Keep the report page and supporting records together.",
                                "Review Mosaic’s draft before sending anything."
                            ],
                            linkTitle: "NNEDV financial abuse guide",
                            urlString: "https://nnedv.org/content/about-financial-abuse/"
                        )

                        LearnRow(
                            title: "Joint accounts and authorized users",
                            sourceCitation: "Consumer Financial Protection Bureau",
                            summary: "Understand the difference between being an authorized user and being responsible for a joint account.",
                            bullets: [
                                "Ask the issuer how your name is listed.",
                                "Authorized-user removal may not erase prior history.",
                                "Compare the account details with your records."
                            ],
                            linkTitle: "Read the CFPB guide",
                            urlString: "https://www.consumerfinance.gov/ask-cfpb/am-i-responsible-for-debt-on-a-credit-card-account-if-i-am-only-an-authorized-user-en-1367/"
                        )

                        LearnRow(
                            title: "Credit freezes are free",
                            sourceCitation: "Federal Trade Commission",
                            summary: "A freeze can help stop new creditors from opening accounts using your information while you review what happened.",
                            bullets: [
                                "Place a freeze separately with each bureau.",
                                "Placing and lifting a freeze is free.",
                                "A freeze does not change your existing score."
                            ],
                            linkTitle: "Open the FTC guide",
                            urlString: "https://consumer.ftc.gov/articles/credit-freezes-and-fraud-alerts"
                        )

                        LearnRow(
                            title: "Dispute review basics",
                            sourceCitation: "FCRA § 611 · CFPB",
                            summary: "Learn what to collect before disputing an item and why keeping copies of everything matters.",
                            bullets: [
                                "Send copies, not original documents.",
                                "Keep a dated record of what you sent.",
                                "Use tracking when mailing important documents."
                            ],
                            linkTitle: "Read CFPB dispute instructions",
                            urlString: "https://www.consumerfinance.gov/ask-cfpb/how-do-i-dispute-an-error-on-my-credit-report-en-314/"
                        )

                        LearnRow(
                            title: "Confidential help",
                            sourceCitation: "NDVH · NFCC",
                            summary: "Free nonprofit counselors and confidential hotlines can help you make a plan without selling you credit-repair services.",
                            bullets: [
                                "Call 1-800-799-7233 or text START to 88788.",
                                "NFCC offers nonprofit budget and debt guidance.",
                                "Legal aid may help with complex cases."
                            ],
                            linkTitle: "Find an NFCC counselor",
                            urlString: "https://www.nfcc.org/"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 80)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct LearnRow: View {
    let title: String
    let sourceCitation: String
    let summary: String
    let bullets: [String]
    let linkTitle: String
    let urlString: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(MosaicFont.medium(18))
                .foregroundColor(Color.mosaicInk)

            Text(sourceCitation.uppercased())
                .font(MosaicFont.medium(10))
                .tracking(0.6)
                .foregroundColor(Color.mosaicMuted)

            Text(summary)
                .font(MosaicFont.regular(14))
                .foregroundColor(Color.mosaicSubtle)
                .lineSpacing(3)

            VStack(alignment: .leading, spacing: 7) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 9) {
                        Text("•")
                            .font(MosaicFont.medium(14))
                            .foregroundColor(Color.mosaicViolet)
                        Text(bullet)
                            .font(MosaicFont.regular(13))
                            .foregroundColor(Color.mosaicInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack {
                        Text(linkTitle)
                            .font(MosaicFont.medium(12))
                            .foregroundColor(Color.mosaicViolet)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.mosaicViolet)
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .overlay(alignment: .bottom) {
            Divider().overlay(Color.mosaicLine)
        }
    }
}
