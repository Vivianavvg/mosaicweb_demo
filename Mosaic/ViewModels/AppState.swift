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
    @Published public var isBiometricLockEnabled: Bool = false
    @Published public var isAppLocked: Bool = false

    // Snapshots & Diff
    @Published public var priorSnapshot: ReportSnapshot? = nil
    @Published public var currentSnapshot: ReportSnapshot? = nil
    @Published public var changeItems: [ChangeItem] = []

    // Recovery & Tasks
    @Published public var recoveryPackets: [RecoveryPacket] = []
    @Published public var tasks: [TaskItem] = []

    // Analytics
    @Published public var analytics: AnalyticsSummary = TigerDataService.shared.fetchSummary()

    // UI Loading States
    @Published public var isAnalyzing: Bool = false
    @Published public var statusMessage: String? = nil

    public init() {
        // Pre-load default state
    }

    /// Logs in with demo mode bypass for judging and local test runs
    public func startDemoMode() {
        isDemoMode = true
        isAuthenticated = true
        userEmail = "judge.demo@hackhers.org"
        userName = "HackHERS Evaluator"
        userSub = "auth0|demo_judge_2026"
        loadSyntheticDemo()
    }

    /// Loads the exact December (Prior) and March (Current) synthetic fixtures
    public func loadSyntheticDemo() {
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
                    documentType: docType
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
                title: "Mail Bureau Dispute to Experian & TransUnion",
                recipientType: .bureau,
                dueAt: cal.date(byAdding: .day, value: 7, to: now),
                sentDate: cal.date(byAdding: .day, value: -2, to: now),
                status: .sent,
                notes: "Sent via USPS Certified Mail #9405 5000 0000 0000 12",
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
                title: "Complete FTC IdentityTheft.gov Worksheet",
                recipientType: .ftc,
                dueAt: cal.date(byAdding: .day, value: 3, to: now),
                sentDate: cal.date(byAdding: .day, value: -1, to: now),
                status: .resolved,
                notes: "Reference worksheet completed and filed locally",
                ruleVersion: "FTC Identity Theft Guidelines",
                completedAt: now
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

    /// User marks a classification on a change item
    public func classifyItem(itemId: UUID, classification: UserClassification) {
        if let index = changeItems.firstIndex(where: { $0.id == itemId }) {
            changeItems[index].classification = classification
            TigerDataService.shared.recordClassification(changeType: changeItems[index].changeType)
            self.analytics = TigerDataService.shared.fetchSummary()
        }
    }

    /// Creates a source-linked recovery packet for an item
    public func createRecoveryPacket(for item: ChangeItem) async {
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
                documentType: docType
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
}
