import SwiftUI

struct LearnView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Consumer Rights & Education")
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text("Neutral, official guidance on credit rights and dispute laws")
                                .font(.subheadline)
                                .foregroundColor(Color.mosaicMuted)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Card 1: Credit Freezes
                    EducationCard(
                        icon: "lock.shield.fill",
                        title: "What a Credit Freeze Does",
                        sourceCitation: "Federal Trade Commission (FTC) • Verified 2026",
                        summary: "A credit freeze restricts access to your credit report, making it difficult for anyone to open new accounts in your name. By federal law, placing and lifting a freeze is completely free.",
                        bullets: [
                            "Must be requested separately at Equifax, Experian, and TransUnion.",
                            "Does not affect your current credit score or existing accounts.",
                            "Can be temporarily lifted (thawed) with a PIN or password whenever you legitimately apply for credit."
                        ],
                        linkTitle: "FTC Credit Freeze Guide",
                        urlString: "https://consumer.ftc.gov/articles/credit-freezes-and-fraud-alerts"
                    )

                    // Card 2: Fraud Alerts
                    EducationCard(
                        icon: "bell.badge.fill",
                        title: "What a Fraud Alert Does",
                        sourceCitation: "Consumer Financial Protection Bureau (CFPB) • Verified 2026",
                        summary: "A fraud alert warns creditors that you may be a victim of fraud or identity theft, requiring them to take extra steps to verify your identity before opening accounts or increasing limits.",
                        bullets: [
                            "An initial fraud alert lasts 1 year. Extended alerts last 7 years.",
                            "Contacting ANY ONE bureau automatically places the alert on all three.",
                            "Does not freeze access to your report, but prompts manual creditor verification."
                        ],
                        linkTitle: "CFPB Fraud Alert Overview",
                        urlString: "https://www.consumerfinance.gov/ask-cfpb/what-is-a-fraud-alert-en-1355/"
                    )

                    // Card 3: Dispute Process & FCRA
                    EducationCard(
                        icon: "doc.text.fill",
                        title: "How Credit Report Disputes Work",
                        sourceCitation: "Fair Credit Reporting Act (FCRA) § 611 • 15 U.S.C. § 1681i",
                        summary: "Under the Fair Credit Reporting Act, credit reporting companies and information furnishers must investigate disputed items free of charge, typically within 30 days of receiving your dispute.",
                        bullets: [
                            "Dispute in writing to both the credit bureau and the reporting furnisher.",
                            "Include copies of supporting records, never your original documents.",
                            "Send by Certified Mail with Return Receipt Requested to prove delivery date."
                        ],
                        linkTitle: "CFPB Model Dispute Guide",
                        urlString: "https://www.consumerfinance.gov/ask-cfpb/how-do-i-dispute-an-error-on-my-credit-report-en-314/"
                    )

                    // Card 4: Official Free Reports
                    EducationCard(
                        icon: "building.columns.fill",
                        title: "How to Obtain Official Credit Reports",
                        sourceCitation: "AnnualCreditReport.com • Federal Law",
                        summary: "Under federal law, you are entitled to free weekly copies of your credit reports from each of the three major nationwide bureaus through the official central website.",
                        bullets: [
                            "Only use AnnualCreditReport.com or call 1-877-322-8228.",
                            "No credit card is ever required to obtain official statutory reports.",
                            "Beware of commercial imitation sites that charge monthly membership fees."
                        ],
                        linkTitle: "Visit AnnualCreditReport.com",
                        urlString: "https://www.annualcreditreport.com/"
                    )

                    // Card 5: Credit-Builder Products (Neutral Comparison)
                    EducationCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Understanding Credit-Builder Products",
                        sourceCitation: "CFPB Consumer Education • Neutral Overview",
                        summary: "Credit-builder loans and secured cards are tools that report on-time payments to bureaus. Mosaic provides neutral information and never recommends or ranks commercial lenders.",
                        bullets: [
                            "Credit-builder loan: Funds are held in a locked savings account until paid off.",
                            "Secured credit card: Backed by a cash deposit that serves as your credit limit.",
                            "Always check interest rates, administrative fees, and whether all 3 bureaus receive reporting."
                        ],
                        linkTitle: "CFPB Credit Building Resources",
                        urlString: "https://www.consumerfinance.gov/consumer-tools/credit-reports-and-scores/"
                    )

                    // Card 6: Legal Aid & Certified Counselors
                    EducationCard(
                        icon: "person.2.badge.gearshape.fill",
                        title: "Certified Counselors & Legal Aid",
                        sourceCitation: "National Foundation for Credit Counseling (NFCC) & LSC",
                        summary: "If you need personalized advice on debt management, coerced debt, or legal rights, contact non-profit certified credit counselors or legal aid organizations.",
                        bullets: [
                            "NFCC certified credit counselors provide free or low-cost confidential budget and debt reviews.",
                            "Legal Services Corporation (LSC) helps locate local civil legal aid programs.",
                            "Never pay upfront fees to companies promising to 'erase bad credit'."
                        ],
                        linkTitle: "Find an NFCC Counselor",
                        urlString: "https://www.nfcc.org/"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.mosaicNavy.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

private struct EducationCard: View {
    let icon: String
    let title: String
    let sourceCitation: String
    let summary: String
    let bullets: [String]
    let linkTitle: String
    let urlString: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color.mosaicAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(sourceCitation)
                        .font(.caption2)
                        .foregroundColor(Color.mosaicTeal)
                }
                Spacer()
            }

            Text(summary)
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.9))
                .lineSpacing(2)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundColor(Color.mosaicAccent)
                        Text(bullet)
                            .font(.caption)
                            .foregroundColor(Color.mosaicMuted)
                    }
                }
            }

            Divider().background(Color.mosaicCardBorder)

            if let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack {
                        Text(linkTitle)
                            .font(.caption.bold())
                            .foregroundColor(Color.mosaicAccent)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption2.bold())
                            .foregroundColor(Color.mosaicAccent)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.mosaicCardBg)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mosaicCardBorder, lineWidth: 1))
    }
}
