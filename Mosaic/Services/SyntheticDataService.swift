import Foundation
import UIKit

public final class SyntheticDataService {
    public static let shared = SyntheticDataService()

    private init() {}

    /// Prior synthetic report fixture (December)
    public func loadPriorReport() -> ReportSnapshot {
        let snapshotId = UUID()
        let cal = Calendar.current
        var comps = DateComponents()
        comps.year = 2025
        comps.month = 12
        comps.day = 10
        let date = cal.date(from: comps) ?? Date()

        let account = ReportAccount(
            snapshotId: snapshotId,
            issuerName: "First National Bank Card",
            accountLast4: "4421",
            accountType: "Revolving",
            openedDate: "2023-04-15",
            balanceCents: 120000, // $1,200
            status: "Open / Current",
            paymentStatus: "Paid as agreed",
            jointIndicator: false, // Individual
            sourcePage: 2,
            extractionConfidence: 0.99,
            localFingerprint: "first national bank card_4421"
        )

        let address = ReportAddress(
            snapshotId: snapshotId,
            redactedAddressLabel: "100 Peachtree Demo Ave, Atlanta, GA",
            reportedDate: "2023-04-15",
            sourcePage: 1
        )

        return ReportSnapshot(
            id: snapshotId,
            userId: "demo_user",
            localFingerprint: "sha256:synth_dec_report_8f3d1b",
            reportDate: date,
            importedAt: date,
            pageCount: 3,
            storageMode: .localOnly,
            isSynthetic: true,
            accounts: [account],
            inquiries: [],
            addresses: [address]
        )
    }

    /// Current synthetic report fixture (March)
    public func loadCurrentReport() -> ReportSnapshot {
        let snapshotId = UUID()
        let cal = Calendar.current
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 3
        comps.day = 15
        let date = cal.date(from: comps) ?? Date()

        let cardAccount = ReportAccount(
            snapshotId: snapshotId,
            issuerName: "First National Bank Card",
            accountLast4: "4421",
            accountType: "Revolving",
            openedDate: "2023-04-15",
            balanceCents: 870000, // $8,700 (increased by $7,500)
            status: "Open / Past Due 30 Days",
            paymentStatus: "30 days past due",
            jointIndicator: true, // Modified to Joint
            sourcePage: 2,
            extractionConfidence: 0.98,
            localFingerprint: "first national bank card_4421"
        )

        let collectionAccount = ReportAccount(
            snapshotId: snapshotId,
            issuerName: "Harbor Recovery Collections",
            accountLast4: "9812",
            accountType: "Collection",
            openedDate: "2026-02-01",
            balanceCents: 214000, // $2,140
            status: "Seriously Past Due / Assigned to Collections",
            paymentStatus: "Collection account",
            jointIndicator: false,
            sourcePage: 3,
            extractionConfidence: 0.96,
            localFingerprint: "harbor recovery collections_9812"
        )

        let inquiry = ReportInquiry(
            snapshotId: snapshotId,
            inquirerName: "Northstar Lending",
            inquiryDate: "2026-02-14",
            sourcePage: 3,
            extractionConfidence: 0.99
        )

        let addressOld = ReportAddress(
            snapshotId: snapshotId,
            redactedAddressLabel: "100 Peachtree Demo Ave, Atlanta, GA",
            reportedDate: "2023-04-15",
            sourcePage: 1
        )

        let addressNew = ReportAddress(
            snapshotId: snapshotId,
            redactedAddressLabel: "44 Example Lane, Atlanta, GA",
            reportedDate: "2026-01-20",
            sourcePage: 1
        )

        return ReportSnapshot(
            id: snapshotId,
            userId: "demo_user",
            localFingerprint: "sha256:synth_mar_report_3a9e22",
            reportDate: date,
            importedAt: date,
            pageCount: 3,
            storageMode: .localOnly,
            isSynthetic: true,
            accounts: [cardAccount, collectionAccount],
            inquiries: [inquiry],
            addresses: [addressOld, addressNew]
        )
    }

    /// Generates sample synthetic text simulating a credit report PDF
    public func syntheticReportText(month: String) -> String {
        if month.lowercased().contains("dec") {
            return """
            SYNTHETIC DEMO CREDIT REPORT — DECEMBER 2025
            Consumer: DEMO CONSUMER (SSN: [SSN REDACTED])
            Current Address: 100 Peachtree Demo Ave, Atlanta, GA

            --- PAGE 2 ---
            REVOLVING ACCOUNTS:
            Issuer: First National Bank Card
            Account: **** 4421
            Status: Open / Paid as agreed
            Type: Individual
            Current Balance: $1,200.00
            High Credit: $2,500.00
            Opened: 04/15/2023

            --- PAGE 3 ---
            COLLECTION ACCOUNTS: None
            HARD INQUIRIES: None in the past 24 months
            """
        } else {
            return """
            SYNTHETIC DEMO CREDIT REPORT — MARCH 2026
            Consumer: DEMO CONSUMER (SSN: [SSN REDACTED])
            Current Address: 44 Example Lane, Atlanta, GA
            Previous Address: 100 Peachtree Demo Ave, Atlanta, GA

            --- PAGE 2 ---
            REVOLVING ACCOUNTS:
            Issuer: First National Bank Card
            Account: **** 4421
            Status: Past Due 30 Days
            Type: Joint Account
            Current Balance: $8,700.00
            High Credit: $10,000.00
            Opened: 04/15/2023

            --- PAGE 3 ---
            COLLECTION ACCOUNTS:
            Agency: Harbor Recovery Collections
            Reference: **** 9812
            Original Creditor: Unknown / Assigned
            Status: Active Collection
            Balance: $2,140.00
            Assigned: 02/01/2026

            HARD INQUIRIES:
            Inquirer: Northstar Lending
            Date: 02/14/2026
            Permissible Purpose: Credit Application
            """
        }
    }

    /// Generates a real multi-page synthetic credit report PDF file on disk
    public func generateSyntheticPDFFile(isCurrentReport: Bool) -> URL? {
        let fileName = isCurrentReport ? "Synthetic_Credit_Report_March_2026.pdf" : "Synthetic_Credit_Report_December_2025.pdf"
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("mosaic_synthetic", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent(fileName)

        let pageWidth: CGFloat = 612.0
        let pageHeight: CGFloat = 792.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        do {
            try renderer.writePDF(to: fileURL) { context in
                // PAGE 1: File Header & Personal Profile
                context.beginPage()
                drawPageHeader(
                    context: context,
                    pageNumber: 1,
                    title: isCurrentReport ? "CREDIT FILE DISCLOSURE — MARCH 2026" : "CREDIT FILE DISCLOSURE — DECEMBER 2025",
                    pageRect: pageRect
                )

                let p1Text = """
                CONSUMER IDENTIFICATION (SYNTHETIC DEMO DATA):
                Name: DEMO CONSUMER
                SSN: [SSN REDACTED]
                Date of Birth: [DOB REDACTED]
                Current Address: \(isCurrentReport ? "44 Example Lane, Atlanta, GA 30303" : "100 Peachtree Demo Ave, Atlanta, GA 30303")
                \(isCurrentReport ? "Prior Address: 100 Peachtree Demo Ave, Atlanta, GA 30303 (Reported: 04/15/2023)" : "")

                FILE METRICS & SCORE ESTIMATE:
                Report Date: \(isCurrentReport ? "March 15, 2026" : "December 10, 2025")
                Total Accounts: \(isCurrentReport ? "2 Accounts" : "1 Account")
                Negative Entries: \(isCurrentReport ? "1 Collection Account" : "0 Negative Items")
                Inquiries (Last 24 Months): \(isCurrentReport ? "1 Hard Inquiry" : "0 Inquiries")

                NOTE: This is a synthetic demonstration credit file created for the FinanceHER Mosaic application. All names and numbers are fictional.
                """
                drawBodyText(p1Text, in: CGRect(x: 40, y: 110, width: 532, height: 600))

                // PAGE 2: Revolving Credit Accounts
                context.beginPage()
                drawPageHeader(
                    context: context,
                    pageNumber: 2,
                    title: "REVOLVING ACCOUNTS — TRADE LINES",
                    pageRect: pageRect
                )

                let p2Text = isCurrentReport ? """
                ACCOUNT 1 OF 2:
                Creditor Name: First National Bank Card
                Account Number: **** 4421
                Account Type: Revolving / Credit Card
                Responsibility / Standing: JOINT ACCOUNT (Liability shared)
                Account Status: Open / Past Due 30 Days
                Date Opened: 04/15/2023
                Current Balance: $8,700.00
                High Credit / Credit Limit: $10,000.00
                Monthly Payment: $280.00
                Payment Status: Late 30 Days (02/2026)

                PAYMENT HISTORY:
                02/2026: 30 Days Past Due | 01/2026: Current | 12/2025: Current
                """ : """
                ACCOUNT 1 OF 1:
                Creditor Name: First National Bank Card
                Account Number: **** 4421
                Account Type: Revolving / Credit Card
                Responsibility / Standing: INDIVIDUAL ACCOUNT
                Account Status: Open / Paid as Agreed
                Date Opened: 04/15/2023
                Current Balance: $1,200.00
                High Credit / Credit Limit: $2,500.00
                Monthly Payment: $45.00
                Payment Status: Current / Paid as agreed

                PAYMENT HISTORY:
                11/2025: Current | 10/2025: Current | 09/2025: Current
                """
                drawBodyText(p2Text, in: CGRect(x: 40, y: 110, width: 532, height: 600))

                // PAGE 3: Collections & Inquiries
                context.beginPage()
                drawPageHeader(
                    context: context,
                    pageNumber: 3,
                    title: "COLLECTIONS & CREDIT INQUIRIES",
                    pageRect: pageRect
                )

                let p3Text = isCurrentReport ? """
                COLLECTION ACCOUNTS:
                Agency: Harbor Recovery Collections
                Account / Reference: **** 9812
                Original Creditor: Unknown / Retail Finance
                Date Assigned: 02/01/2026
                Original Amount: $2,140.00
                Current Balance: $2,140.00
                Status: Active Collection / Seriously Past Due

                HARD CREDIT INQUIRIES (Past 24 Months):
                Inquiring Creditor: Northstar Lending
                Inquiry Date: 02/14/2026
                Permissible Purpose: Credit Card / Loan Application

                END OF REPORT
                """ : """
                COLLECTION ACCOUNTS:
                No collection accounts or derogatory public records reported.

                HARD CREDIT INQUIRIES:
                No hard credit inquiries recorded in the past 24 months.

                END OF REPORT
                """
                drawBodyText(p3Text, in: CGRect(x: 40, y: 110, width: 532, height: 600))
            }
            return fileURL
        } catch {
            print("Failed to render synthetic PDF: \(error.localizedDescription)")
            return nil
        }
    }

    private func drawPageHeader(context: UIGraphicsPDFRendererContext, pageNumber: Int, title: String, pageRect: CGRect) {
        let bannerRect = CGRect(x: 40, y: 35, width: 532, height: 50)
        UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1.0).setFill()
        UIRectFill(bannerRect)

        let titleStyle = NSMutableParagraphStyle()
        titleStyle.alignment = .left

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.white,
            .paragraphStyle: titleStyle
        ]
        NSString(string: "SYNTHETIC DEMO REPORT • " + title).draw(in: CGRect(x: 52, y: 44, width: 420, height: 20), withAttributes: titleAttrs)

        let pageAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1.0)
        ]
        NSString(string: "PAGE \(pageNumber) OF 3").draw(in: CGRect(x: 480, y: 44, width: 80, height: 20), withAttributes: pageAttrs)
    }

    private func drawBodyText(_ text: String, in rect: CGRect) {
        let para = NSMutableParagraphStyle()
        para.lineSpacing = 4

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: para
        ]
        NSString(string: text).draw(in: rect, withAttributes: attrs)
    }
}
