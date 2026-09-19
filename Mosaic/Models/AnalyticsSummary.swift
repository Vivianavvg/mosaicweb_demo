import Foundation

public struct MonthlyMetric: Identifiable, Codable, Hashable {
    public var id: String { month }
    public let month: String
    public var count: Int

    public init(month: String, count: Int) {
        self.month = month
        self.count = count
    }
}

public struct ChangeTypeMetric: Identifiable, Codable, Hashable {
    public var id: String { changeType }
    public let changeType: String
    public var count: Int

    public init(changeType: String, count: Int) {
        self.changeType = changeType
        self.count = count
    }
}

public struct AnalyticsSummary: Codable, Hashable {
    public var totalScans: Int
    public var changesReviewed: Int
    public var packetsCreated: Int
    public var openTasks: Int
    public var completedTasks: Int
    public var avgTaskAgeDays: Double
    public var avgDaysToFirstAction: Double
    public var changesByMonth: [MonthlyMetric]
    public var packetsByMonth: [MonthlyMetric]
    public var countsByChangeType: [ChangeTypeMetric]
    public var lastUpdated: Date

    public init(
        totalScans: Int = 2,
        changesReviewed: Int = 4,
        packetsCreated: Int = 2,
        openTasks: Int = 3,
        completedTasks: Int = 1,
        avgTaskAgeDays: Double = 6.4,
        avgDaysToFirstAction: Double = 1.2,
        changesByMonth: [MonthlyMetric] = [
            MonthlyMetric(month: "Jan", count: 1),
            MonthlyMetric(month: "Feb", count: 2),
            MonthlyMetric(month: "Mar", count: 4)
        ],
        packetsByMonth: [MonthlyMetric] = [
            MonthlyMetric(month: "Jan", count: 0),
            MonthlyMetric(month: "Feb", count: 1),
            MonthlyMetric(month: "Mar", count: 2)
        ],
        countsByChangeType: [ChangeTypeMetric] = [
            ChangeTypeMetric(changeType: "New Account", count: 1),
            ChangeTypeMetric(changeType: "New Inquiry", count: 1),
            ChangeTypeMetric(changeType: "Address Change", count: 1),
            ChangeTypeMetric(changeType: "Collection Entry", count: 1)
        ],
        lastUpdated: Date = Date()
    ) {
        self.totalScans = totalScans
        self.changesReviewed = changesReviewed
        self.packetsCreated = packetsCreated
        self.openTasks = openTasks
        self.completedTasks = completedTasks
        self.avgTaskAgeDays = avgTaskAgeDays
        self.avgDaysToFirstAction = avgDaysToFirstAction
        self.changesByMonth = changesByMonth
        self.packetsByMonth = packetsByMonth
        self.countsByChangeType = countsByChangeType
        self.lastUpdated = lastUpdated
    }
}
