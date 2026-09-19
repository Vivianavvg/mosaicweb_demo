import Foundation

/// The cloud-backed structured workspace. Original PDF bytes and report email candidates
/// intentionally remain local; this payload contains the user's workflow data and redacted
/// report facts needed to restore the app on another device.
public struct WorkspaceState: Codable {
    public var priorSnapshot: ReportSnapshot?
    public var currentSnapshot: ReportSnapshot?
    public var changeItems: [ChangeItem]
    public var recoveryPackets: [RecoveryPacket]
    public var tasks: [TaskItem]
    public var savedItems: [ChangeItem]
    public var analytics: AnalyticsSummary
    public var letterProfile: LetterUserProfile
    public var updatedAt: Date

    public init(
        priorSnapshot: ReportSnapshot? = nil,
        currentSnapshot: ReportSnapshot? = nil,
        changeItems: [ChangeItem] = [],
        recoveryPackets: [RecoveryPacket] = [],
        tasks: [TaskItem] = [],
        savedItems: [ChangeItem] = [],
        analytics: AnalyticsSummary = AnalyticsSummary(),
        letterProfile: LetterUserProfile = LetterUserProfile(),
        updatedAt: Date = Date()
    ) {
        self.priorSnapshot = priorSnapshot
        self.currentSnapshot = currentSnapshot
        self.changeItems = changeItems
        self.recoveryPackets = recoveryPackets
        self.tasks = tasks
        self.savedItems = savedItems
        self.analytics = analytics
        self.letterProfile = letterProfile
        self.updatedAt = updatedAt
    }
}
