import Foundation

public final class GeminiService {
    public static let shared = GeminiService()

    private var apiKey: String { SecretsConfig.shared.geminiApiKey }
    private let modelName: String = "gemini-3.6-flash"

    private init() {}

    /// Produces a short, neutral overview using only report-change categories and counts.
    /// The original report and sensitive identifiers never enter this prompt.
    public func generateOverviewSummary(changeItems: [ChangeItem], openTaskCount: Int) async -> String {
        let categories = changeItems.prefix(6).map { $0.changeType.displayName }.joined(separator: ", ")
        let prompt = """
        Write one calm, plain-language sentence for a credit-report review dashboard.
        Say what the user should look at next without claiming fraud, abuse, identity theft, or coercion.
        Use only these redacted facts: \(changeItems.count) report changes, \(openTaskCount) open tasks, categories: \(categories.isEmpty ? "none yet" : categories).
        Do not use a greeting, markdown, legal advice, or a promise of an outcome.
        """

        if let aiText = try? await callGemini(prompt: prompt), !aiText.isEmpty {
            return aiText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if changeItems.isEmpty {
            return "Your report workspace is ready. Import or review a report when you are ready."
        }
        if openTaskCount == 0 {
            return "You have \(changeItems.count) change\(changeItems.count == 1 ? "" : "s") to review and no open follow-up tasks."
        }
        return "You have \(changeItems.count) change\(changeItems.count == 1 ? "" : "s") to review and \(openTaskCount) next step\(openTaskCount == 1 ? "" : "s") waiting for you."
    }

    /// Generates structured dispute and recovery drafts using Gemini 3.6 Flash (or deterministic fallback)
    public func generateDraft(
        item: ChangeItem,
        classification: UserClassification,
        documentType: PacketDocumentType
    ) async -> String {
        let prompt = """
        You are an assistant creating neutral, user-controlled credit report dispute and preparation drafts.
        The user has reviewed their credit report and marked the following item:
        - Item: \(item.summary)
        - Issuer/Creditor: \(item.issuerName ?? "Unknown")
        - Masked Account: \(item.relatedAccountLast4 ?? "Unknown")
        - Report Page: \(item.sourcePages.map(String.init).joined(separator: ", "))
        - User's Selected Classification: "\(classification.title)"
        - Change context: \(item.deltaSummary ?? "")

        Document Type to generate: \(documentType.title)

        MANDATORY RULES:
        1. NEVER claim or assert that abuse, fraud, identity theft, or coerced debt occurred.
        2. Never state legal conclusions or promise that items will be deleted.
        3. Never recommend taking out a loan or credit card.
        4. Use neutral, factual, user-controlled language.
        5. Use bracketed prompts for any facts the user must fill in, e.g. [insert your full legal name], [insert date], [describe your records or what you recall regarding this account].
        6. Always include the standard disclaimer: "NOTICE: This draft was generated for consumer review only. Mosaic is not a law firm or credit repair organization. Confirm all facts before submitting."
        7. Provide specific guidance on attaching supporting documentation and keeping proof of mailing.
        """

        do {
            if let aiText = try await callGemini(prompt: prompt) {
                return aiText
            }
        } catch {
            print("Gemini call failed or offline: \(error.localizedDescription). Using deterministic draft template.")
        }

        // Deterministic template fallback conforming strictly to spec
        return generateDeterministicDraft(item: item, classification: classification, documentType: documentType)
    }

    private func callGemini(prompt: String) async throws -> String? {
        guard !apiKey.isEmpty, !apiKey.hasPrefix("YOUR_") else {
            return nil
        }
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2,
                "maxOutputTokens": 1024
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            return text
        }

        return nil
    }

    /// Deterministic draft generator following official CFPB / FTC guidelines
    public func generateDeterministicDraft(
        item: ChangeItem,
        classification: UserClassification,
        documentType: PacketDocumentType
    ) -> String {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
        let issuer = item.issuerName ?? "Credit Reporting Entity"
        let last4 = item.relatedAccountLast4.map { "**** \($0)" } ?? "**** [Last 4]"
        let pages = item.sourcePages.map(String.init).joined(separator: ", ")

        switch documentType {
        case .bureauDispute:
            return """
            [Date: \(today)]

            To:
            [Credit Bureau Name: Equifax / Experian / TransUnion]
            [Credit Bureau Dispute Department Address]

            From:
            [Your Full Legal Name]
            [Your Mailing Address]
            [Your Phone Number]
            [Your Social Security Number / ID Reference - Provide separately per bureau secure protocol]

            SUBJECT: Notice of Disputed Item on Credit Report — Request for Investigation under FCRA § 611 (15 U.S.C. § 1681i)

            Dear Dispute Department,

            I am writing to formally dispute inaccurate or unfamiliar information appearing on my credit report. I recently reviewed my credit file (reference page(s) \(pages)) and identified an item that requires your immediate investigation.

            DISPUTED ITEM DETAILS:
            - Creditor / Furnisher Name: \(issuer)
            - Reported Account Number: \(last4)
            - Reported Balance / Status: \(item.deltaSummary ?? "Needs Review")
            - My Review Classification: \(classification.title)

            REASON FOR DISPUTE:
            [describe what you recognize or do not recognize regarding this item. For example: "I do not recognize having opened or authorized this account," or "I believe this account was added or modified without my free consent and authorization," or "The balance/status reported is inconsistent with my records."]

            REQUESTED ACTION:
            In accordance with the Fair Credit Reporting Act (FCRA), please conduct a thorough reinvestigation of this disputed item with the furnisher, verify all source documentation, and delete or correct any inaccurate or unverified entries from my file within 30 days. Please send me an updated copy of my report upon completion.

            ATTACHMENTS ENCLOSED:
            [ ] Copy of government-issued photo ID (Driver's License / State ID)
            [ ] Proof of address (utility bill or bank statement)
            [ ] Copy of credit report page \(pages) highlighting the disputed item
            [ ] Any relevant personal records or affidavits

            Sincerely,

            ____________________________________
            [Your Signature]
            [Your Printed Name]

            --------------------------------------------------------------------------------
            NOTICE: Draft for review. Mosaic is not a lawyer or credit-repair company. Confirm the facts and current instructions before sending.
            Official Guidance: https://www.consumerfinance.gov/ask-cfpb/how-do-i-dispute-an-error-on-my-credit-report-en-314/
            """

        case .furnisherDispute:
            return """
            [Date: \(today)]

            To:
            \(issuer)
            Attn: Direct Dispute Department / Customer Relations
            [Creditor Mailing Address]

            From:
            [Your Full Legal Name]
            [Your Mailing Address]
            [Your Phone Number]

            SUBJECT: Notice of Direct Dispute under 12 CFR § 1022.43 (FCRA § 623)
            Account Identifier: \(last4)

            Dear Dispute Coordinator,

            I am writing to submit a direct dispute regarding information your organization has reported to consumer reporting agencies.

            ITEM IN DISPUTE:
            - Account Identifier: \(last4)
            - Reported Standing / Balance: \(item.deltaSummary ?? "Under review")
            - Consumer Status Selection: \(classification.title)

            EXPLANATION OF DISPUTE:
            [State the factual basis for disputing this item with the furnisher. For example: "I dispute liability for this balance. I did not enter into an agreement for this account, or my authorization was not freely given," or "I request verification of the original signed contract and all associated billing statements."]

            REQUEST:
            Please conduct an investigation of this direct dispute, review all relevant information, and report the results to me within 30 days. If the account information cannot be verified or is inaccurate, please promptly notify each credit reporting agency to update or delete the entry.

            Sincerely,

            ____________________________________
            [Your Printed Name]

            --------------------------------------------------------------------------------
            NOTICE: Draft for review. Mosaic is not a lawyer or credit-repair company. Confirm the facts and current instructions before sending.
            """

        case .ftcPrep:
            return """
            FTC IDENTITYTHEFT.GOV WORKSHEET & INCIDENT PREPARATION
            Date Prepared: \(today)
            Source Reference: Credit Report Page(s) \(pages)

            1. DISPUTED ACCOUNT FACTS:
            - Company / Creditor: \(issuer)
            - Account Number: \(last4)
            - Balance / Exposure: \(item.deltaSummary ?? "Unknown")
            - User Classification: \(classification.title)

            2. TIMELINE & RECOLLECTION WORKSHEET:
            - Approximate date you first noticed this entry: [Insert Date]
            - Do you recall applying for or signing for this account? [Yes / No / Unsure]
            - Were you pressured, misled, or denied access to account communications? [Provide details in your own words]
            - Have you contacted this creditor previously? [Details and dates, if any]

            3. RECOMMENDED OFFICIAL NEXT STEPS:
            - Visit the official Federal Trade Commission portal: https://www.identitytheft.gov/
            - Complete the step-by-step reporting wizard to generate an official FTC Identity Theft Report.
            - Retain your FTC report reference number securely.

            --------------------------------------------------------------------------------
            NOTICE: This worksheet is for personal organization only. Mosaic does not submit reports to the FTC or law enforcement on your behalf.
            """

        case .evidenceChecklist:
            return """
            EVIDENCE & DOCUMENTATION CHECKLIST
            Disputed Item: \(issuer) (\(last4))

            Gather and retain copies of the following documents in your records:
            [ ] Unaltered copy of your credit report showing the item on page \(pages).
            [ ] Copy of your valid state identification or passport.
            [ ] Current proof of residence (lease, electric/water bill, bank statement).
            [ ] Certified Mail tracking numbers and signed return receipts (Green Cards).
            [ ] Written correspondence log noting date, representative name, and summary of any phone calls.
            [ ] Any letters, billing statements, or collection notices received from \(issuer).
            [ ] FTC Identity Theft Report / Affidavit (if applicable from identitytheft.gov).
            [ ] Notes documenting your timeline and recollection of events.

            IMPORTANT RECORDKEEPING TIP:
            Always send disputes via USPS Certified Mail with Return Receipt Requested. Keep a duplicate copy of everything you mail.
            """

        case .freezeChecklist:
            return """
            CREDIT FREEZE & FRAUD ALERT CHECKLIST
            Protect your file across the three nationwide credit bureaus.

            A credit freeze stops potential creditors from pulling your credit file without your PIN/permission. It is 100% free by federal law.

            [ ] 1. EQUIFAX FREEZE:
                Online: https://www.equifax.com/personal/credit-report-services/credit-freeze/
                Phone: 1-800-349-9960
                Confirmation / PIN: [____________________]

            [ ] 2. EXPERIAN FREEZE:
                Online: https://www.experian.com/freeze/center.html
                Phone: 1-888-397-3742
                Confirmation / PIN: [____________________]

            [ ] 3. TRANSUNION FREEZE:
                Online: https://www.transunion.com/credit-freeze
                Phone: 1-888-909-8872
                Confirmation / PIN: [____________________]

            [ ] 4. FRAUD ALERT (Optional):
                Places a notice requiring creditors to take extra steps to verify your identity before opening accounts.
                Placing an alert with ANY ONE bureau automatically notifies the other two.

            Official FTC Guide: https://consumer.ftc.gov/articles/credit-freezes-and-fraud-alerts
            """
        }
    }
}
