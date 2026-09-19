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
        Write exactly three short, calm, plain-language sentences for a credit-report review dashboard.
        Sentence one: summarize the report at a high level. Sentence two: say what the user should look at next.
        Sentence three: say how Mosaic can help. Do not claim fraud, abuse, identity theft, or coercion.
        Use only these redacted facts: \(changeItems.count) report changes, \(openTaskCount) open tasks, categories: \(categories.isEmpty ? "none yet" : categories).
        Do not use a greeting, markdown, legal advice, or a promise of an outcome. Keep each sentence under 18 words.
        """

        if let aiText = try? await callGemini(prompt: prompt), !aiText.isEmpty {
            return capOverviewSummary(aiText)
        }

        if changeItems.isEmpty {
            return "Your report workspace is ready. Import a report to see the changes that matter. Mosaic will explain what to review next."
        }
        return "Your report has \(changeItems.count) change\(changeItems.count == 1 ? "" : "s") to review. Start with the highest-priority change and its source page. Mosaic will help you decide what to save, revisit, or draft."
    }

    private func capOverviewSummary(_ text: String) -> String {
        let sentences = text
            .replacingOccurrences(of: "\n", with: " ")
            .split { $0 == "." || $0 == "!" || $0 == "?" }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)

        guard !sentences.isEmpty else { return "" }
        return sentences.map { "\($0)." }.joined(separator: " ")
    }

    /// Gives each review card one short, neutral next step using only redacted report facts.
    public func generateRecommendedNextStep(for item: ChangeItem) async -> String {
        let safeSummary = RedactionEngine.shared.redactText(item.summary)
        let safeDelta = RedactionEngine.shared.redactText(item.deltaSummary ?? "No additional change detail")
        let prompt = """
        Write one practical next step for a consumer reviewing a credit-report change.
        Use plain language, 18 words or fewer, and begin with a verb.
        Do not claim fraud, identity theft, coercion, legal outcomes, or guaranteed deletion.
        Do not invent facts. The user must review the source page and decide what is accurate.
        Change type: \(item.changeType.displayName)
        Summary: \(safeSummary)
        Change detail: \(safeDelta)
        Source page: \(item.sourcePages.map(String.init).joined(separator: ", "))
        """

        if let aiText = try? await callGemini(prompt: prompt), !aiText.isEmpty {
            return aiText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        switch item.changeType {
        case .newInquiry:
            return "Check whether you recognize this inquiry and keep the source page for your records."
        case .collectionOrChargeoffChange:
            return "Review the source page and gather records before deciding whether to create a draft."
        case .balanceIncrease, .balanceDecrease:
            return "Compare this balance with your statements and note any difference you cannot explain."
        case .newAddress:
            return "Confirm this address belongs on your file and keep supporting records if it does not."
        default:
            return "Review the source page and compare this entry with your own records before taking action."
        }
    }

    /// Answers a focused Home-screen question using redacted report context.
    public func generateAgentTurn(
        userMessage: String,
        changeItems: [ChangeItem],
        openTaskCount: Int
    ) async -> AgentTurn {
        let safeMessage = RedactionEngine.shared.redactText(userMessage)
        let categories = changeItems.prefix(6).map { $0.changeType.displayName }.joined(separator: ", ")
        let prompt = """
        You are Mosaic Coach, a calm financial-health assistant for a privacy-first iPhone app.
        Answer the user's question in 2-4 short sentences using only this redacted context:
        - Report changes: \(changeItems.count)
        - Open follow-up tasks: \(openTaskCount)
        - Change categories: \(categories.isEmpty ? "none yet" : categories)
        User message: \(safeMessage)

        Rules:
        - Be practical and nonjudgmental.
        - Never claim fraud, abuse, identity theft, or legal outcomes.
        - Do not invent balances, scores, income, or account details.
        - Explain that Mosaic prepares drafts and actions for user review; it does not submit disputes.
        - If the user asks what to do next, prioritize reviewing the highest-severity report change and its source page.
        """

        if let aiText = try? await callGemini(prompt: prompt), !aiText.isEmpty {
            return AgentTurn(
                summary: "Mosaic Coach",
                reply: aiText.trimmingCharacters(in: .whitespacesAndNewlines),
                suggestions: suggestions(for: safeMessage)
            )
        }

        return deterministicAgentTurn(
            for: safeMessage,
            changeItems: changeItems,
            openTaskCount: openTaskCount
        )
    }

    private func suggestions(for message: String) -> [AgentSuggestion] {
        let lowercased = message.lowercased()
        if lowercased.contains("learn") || lowercased.contains("explain") {
            return [
                AgentSuggestion(label: "Open Learn", action: "open_learn"),
                AgentSuggestion(label: "Review changes", action: "review_changes")
            ]
        }
        if lowercased.contains("letter") || lowercased.contains("dispute") || lowercased.contains("draft") {
            return [
                AgentSuggestion(label: "Open Letters", action: "open_recovery"),
                AgentSuggestion(label: "Review changes", action: "review_changes")
            ]
        }
        return [
            AgentSuggestion(label: "Review changes", action: "review_changes"),
            AgentSuggestion(label: "What next?", action: "ask", prompt: "What should I do next?"),
            AgentSuggestion(label: "Explain my options", action: "open_learn")
        ]
    }

    private func deterministicAgentTurn(
        for message: String,
        changeItems: [ChangeItem],
        openTaskCount: Int
    ) -> AgentTurn {
        let lowercased = message.lowercased()
        let pendingItems = changeItems.filter { $0.classification == nil }
        let focusItem = pendingItems.max { lhs, rhs in
            severityRank(lhs.severity) < severityRank(rhs.severity)
        } ?? changeItems.first
        let changeCount = changeItems.count
        let reply: String

        if let focusItem,
           lowercased.contains("biggest") ||
           lowercased.contains("what changed") ||
           lowercased.contains("explain") {
            let issuer = RedactionEngine.shared.redactText(
                focusItem.issuerName ?? focusItem.changeType.displayName
            )
            let detail = RedactionEngine.shared.redactText(
                focusItem.deltaSummary ?? focusItem.summary
            )
            let page = focusItem.sourcePages.first.map(String.init) ?? "the report"
            reply = "The most important change to review is " + issuer + ": " + detail + ". It appears on page " + page + ". Compare that page with your records, then choose Recognize, Don't recognize, or Not sure."
        } else if lowercased.contains("review") || lowercased.contains("matter") {
            if let focusItem {
                let issuer = RedactionEngine.shared.redactText(
                    focusItem.issuerName ?? focusItem.changeType.displayName
                )
                reply = "Start with " + issuer + ". Check its source page and decide whether the entry is yours before creating any draft."
            } else {
                reply = "Import a credit report first. Mosaic will turn its changes into a short review list."
            }
        } else if lowercased.contains("upload") || (lowercased.contains("report") && changeItems.isEmpty) {
            reply = "Tap Add a credit report and choose a PDF. Mosaic reads it on-device, then shows the changes to review."
        } else if lowercased.contains("next") || lowercased.contains("do") {
            let changeWord = changeCount == 1 ? "change" : "changes"
            let taskWord = openTaskCount == 1 ? "task" : "tasks"
            reply = "Start with the highest-priority report change, then review the source page before creating any draft. You have " + String(changeCount) + " " + changeWord + " and " + String(openTaskCount) + " open follow-up " + taskWord + " in Mosaic."
        } else if lowercased.contains("learn") {
            reply = "Open Learn for sourced explanations, then return to Review when you are ready to decide what the report entry means."
        } else if lowercased.contains("letter") || lowercased.contains("dispute") {
            reply = "I can prepare a reviewable draft in Letters. Confirm the facts and recipient before opening it in Mail."
        } else {
            reply = "I can explain a report change, help you choose what to review, or prepare a draft after you confirm the facts."
        }

        return AgentTurn(
            summary: "Mosaic Coach",
            reply: reply,
            suggestions: suggestions(for: message)
        )
    }

    private func severityRank(_ severity: ChangeSeverity) -> Int {
        switch severity {
        case .urgentReview: return 3
        case .review: return 2
        case .informational: return 1
        }
    }

    public func generateDraft(
        item: ChangeItem,
        classification: UserClassification,
        documentType: PacketDocumentType,
        profile: LetterUserProfile = LetterUserProfile()
    ) async -> String {
        let prompt = """
        Create a short email-style credit report draft.
        Format EXACTLY:
        TOPIC: <one short subject line>
        ISSUE: <one short sentence>
        Then the letter body.

        Facts:
        - Item: \(item.summary)
        - Issuer: \(item.issuerName ?? "Unknown")
        - Masked Account: \(item.relatedAccountLast4 ?? "Unknown")
        - Report Page: \(item.sourcePages.map(String.init).joined(separator: ", "))
        - Classification: \(classification.title)
        - Change context: \(item.deltaSummary ?? "")
        - Sender: \(profile.fullName), \(profile.mailingAddress.replacingOccurrences(of: "\n", with: ", ")), \(profile.phone), \(profile.email)
        - Document: \(documentType.title)

        Rules: never claim fraud/abuse/coercion; never promise deletion; fill From with sender info; end with NOTICE: Draft for review. Mosaic is not a lawyer or credit-repair company. Confirm the facts before sending.
        """

        do {
            if let aiText = try await callGemini(prompt: prompt) {
                return fillUserInfo(in: aiText, profile: profile)
            }
        } catch {
            print("Gemini call failed or offline: \(error.localizedDescription). Using deterministic draft template.")
        }

        return generateDeterministicDraft(
            item: item,
            classification: classification,
            documentType: documentType,
            profile: profile
        )
    }

    public func fillUserInfo(in text: String, profile: LetterUserProfile) -> String {
        var result = text
        let replacements: [(String, String)] = [
            ("[Your Full Legal Name]", profile.fullName),
            ("[insert your full legal name]", profile.fullName),
            ("[Your Printed Name]", profile.fullName),
            ("[Your Signature]", profile.fullName),
            ("[Your Mailing Address]", profile.mailingAddress),
            ("[Your Phone Number]", profile.phone),
            ("[Your Email]", profile.email),
            ("[insert date]", DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none))
        ]
        for (needle, value) in replacements {
            result = result.replacingOccurrences(of: needle, with: value)
        }
        return result
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
        request.timeoutInterval = 5
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

    public func generateDeterministicDraft(
        item: ChangeItem,
        classification: UserClassification,
        documentType: PacketDocumentType,
        profile: LetterUserProfile = LetterUserProfile()
    ) -> String {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
        let issuer = item.issuerName ?? "Credit Reporting Entity"
        let last4 = item.relatedAccountLast4.map { "**** \($0)" } ?? "**** [Last 4]"
        let pages = item.sourcePages.map(String.init).joined(separator: ", ")
        let topic = "Dispute of \(issuer) account \(last4)"
        let issue: String = {
            switch classification {
            case .unrecognized:
                return "I do not recognize this account on my credit report."
            case .someoneElseOpened:
                return "Someone else may have opened or used this account."
            case .jointOrShared:
                return "This may be a joint or shared account, so I am checking how it is reported."
            case .authorizedUser:
                return "I may be listed as an authorized user, so I am checking how it is reported."
            case .pressuredOrNotFreelyAgreed:
                return "I did not freely agree to this account appearing on my credit report."
            case .recognized:
                return "I recognize this account and am keeping a record of it."
            case .notSure:
                return "I need more time to verify this account against my records."
            case .ignored:
                return "I am not taking action on this item right now."
            }
        }()

        switch documentType {
        case .bureauDispute:
            return """
            TOPIC: \(topic)
            ISSUE: \(issue)

            \(today)

            To:
            Credit Bureau Dispute Department
            Equifax / Experian / TransUnion

            From:
            \(profile.fullName)
            \(profile.mailingAddress)
            \(profile.phone)
            \(profile.email)

            SUBJECT: \(topic)

            Dear Dispute Department,

            I am writing to dispute information on my credit report (page \(pages)).

            DISPUTED ITEM
            - Creditor: \(issuer)
            - Account: \(last4)
            - Reported standing: \(item.deltaSummary ?? "Needs review")
            - My note: \(classification.title)

            Please investigate this item under the Fair Credit Reporting Act, verify the records with the furnisher, and update any information that cannot be verified. Send me an updated report when you finish.

            Attachments I will include:
            - Photo ID
            - Proof of address
            - Copy of report page \(pages)

            Sincerely,
            \(profile.fullName)

            NOTICE: Draft for review. Mosaic is not a lawyer or credit-repair company. Confirm the facts before sending.
            """

        case .furnisherDispute:
            return """
            TOPIC: Direct dispute — \(issuer) \(last4)
            ISSUE: \(issue)

            \(today)

            To:
            \(issuer)
            Attn: Direct Dispute Department

            From:
            \(profile.fullName)
            \(profile.mailingAddress)
            \(profile.phone)
            \(profile.email)

            SUBJECT: Direct dispute for account \(last4)

            Dear Dispute Coordinator,

            I dispute the information your organization has reported about account \(last4). Reported standing: \(item.deltaSummary ?? "Under review").

            Please investigate, verify the records, and notify each credit bureau to update any information that cannot be verified. Reply to me within 30 days.

            Sincerely,
            \(profile.fullName)

            NOTICE: Draft for review. Mosaic is not a lawyer or credit-repair company. Confirm the facts before sending.
            """

        case .ftcPrep:
            return """
            TOPIC: FTC worksheet for \(issuer)
            ISSUE: \(issue)

            Prepared for: \(profile.fullName)
            Date: \(today)
            Account: \(last4) · Report page \(pages)

            1. Company: \(issuer)
            2. What changed: \(item.deltaSummary ?? "Needs review")
            3. My classification: \(classification.title)
            4. Next official step: visit https://www.identitytheft.gov/ if you choose to file a report there yourself.

            NOTICE: This worksheet stays on your phone. Mosaic does not file reports for you.
            """

        case .evidenceChecklist:
            return """
            TOPIC: Evidence checklist — \(issuer)
            ISSUE: Keep proof with any letter you mail.

            Prepared for: \(profile.fullName)
            Account: \(last4)

            [ ] Photo ID
            [ ] Proof of address
            [ ] Credit report page \(pages)
            [ ] Certified mail tracking number
            [ ] Notes from any phone calls

            NOTICE: Draft for review. Mosaic is not a lawyer or credit-repair company.
            """

        case .freezeChecklist:
            return """
            TOPIC: Credit freeze checklist
            ISSUE: Freezes are free and you place them yourself.

            Prepared for: \(profile.fullName)

            [ ] Equifax freeze
            [ ] Experian freeze
            [ ] TransUnion freeze

            Official guide: https://consumer.ftc.gov/articles/credit-freezes-and-fraud-alerts

            NOTICE: Draft for review. Mosaic does not place freezes for you.
            """
        }
    }
}
