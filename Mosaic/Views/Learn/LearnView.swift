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

                        Text("Clear guidance for understanding your report and choosing your next step.")
                            .font(MosaicFont.regular(15))
                            .foregroundColor(Color.mosaicSubtle)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                            .padding(.bottom, 18)

                        Divider().overlay(Color.mosaicLine)

                        LearnRow(
                            title: "Understand your report",
                            summary: "A report lists accounts, balances, payment history, inquiries, and addresses. A score is a separate calculation.",
                            bullets: [
                                "Check names, accounts, balances, and payment history.",
                                "Compare all three bureaus; their files can differ.",
                                "A change is a reason to check, not proof of an error."
                            ],
                            linkTitle: "Read CFPB credit basics",
                            urlString: "https://www.consumerfinance.gov/consumer-tools/credit-reports-and-scores/"
                        )

                        LearnRow(
                            title: "Build financial breathing room",
                            summary: "A simple spending plan and small emergency fund can make unexpected costs easier to handle.",
                            bullets: [
                                "Plan essential bills before flexible spending.",
                                "Start with a buffer you can maintain consistently.",
                                "Rebuild savings after using them for a real emergency."
                            ],
                            linkTitle: "Explore CFPB budgeting tools",
                            urlString: "https://www.consumerfinance.gov/consumer-tools/budgeting/"
                        )

                        LearnRow(
                            title: "Protect your file",
                            summary: "A credit freeze can help stop new accounts from being opened while you review what changed.",
                            bullets: [
                                "Place a freeze separately with each bureau.",
                                "Freezes are free to place and lift.",
                                "A freeze does not change your existing score."
                            ],
                            linkTitle: "Open the FTC guide",
                            urlString: "https://consumer.ftc.gov/articles/credit-freezes-and-fraud-alerts"
                        )

                        LearnRow(
                            title: "Dispute an error",
                            summary: "Collect the report page and your records before asking a bureau or furnisher to investigate.",
                            bullets: [
                                "Describe the exact item and why it is wrong.",
                                "Send copies and keep the originals.",
                                "Keep a dated copy of everything you send."
                            ],
                            linkTitle: "Read CFPB dispute instructions",
                            urlString: "https://www.consumerfinance.gov/ask-cfpb/how-do-i-dispute-an-error-on-my-credit-report-en-314/"
                        )

                        LearnRow(
                            title: "Joint or authorized user",
                            summary: "These labels are different. A joint account can create shared responsibility; an authorized user may not be responsible for the debt.",
                            bullets: [
                                "Ask the issuer how your name is listed.",
                                "Removal may not erase prior history.",
                                "Compare the account details with your records."
                            ],
                            linkTitle: "Read the CFPB guide",
                            urlString: "https://www.consumerfinance.gov/ask-cfpb/am-i-responsible-for-debt-on-a-credit-card-account-if-i-am-only-an-authorized-user-en-1367/"
                        )

                        LearnRow(
                            title: "Get confidential support",
                            summary: "You can get help making a plan without handing your money to a credit-repair company.",
                            bullets: [
                                "Keep a record of what happened in your own words.",
                                "Use nonprofit counselors or legal aid when appropriate.",
                                "Review every Mosaic draft before sending it.",
                                "The National Domestic Violence Hotline is available 24/7.",
                                "NFCC offers nonprofit budget and debt guidance."
                            ],
                            linkTitle: "Find confidential support",
                            urlString: "https://nnedv.org/content/about-financial-abuse/"
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
    let summary: String
    let bullets: [String]
    let linkTitle: String
    let urlString: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(MosaicFont.medium(18))
                .foregroundColor(Color.mosaicInk)

            Text(summary)
                .font(MosaicFont.regular(15))
                .foregroundColor(Color.mosaicSubtle)
                .lineSpacing(3)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 9) {
                        Text("•")
                            .font(MosaicFont.medium(13))
                            .foregroundColor(Color.mosaicViolet)
                        Text(bullet)
                            .font(MosaicFont.regular(14))
                            .foregroundColor(Color.mosaicInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack {
                        Text(linkTitle)
                            .font(MosaicFont.medium(13))
                            .foregroundColor(Color.mosaicViolet)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.mosaicViolet)
                    }
                }
            }
        }
        .padding(.vertical, 18)
        .overlay(alignment: .bottom) {
            Divider().overlay(Color.mosaicLine)
        }
    }
}
