import Foundation

/// Privacy-bounded workflow state and Gemini-backed conversation service.
/// Report pages, full addresses, account numbers, abuse narratives, and identity
/// documents never enter the Backboard conversation payload.
public final class BackboardService {
    public static let shared = BackboardService()

    private static let memoryStorageKey = "mosaic.backboard.safe-memory.v1"
    private static let chatThreadStorageKey = "mosaic.backboard.thread.v1"
    private var apiKey: String { SecretsConfig.shared.backboardApiKey }
    private let baseURL = "https://app.backboard.io/api"
    private let geminiModelName = "gemini-2.5-flash"

    // Safe Workflow State Model
    public struct SafeWorkflowMemory: Codable {
        public var lastViewedPacketId: String?
        public var reminderPreference: String?
        public var selectedWorkflowState: String?
        public var priorOfficialSourceVersions: [String: String]?
        public var lastUpdated: Date?

        public init(
            lastViewedPacketId: String? = nil,
            reminderPreference: String? = "Neutral (Mosaic update)",
            selectedWorkflowState: String? = "reviewing_changes",
            priorOfficialSourceVersions: [String: String]? = [
                "FCRA": "15 U.S.C. § 1681i (Rev 2026)",
                "CFPB_REG_V": "12 CFR § 1022.43 (Rev 2026)",
                "FTC_FREEZE": "FTC Guidelines § 605A (Rev 2026)"
            ],
            lastUpdated: Date? = Date()
        ) {
            self.lastViewedPacketId = lastViewedPacketId
            self.reminderPreference = reminderPreference
            self.selectedWorkflowState = selectedWorkflowState
            self.priorOfficialSourceVersions = priorOfficialSourceVersions
            self.lastUpdated = lastUpdated
        }
    }

    private var localMemory = SafeWorkflowMemory()
    private var chatThreadId: String?

    private struct MessageResponse: Decodable {
        let content: String?
        let threadId: String?
        let status: String?

        enum CodingKeys: String, CodingKey {
            case content
            case threadId = "thread_id"
            case status
        }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.memoryStorageKey),
           let savedMemory = try? JSONDecoder().decode(SafeWorkflowMemory.self, from: data) {
            localMemory = savedMemory
        }
        chatThreadId = UserDefaults.standard.string(forKey: Self.chatThreadStorageKey)
    }

    /// Asserts that a payload does not contain sensitive identifiers or narratives
    private func assertPrivacyBoundary(key: String, value: String) -> Bool {
        let prohibitedPatterns = [
            #"\b\d{3}[- ]?\d{2}[- ]?\d{4}\b"#, // SSN
            #"\b\d{12,19}\b"#,                 // full account numbers
            #"(?i)(abuse|assault|victim|domestic|trauma)"# // raw abuse narratives
        ]
        for pattern in prohibitedPatterns {
            if value.range(of: pattern, options: .regularExpression) != nil {
                print("SECURITY AUDIT FAILED: Prohibited data detected for key \(key). Rejecting Backboard persistence.")
                return false
            }
        }
        return true
    }

    /// Records the last viewed packet ID
    public func recordLastViewedPacket(id: UUID) {
        let idString = id.uuidString
        guard assertPrivacyBoundary(key: "lastViewedPacketId", value: idString) else { return }
        localMemory.lastViewedPacketId = idString
        localMemory.lastUpdated = Date()
        persistLocalMemory()
    }

    /// Updates reminder preference
    public func updateReminderPreference(_ preference: String) {
        guard assertPrivacyBoundary(key: "reminderPreference", value: preference) else { return }
        localMemory.reminderPreference = preference
        localMemory.lastUpdated = Date()
        persistLocalMemory()
    }

    /// Updates current non-sensitive workflow state
    public func updateWorkflowState(_ state: String) {
        guard assertPrivacyBoundary(key: "selectedWorkflowState", value: state) else { return }
        localMemory.selectedWorkflowState = state
        localMemory.lastUpdated = Date()
        persistLocalMemory()
    }

    /// Fetches current safe memory
    public func getMemory() -> SafeWorkflowMemory {
        return localMemory
    }

    /// Clears memory on user data wipe
    public func clearMemory() {
        localMemory = SafeWorkflowMemory()
        chatThreadId = nil
        UserDefaults.standard.removeObject(forKey: Self.memoryStorageKey)
        UserDefaults.standard.removeObject(forKey: Self.chatThreadStorageKey)
    }

    /// Sends a privacy-bounded decision brief through Backboard.
    /// Backboard owns durable conversation continuity and memory; the report itself
    /// stays on-device and only redacted change summaries enter this request.
    public func generateAgentReply(
        userMessage: String,
        changeItems: [ChangeItem],
        openTaskCount: Int
    ) async -> String? {
        guard !apiKey.isEmpty, !apiKey.hasPrefix("YOUR_") else { return nil }

        let safeMessage = RedactionEngine.shared.redactText(userMessage)
        localMemory.selectedWorkflowState = "coaching_report_review"
        localMemory.lastUpdated = Date()
        persistLocalMemory()
        let changeContext = safeChangeContext(for: changeItems)
        let memoryContext = safeMemoryContext()
        let systemPrompt = """
        You are Mosaic Continuity Coach, the decision-support layer inside a privacy-first credit-health app.
        Turn the supplied evidence into a calm, specific decision brief that helps the user take one safe next step.
        Use the workflow memory to continue the user's process instead of restarting with generic advice.
        Answer in 3 short parts: What matters, Next action, and What Mosaic can prepare.
        Keep the answer under 120 words and use plain language.
        Never claim fraud, identity theft, coercion, legal outcomes, or guaranteed deletion.
        Do not invent balances, scores, income, or account details.
        Explain that Mosaic prepares drafts for user review and never submits disputes automatically.
        If the user has no report changes yet, tell them to upload a report instead of pretending to analyze one.
        """
        let content = """
        Mosaic report context (redacted):
        Report changes: \(changeItems.count)
        Open follow-up tasks: \(openTaskCount)
        Change evidence:
        \(changeContext.isEmpty ? "none yet" : changeContext)

        Safe workflow memory:
        \(memoryContext)

        User question: \(safeMessage)
        """

        var payload: [String: Any] = [
            "content": content,
            "system_prompt": systemPrompt,
            "llm_provider": "google",
            "model_name": geminiModelName,
            "stream": false,
            "memory_pro": "Auto",
            "memory_response_citation": false,
            "web_search": "off",
            "send_to_llm": "true",
            "metadata": "{\"product\":\"mosaic\",\"feature\":\"continuity_coach\",\"privacy\":\"redacted_workflow_only\"}"
        ]
        if let chatThreadId {
            payload["thread_id"] = chatThreadId
        }

        guard let url = URL(string: "\(baseURL)/threads/messages") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                if let httpResponse = response as? HTTPURLResponse {
                    print("Backboard request failed with status \(httpResponse.statusCode)")
                }
                return nil
            }

            let result = try JSONDecoder().decode(MessageResponse.self, from: data)
            guard result.status == nil || result.status?.uppercased() == "COMPLETED" else {
                print("Backboard returned status \(result.status ?? "unknown")")
                return nil
            }
            if let threadId = result.threadId, !threadId.isEmpty {
                chatThreadId = threadId
                UserDefaults.standard.set(threadId, forKey: Self.chatThreadStorageKey)
            }
            let reply = result.content?.trimmingCharacters(in: .whitespacesAndNewlines)
            return reply?.isEmpty == false ? reply : nil
        } catch {
            print("Backboard chat unavailable: \(error.localizedDescription)")
            return nil
        }
    }

    private func persistLocalMemory() {
        guard let data = try? JSONEncoder().encode(localMemory) else { return }
        UserDefaults.standard.set(data, forKey: Self.memoryStorageKey)
    }

    private func safeChangeContext(for items: [ChangeItem]) -> String {
        items.prefix(6).enumerated().map { index, item in
            let summary = RedactionEngine.shared.redactText(item.summary)
            let delta = RedactionEngine.shared.redactText(item.deltaSummary ?? "No additional change detail")
            let classification = item.classification?.title ?? "Not reviewed"
            let pages = item.sourcePages.map(String.init).joined(separator: ", ")
            return "\(index + 1). \(item.changeType.displayName) | priority: \(item.severity.label) | page: \(pages) | status: \(classification) | summary: \(summary) | detail: \(delta)"
        }.joined(separator: "\n")
    }

    private func safeMemoryContext() -> String {
        let sources = localMemory.priorOfficialSourceVersions?.sorted { $0.key < $1.key }
            .map { "\($0.key) \($0.value)" }
            .joined(separator: "; ") ?? "none"
        return """
        Current workflow: \(localMemory.selectedWorkflowState ?? "reviewing_changes")
        Reminder preference: \(localMemory.reminderPreference ?? "Neutral (Mosaic update)")
        A letter packet was viewed previously: \(localMemory.lastViewedPacketId == nil ? "no" : "yes")
        Official source versions remembered: \(sources)
        """
    }

}
