import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    // Auth & Demo
    @Published public var isAuthenticated: Bool = false
    @Published public var isDemoMode: Bool = false
    @Published public var userEmail: String? = nil
    @Published public var userName: String? = nil
    @Published public var userSub: String? = nil

    // Security & Lock
    @Published public var isBiometricLockEnabled: Bool {
        didSet { UserDefaults.standard.set(isBiometricLockEnabled, forKey: "mosaic.app-lock-enabled") }
    }
    @Published public var isAppLocked: Bool = false

    // Snapshots & Diff
    @Published public var priorSnapshot: ReportSnapshot? = nil
    @Published public var currentSnapshot: ReportSnapshot? = nil
    @Published public var changeItems: [ChangeItem] = []
    /// Recipient addresses found verbatim in the imported report, kept on-device.
    @Published public var reportEmailCandidates: [String] = []

    // Recovery & Tasks
    @Published public var recoveryPackets: [RecoveryPacket] = []
    @Published public var tasks: [TaskItem] = []
    /// Items the user marked as theirs — kept for reference, no letter.
    @Published public var savedItems: [ChangeItem] = []
    /// Short toast after a Review decision.
    @Published public var reviewFeedback: String? = nil
    @Published public private(set) var canUndoLastReview: Bool = false

    // Analytics
    @Published public var analytics: AnalyticsSummary = TigerDataService.shared.fetchSummary()

    // UI Loading States
    @Published public var isAnalyzing: Bool = false
    @Published public var statusMessage: String? = nil
    /// Tab index requested by a workflow action, such as Ask Mosaic creating a draft.
    @Published public var requestedTabIndex: Int? = nil
    /// Draft that should receive first attention after a workflow opens Letters.
    @Published public var requestedRecoveryPacketID: UUID? = nil
    @Published public private(set) var isCloudSynced: Bool = false
    @Published public private(set) var cloudSyncError: String?

    @Published public var letterProfile = LetterUserProfile()

    private struct ReviewUndoSnapshot {
        let changeItems: [ChangeItem]
        let recoveryPackets: [RecoveryPacket]
        let tasks: [TaskItem]
        let savedItems: [ChangeItem]
        let analytics: AnalyticsSummary
    }

    private var undoSnapshot: ReviewUndoSnapshot?
    private var undoneReviewItemIDs = Set<UUID>()
    private var lastReviewedItemID: UUID?

    public init() {
        isBiometricLockEnabled = UserDefaults.standard.bool(forKey: "mosaic.app-lock-enabled")
    }

    /// Configures the authenticated API session and restores the user's cloud workspace.
    /// The API is the source of truth for structured workflow state after sign-in.
    public func configureCloud(accessToken: String?) {
        MosaicAPIService.shared.configure(accessToken: accessToken)
        isCloudSynced = false
        cloudSyncError = nil
        guard accessToken?.isEmpty == false else { return }
        Task { @MainActor in
            await restoreCloudWorkspace()
        }
    }

    public func clearCloudCredentials() {
        MosaicAPIService.shared.clearCredentials()
        isCloudSynced = false
        cloudSyncError = nil
    }

    private var workspaceState: WorkspaceState {
        WorkspaceState(
            priorSnapshot: priorSnapshot,
            currentSnapshot: currentSnapshot,
            changeItems: changeItems,
            recoveryPackets: recoveryPackets,
            tasks: tasks,
            savedItems: savedItems,
            analytics: analytics,
            letterProfile: letterProfile
        )
    }

    private func scheduleCloudSync() {
        guard MosaicAPIService.shared.isConfigured else { return }
        Task { @MainActor in
            await syncToCloud()
        }
    }

    private func restoreCloudWorkspace() async {
        guard MosaicAPIService.shared.isConfigured else { return }
        do {
            if let workspace = try await MosaicAPIService.shared.fetchWorkspace() {
                priorSnapshot = workspace.priorSnapshot
                currentSnapshot = workspace.currentSnapshot
                changeItems = workspace.changeItems
                recoveryPackets = workspace.recoveryPackets
                tasks = workspace.tasks
                savedItems = workspace.savedItems
                analytics = workspace.analytics
                letterProfile = workspace.letterProfile
                isDemoMode = workspace.currentSnapshot?.isSynthetic == true
            } else if hasStructuredWorkspaceData {
                try await MosaicAPIService.shared.saveWorkspace(workspaceState)
            }
            isCloudSynced = true
            cloudSyncError = nil
        } catch {
            isCloudSynced = false
            cloudSyncError = error.localizedDescription
            print("Mosaic cloud restore failed: \(error.localizedDescription)")
        }
    }

    public func syncToCloud() async {
        guard MosaicAPIService.shared.isConfigured else { return }
        do {
            try await MosaicAPIService.shared.saveWorkspace(workspaceState)
            isCloudSynced = true
            cloudSyncError = nil
        } catch {
            isCloudSynced = false
            cloudSyncError = error.localizedDescription
            print("Mosaic cloud sync failed: \(error.localizedDescription)")
        }
    }

    private var hasStructuredWorkspaceData: Bool {
        priorSnapshot != nil || currentSnapshot != nil || !changeItems.isEmpty ||
            !recoveryPackets.isEmpty || !tasks.isEmpty || !savedItems.isEmpty
    }

    /// Logs in with demo mode bypass for judging and local test runs
    public func startDemoMode() {
        isDemoMode = true
        isAuthenticated = true
        userEmail = "demo@mosaic.invalid"
        userName = "Sample user"
        userSub = "auth0|demo_noor_2026"
        letterProfile = LetterUserProfile(
            fullName: "Sample user",
            mailingAddress: "Synthetic sample data — do not mail",
            phone: "",
            email: "demo@mosaic.invalid"
        )
        loadSyntheticDemo()
    }

    /// Reads a user-selected credit report into memory, seals a local copy, then parses only decrypted bytes.
    /// Synthetic detection remains unchanged for the explicit demo fixture path.
    public func importCreditReport(from url: URL) async throws -> (isSynthetic: Bool, pageCount: Int) {
        let secured = url.startAccessingSecurityScopedResource()
        defer {
            if secured {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let importedData = try Data(contentsOf: url, options: [.mappedIfSafe])
        let encryptedURL = try SecurityManager.shared.encryptPDF(
            importedData,
            originalFilename: url.lastPathComponent
        )
        let protectedData = try SecurityManager.shared.decryptPDF(at: encryptedURL)
        let extraction = try await PDFExtractionService.shared.extract(from: protectedData)
        reportEmailCandidates = PDFExtractionService.shared.emailAddresses(in: extraction.pages)
        if extraction.isSynthetic {
            isDemoMode = true
            loadSyntheticDemo()
        }
        scheduleCloudSync()

        return (isSynthetic: extraction.isSynthetic, pageCount: extraction.pageCount)
    }

    /// Loads the exact December (Prior) and March (Current) synthetic fixtures
    public func loadSyntheticDemo() {
        if (userName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userName = "Sample user"
        }
        isAnalyzing = true
        statusMessage = "Loading synthetic credit fixtures..."

        let prior = SyntheticDataService.shared.loadPriorReport()
        let current = SyntheticDataService.shared.loadCurrentReport()

        self.priorSnapshot = prior
        self.currentSnapshot = current
        if !isDemoMode {
            reportEmailCandidates = []
        }

        // Run normalized diff
        let diffChanges = ReportDiffEngine.shared.diff(current: current, prior: prior)
        self.changeItems = diffChanges

        // Seed a sample recovery packet and deadline tasks for the demo
        seedDefaultPacketAndTasks(for: diffChanges, snapshotId: current.id)

        // Replace the seeded preview letters with Gemini drafts when the key is available.
        // The deterministic copy remains visible immediately while these drafts load.
        Task { await refreshDemoLettersWithGemini() }

        self.analytics = TigerDataService.shared.fetchSummary()
        isAnalyzing = false
        statusMessage = nil
        scheduleCloudSync()
    }

    private func seedDefaultPacketAndTasks(for changes: [ChangeItem], snapshotId: UUID) {
        recoveryPackets.removeAll()
        tasks.removeAll()

        // Demo-only packet set: each item is still unclassified in Review, but
        // Letters shows several neutral, clearly synthetic draft scenarios.
        let preferredScenarios: [(ChangeType, UserClassification)] = [
            (.collectionOrChargeoffChange, .unrecognized),
            (.jointOrAuthorizedUserChange, .jointOrShared),
            (.balanceIncrease, .notSure),
            (.newInquiry, .someoneElseOpened),
            (.newAddress, .pressuredOrNotFreelyAgreed)
        ]

        let selectedChanges: [(ChangeItem, UserClassification)] = preferredScenarios.compactMap { type, classification in
            guard let change = changes.first(where: { $0.changeType == type }) else { return nil }
            return (change, classification)
        }

        let fallbackChanges = changes
            .filter { change in !selectedChanges.contains(where: { $0.0.id == change.id }) }
            .prefix(max(0, 5 - selectedChanges.count))
            .map { ($0, UserClassification.notSure) }

        let demoCases = Array((selectedChanges + fallbackChanges).prefix(5))
        let calendar = Calendar.current
        let now = Date()

        for (index, scenario) in demoCases.enumerated() {
            let change = scenario.0
            let classification = scenario.1
            var packet = RecoveryPacket(
                changeItemId: change.id,
                classificationAtCreation: classification,
                status: .readyForReview,
                itemName: change.issuerName ?? demoItemName(for: change),
                itemLast4: change.relatedAccountLast4,
                sourcePage: change.sourcePages.first ?? 1
            )

            for documentType in PacketDocumentType.allCases {
                let text = GeminiService.shared.generateDeterministicDraft(
                    item: change,
                    classification: classification,
                    documentType: documentType,
                    profile: letterProfile
                )
                packet.documents.append(PacketDocument(
                    packetId: packet.id,
                    documentType: documentType,
                    draftText: text
                ))
            }

            recoveryPackets.append(packet)

            let recipient: RecipientType = index == 0 ? .bureau : (index.isMultiple(of: 2) ? .furnisher : .bureau)
            let dueAt = calendar.date(byAdding: .day, value: 3 + (index * 4), to: now)
            tasks.append(TaskItem(
                packetId: packet.id,
                title: "Review (demoItemName(for: change)) draft",
                recipientType: recipient,
                dueAt: dueAt,
                sentDate: nil,
                status: .draft,
                notes: "Synthetic demo case only. Nothing has been sent. Mosaic does not submit disputes for you.",
                ruleVersion: index == 0 ? "FCRA § 611 (15 U.S.C. § 1681i)" : "Demo review guidance"
            ))
        }

        if let firstPacket = recoveryPackets.first {
            tasks.append(TaskItem(
                packetId: firstPacket.id,
                title: "Review FTC IdentityTheft.gov options",
                recipientType: .ftc,
                dueAt: calendar.date(byAdding: .day, value: 3, to: now),
                sentDate: nil,
                status: .draft,
                notes: "Synthetic demo case only. Mosaic does not file reports for you.",
                ruleVersion: "FTC Identity Theft Guidelines"
            ))

            tasks.append(TaskItem(
                packetId: firstPacket.id,
                title: "Confirm bureau security freezes",
                recipientType: .security,
                dueAt: calendar.date(byAdding: .day, value: 5, to: now),
                sentDate: nil,
                status: .draft,
                notes: "Synthetic demo case only. Review freeze status yourself.",
                ruleVersion: "Economic Growth, Regulatory Relief, and Consumer Protection Act"
            ))
        }
    }

    private func refreshDemoLettersWithGemini() async {
        let packetIDs = recoveryPackets.map(\ .id)

        for packetID in packetIDs {
            guard let packetIndex = recoveryPackets.firstIndex(where: { $0.id == packetID }),
                  let item = changeItems.first(where: { $0.id == recoveryPackets[packetIndex].changeItemId }),
                  let documentIndex = recoveryPackets[packetIndex].documents.firstIndex(where: { $0.documentType == .bureauDispute }) else {
                continue
            }

            let classification = recoveryPackets[packetIndex].classificationAtCreation
            let draft = await GeminiService.shared.generateDraft(
                item: item,
                classification: classification,
                documentType: .bureauDispute,
                profile: letterProfile
            )

            guard let updatedPacketIndex = recoveryPackets.firstIndex(where: { $0.id == packetID }),
                  let updatedDocumentIndex = recoveryPackets[updatedPacketIndex].documents.firstIndex(where: { $0.documentType == .bureauDispute }) else {
                continue
            }
            recoveryPackets[updatedPacketIndex].documents[updatedDocumentIndex].draftText = draft
            recoveryPackets[updatedPacketIndex].documents[updatedDocumentIndex].generatedBy = "gemini-3.6-flash"
        }

        scheduleCloudSync()
    }

    private func demoItemName(for change: ChangeItem) -> String {
        switch change.changeType {
        case .collectionOrChargeoffChange:
            return "Harbor Recovery Collections"
        case .jointOrAuthorizedUserChange:
            return "First National Bank Card"
        case .balanceIncrease:
            return "First National Bank Card balance"
        case .newInquiry:
            return "Northstar Lending inquiry"
        case .newAddress:
            return "New address entry"
        default:
            return change.summary
        }
    }

    /// User marks a classification on a change item and Mosaic takes a real next step.
    public func classifyItem(itemId: UUID, classification: UserClassification) {
        guard let index = changeItems.firstIndex(where: { $0.id == itemId }) else { return }

        undoSnapshot = ReviewUndoSnapshot(
            changeItems: changeItems,
            recoveryPackets: recoveryPackets,
            tasks: tasks,
            savedItems: savedItems,
            analytics: analytics
        )
        canUndoLastReview = true
        undoneReviewItemIDs.remove(itemId)

        changeItems[index].classification = classification
        TigerDataService.shared.recordClassification(changeType: changeItems[index].changeType)
        self.analytics = TigerDataService.shared.fetchSummary()

        let item = changeItems[index]
        lastReviewedItemID = item.id
        switch classification {
        case .recognized, .jointOrShared, .authorizedUser:
            if !savedItems.contains(where: { $0.id == item.id }) {
                savedItems.insert(item, at: 0)
            }
            reviewFeedback = "Saved for your records. You can revisit the classification in Review."
        case .unrecognized, .someoneElseOpened, .pressuredOrNotFreelyAgreed:
            if !recoveryPackets.contains(where: { $0.changeItemId == item.id }) {
                Task { await createRecoveryPacket(for: item) }
            }
            reviewFeedback = "A reviewable draft can help you ask the bureau or creditor to investigate."
        case .notSure:
            let already = tasks.contains {
                $0.title.contains(item.issuerName ?? item.summary) && !$0.isCompleted
            }
            if !already {
                let cal = Calendar.current
                tasks.append(TaskItem(
                    title: "Look again: \(item.issuerName ?? item.summary)",
                    recipientType: .other,
                    dueAt: cal.date(byAdding: .day, value: 3, to: Date()),
                    status: .draft,
                    notes: "You marked this as Not sure. Check your own records, then come back to Review."
                ))
            }
            reviewFeedback = "Parked for later. Mosaic added a 3-day reminder task."
        case .ignored:
            reviewFeedback = "Skipped. This item stays out of Letters."
        }

        BackboardService.shared.updateWorkflowState("reviewed_\(classification.rawValue)")
        scheduleCloudSync()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            if self.reviewFeedback != nil {
                self.reviewFeedback = nil
            }
        }
    }

    /// Creates a source-linked recovery packet for an item
    public func createRecoveryPacket(for item: ChangeItem, classification overrideClassification: UserClassification? = nil) async {
        guard !undoneReviewItemIDs.contains(item.id) else { return }
        guard !recoveryPackets.contains(where: { $0.changeItemId == item.id }) else { return }
        isAnalyzing = true
        statusMessage = "Generating neutral dispute and recovery drafts..."

        let classification = overrideClassification ?? item.classification ?? .unrecognized
        var packet = RecoveryPacket(
            changeItemId: item.id,
            classificationAtCreation: classification,
            status: .readyForReview,
            itemName: item.issuerName ?? item.summary,
            itemLast4: item.relatedAccountLast4,
            sourcePage: item.sourcePages.first ?? 1
        )

        for docType in PacketDocumentType.allCases {
            let draft = await GeminiService.shared.generateDraft(
                item: item,
                classification: classification,
                documentType: docType,
                profile: letterProfile
            )
            packet.documents.append(PacketDocument(
                packetId: packet.id,
                documentType: docType,
                draftText: draft
            ))
        }

        recoveryPackets.append(packet)

        // Add follow-up task
        let cal = Calendar.current
        let newTask = TaskItem(
            packetId: packet.id,
            title: "Review & Mail Dispute for \(item.issuerName ?? "Account")",
            recipientType: .bureau,
            dueAt: cal.date(byAdding: .day, value: 30, to: Date()),
            status: .draft,
            notes: "Drafted using Mosaic assistant."
        )
        tasks.append(newTask)

        TigerDataService.shared.recordPacketCreated()
        self.analytics = TigerDataService.shared.fetchSummary()

        isAnalyzing = false
        statusMessage = nil
        scheduleCloudSync()
    }

    /// Updates task status and recalculates time-series analytics immediately
    public func updateTaskStatus(taskId: UUID, newStatus: TaskStatus) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            let previous = tasks[index].status
            tasks[index].status = newStatus
            if newStatus.isCompleted {
                tasks[index].completedAt = Date()
            } else {
                tasks[index].completedAt = nil
            }
            TigerDataService.shared.recordTaskStatusChange(task: tasks[index], previousStatus: previous)
            self.analytics = TigerDataService.shared.fetchSummary()
            scheduleCloudSync()
        }
    }

    /// One-tap local data deletion per specification
    public func deleteAllData() {
        priorSnapshot = nil
        currentSnapshot = nil
        changeItems.removeAll()
        reportEmailCandidates.removeAll()
        recoveryPackets.removeAll()
        tasks.removeAll()
        savedItems.removeAll()
        reviewFeedback = nil
        requestedRecoveryPacketID = nil
        letterProfile = LetterUserProfile()
        isDemoMode = false
        undoSnapshot = nil
        canUndoLastReview = false
        lastReviewedItemID = nil
        undoneReviewItemIDs.removeAll()
        SecurityManager.shared.purgeEncryptedStore()
        SecurityManager.shared.purgeTemporaryFiles()
        BackboardService.shared.clearMemory()
        analytics = AnalyticsSummary(
            totalScans: 0,
            changesReviewed: 0,
            packetsCreated: 0,
            openTasks: 0,
            completedTasks: 0,
            avgTaskAgeDays: 0,
            avgDaysToFirstAction: 0,
            changesByMonth: [],
            packetsByMonth: [],
            countsByChangeType: [],
            lastUpdated: Date()
        )
        if MosaicAPIService.shared.isConfigured {
            Task { @MainActor in
                do {
                    try await MosaicAPIService.shared.deleteWorkspace()
                    isCloudSynced = true
                    cloudSyncError = nil
                } catch {
                    isCloudSynced = false
                    cloudSyncError = error.localizedDescription
                }
            }
        }
    }

    /// Unlocks app with biometric prompt
    public func requestUnlock() {
        SecurityManager.shared.authenticateUser { success, _ in
            if success {
                self.isAppLocked = false
            }
        }
    }

    public func lockForBackground() {
        guard isAuthenticated, isBiometricLockEnabled else { return }
        isAppLocked = true
    }

    public func undoLastReview() {
        guard let undoSnapshot else { return }
        if let lastReviewedItemID { undoneReviewItemIDs.insert(lastReviewedItemID) }
        changeItems = undoSnapshot.changeItems
        recoveryPackets = undoSnapshot.recoveryPackets
        tasks = undoSnapshot.tasks
        savedItems = undoSnapshot.savedItems
        analytics = undoSnapshot.analytics
        self.undoSnapshot = nil
        canUndoLastReview = false
        lastReviewedItemID = nil
        reviewFeedback = "Review undone. Choose a different answer when you are ready."
        scheduleCloudSync()
    }
}
