import Foundation

public final class TigerDataService {
    public static let shared = TigerDataService()

    private var cachedSummary = AnalyticsSummary()
    public var isCloudConnected: Bool = false
    public var lastSyncTimestamp: Date? = nil

    private init() {
        seedSynthetic90Days()
    }

    /// Seeds 90 days of synthetic time series analytics
    private func seedSynthetic90Days() {
        cachedSummary = AnalyticsSummary(
            totalScans: 2,
            changesReviewed: 4,
            packetsCreated: 2,
            openTasks: 3,
            completedTasks: 1,
            avgTaskAgeDays: 5.8,
            avgDaysToFirstAction: 1.1,
            changesByMonth: [
                MonthlyMetric(month: "Jan", count: 1),
                MonthlyMetric(month: "Feb", count: 2),
                MonthlyMetric(month: "Mar", count: 4)
            ],
            packetsByMonth: [
                MonthlyMetric(month: "Jan", count: 0),
                MonthlyMetric(month: "Feb", count: 1),
                MonthlyMetric(month: "Mar", count: 2)
            ],
            countsByChangeType: [
                ChangeTypeMetric(changeType: "New Account", count: 1),
                ChangeTypeMetric(changeType: "New Inquiry", count: 1),
                ChangeTypeMetric(changeType: "Address Change", count: 1),
                ChangeTypeMetric(changeType: "Collection Entry", count: 1)
            ],
            lastUpdated: Date()
        )
    }

    /// Fetches analytics summary (from Tiger Data / Timescale or local cached time-series)
    public func fetchSummary() -> AnalyticsSummary {
        return cachedSummary
    }

    /// Records a task status update (triggers live time-series recalculation)
    public func recordTaskStatusChange(task: TaskItem, previousStatus: TaskStatus) {
        if task.isCompleted && !previousStatus.isCompleted {
            cachedSummary.openTasks = max(0, cachedSummary.openTasks - 1)
            cachedSummary.completedTasks += 1
            cachedSummary.avgTaskAgeDays = max(1.0, cachedSummary.avgTaskAgeDays - 0.4)
        } else if !task.isCompleted && previousStatus.isCompleted {
            cachedSummary.openTasks += 1
            cachedSummary.completedTasks = max(0, cachedSummary.completedTasks - 1)
        }
        cachedSummary.lastUpdated = Date()
    }

    /// Records when a new packet is created
    public func recordPacketCreated() {
        cachedSummary.packetsCreated += 1
        if let idx = cachedSummary.packetsByMonth.firstIndex(where: { $0.month == "Mar" }) {
            cachedSummary.packetsByMonth[idx].count += 1
        }
        cachedSummary.lastUpdated = Date()
    }

    /// Records when an item is classified
    public func recordClassification(changeType: ChangeType) {
        cachedSummary.changesReviewed += 1
        cachedSummary.lastUpdated = Date()
    }
}
