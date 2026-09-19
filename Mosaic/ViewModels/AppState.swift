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

    /// Reads a user-selected credit report and applies any recognized demo data.
    /// Both Home and Review use this path so importing behaves the same everywhere.
    public func importCreditReport(from url: URL) async throws -> (isSynthetic: Bool, pageCount: Int) {
        let secured = url.startAccessingSecurityScopedResource()
        defer {
            if secured {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let extraction = try await PDFExtractionService.shared.extract(from: url)
        if extraction.isSynthetic {
            isDemoMode = true
            loadSyntheticDemo()
        }

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

        // Run normalized diff
        let diffChanges = ReportDiffEngine.shared.diff(current: current, prior: prior)
        self.changeItems = diffChanges

        // Seed a sample recovery packet and deadline tasks for the demo
        seedDefaultPacketAndTasks(for: diffChanges, snapshotId: current.id)

        self.analytics = TigerDataService.shared.fetchSummary()
        isAnalyzing = false
        statusMessage = nil
    }

    private func seedDefaultPacketAndTasks(for changes: [ChangeItem], snapshotId: UUID) {
        recoveryPackets.removeAll()
        tasks.removeAll()

        // Create recovery packet for the Collection item
        if let collectionChange = changes.first(where: { $0.changeType == .collectionOrChargeoffChange }) {
            var packet = RecoveryPacket(
                changeItemId: collectionChange.id,
                classificationAtCreation: .unrecognized,
                status: .readyForReview,
                itemName: collectionChange.issuerName ?? "Harbor Recovery Collections",
                itemLast4: collectionChange.relatedAccountLast4,
                sourcePage: collectionChange.sourcePages.first ?? 3
            )

            // Generate initial drafts
            for docType in PacketDocumentType.allCases {
                let text = GeminiService.shared.generateDeterministicDraft(
                    item: collectionChange,
                    classification: .unrecognized,
                    documentType: docType,
                    profile: letterProfile
                )
                packet.documents.append(PacketDocument(
                    packetId: packet.id,
                    documentType: docType,
                    draftText: text
                ))
            }

            recoveryPackets.append(packet)

            // Seed tasks
            let cal = Calendar.current
            let now = Date()
            let dueIn30 = cal.date(byAdding: .day, value: 30, to: now)

            let task1 = TaskItem(
                packetId: packet.id,
                title: "Review bureau dispute options",
                recipientType: .bureau,
                dueAt: cal.date(byAdding: .day, value: 7, to: now),
                sentDate: nil,
                status: .draft,
                notes: "Sample task only. Nothing has been sent.",
                ruleVersion: "FCRA § 611 (15 U.S.C. § 1681i)"
            )

            let task2 = TaskItem(
                packetId: packet.id,
                title: "Furnisher Direct Dispute: Harbor Recovery",
                recipientType: .furnisher,
                dueAt: dueIn30,
                sentDate: nil,
                status: .draft,
                notes: "Pending consumer signature on drafted letter",
                ruleVersion: "12 CFR § 1022.43"
            )

            let task3 = TaskItem(
                packetId: packet.id,
                title: "Review FTC IdentityTheft.gov options",
                recipientType: .ftc,
                dueAt: cal.date(byAdding: .day, value: 3, to: now),
                sentDate: nil,
                status: .draft,
                notes: "Sample task only. Mosaic does not file reports for you.",
                ruleVersion: "FTC Identity Theft Guidelines"
            )

            let task4 = TaskItem(
                packetId: packet.id,
                title: "Confirm Equifax & TransUnion Security Freezes",
                recipientType: .security,
                dueAt: cal.date(byAdding: .day, value: 5, to: now),
                sentDate: nil,
                status: .draft,
                notes: "Review freeze status at bureaus",
                ruleVersion: "Economic Growth, Regulatory Relief, and Consumer Protection Act"
            )

            tasks = [task1, task2, task3, task4]
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            if self.reviewFeedback != nil {
                self.reviewFeedback = nil
            }
        }
    }

    /// Creates a source-linked recovery packet for an item
    public func createRecoveryPacket(for item: ChangeItem) async {
        guard !undoneReviewItemIDs.contains(item.id) else { return }
        isAnalyzing = true
        statusMessage = "Generating neutral dispute and recovery drafts..."

        let classification = item.classification ?? .unrecognized
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
        }
    }

    /// One-tap local data deletion per specification
    public func deleteAllData() {
        priorSnapshot = nil
        currentSnapshot = nil
        changeItems.removeAll()
        recoveryPackets.removeAll()
        tasks.removeAll()
        savedItems.removeAll()
        reviewFeedback = nil
        letterProfile = LetterUserProfile()
        isDemoMode = false
        undoSnapshot = nil
        canUndoLastReview = false
        lastReviewedItemID = nil
        undoneReviewItemIDs.removeAll()
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
    }
}
