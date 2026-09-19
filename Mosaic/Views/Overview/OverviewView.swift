import SwiftUI
import Charts

struct OverviewView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Credit Overview")
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text("Your verified report snapshot & active steps")
                                .font(.subheadline)
                                .foregroundColor(Color.mosaicMuted)
                        }
                        Spacer()
                        if appState.isDemoMode || (appState.currentSnapshot?.isSynthetic ?? false) {
                            SyntheticBadge()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Recent Scan Card
                    if let current = appState.currentSnapshot {
                        RecentScanCard(snapshot: current) {
                            selectedTab = 1 // Go to Scan tab
                        }
                        .padding(.horizontal, 20)
                    } else {
                        NoScanCard {
                            selectedTab = 1
                        }
                        .padding(.horizontal, 20)
                    }

                    // Open Tasks Summary
                    OpenTasksCard(tasks: appState.tasks) {
                        selectedTab = 2 // Go to Recovery tab
                    } onToggleTask: { taskId in
                        if let task = appState.tasks.first(where: { $0.id == taskId }) {
                            let newStatus: TaskStatus = task.isCompleted ? .draft : .resolved
                            appState.updateTaskStatus(taskId: taskId, newStatus: newStatus)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Financial Health & Recovery Progress Metrics (Powered by Tiger Data / Timescale)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Dispute & Progress Analytics")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.mosaicTeal)
                                    .frame(width: 6, height: 6)
                                Text("Tiger Data Live")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.mosaicTeal)
                            }
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MetricBox(
                                title: "Changes Reviewed",
                                value: "\(appState.analytics.changesReviewed)",
                                icon: "checklist",
                                color: Color.mosaicAccent
                            )
                            MetricBox(
                                title: "Packets Created",
                                value: "\(appState.analytics.packetsCreated)",
                                icon: "folder.fill",
                                color: Color.mosaicIndigo
                            )
                            MetricBox(
                                title: "Open Tasks",
                                value: "\(appState.analytics.openTasks)",
                                icon: "clock.arrow.circlepath",
                                color: Color.mosaicAmber
                            )
                            MetricBox(
                                title: "Resolved Steps",
                                value: "\(appState.analytics.completedTasks)",
                                icon: "checkmark.circle.fill",
                                color: Color.mosaicTeal
                            )
                        }

                        // Interactive Chart (90-Day Trend from Tiger Data)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Monthly Activity Trend")
                                    .font(.caption.bold())
                                    .foregroundColor(Color.mosaicMuted)
                                Spacer()
                                HStack(spacing: 8) {
                                    HStack(spacing: 4) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.mosaicAccent)
                                            .frame(width: 8, height: 8)
                                        Text("Reviewed")
                                            .font(.system(size: 9))
                                            .foregroundColor(Color.mosaicMuted)
                                    }
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.mosaicTeal)
                                            .frame(width: 8, height: 8)
                                        Text("Packets")
                                            .font(.system(size: 9))
                                            .foregroundColor(Color.mosaicMuted)
                                    }
                                }
                            }

                            Chart {
                                ForEach(appState.analytics.changesByMonth) { item in
                                    BarMark(
                                        x: .value("Month", item.month),
                                        y: .value("Changes", item.count)
                                    )
                                    .foregroundStyle(Color.mosaicAccent.gradient)
                                    .cornerRadius(4)
                                }
                                ForEach(appState.analytics.packetsByMonth) { item in
                                    LineMark(
                                        x: .value("Month", item.month),
                                        y: .value("Packets", item.count)
                                    )
                                    .foregroundStyle(Color.mosaicTeal)
                                    .symbol(.circle)
                                }
                            }
                            .frame(height: 110)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        }
                        .padding(.top, 6)

                        // Time-series Turnaround Metric
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(Color.mosaicAccent)
                            Text("Avg Response Tracking: \(String(format: "%.1f", appState.analytics.avgTaskAgeDays)) days")
                                .font(.footnote)
                                .foregroundColor(Color.mosaicMuted)
                            Spacer()
                            Text("90-day window")
                                .font(.system(size: 11))
                                .foregroundColor(Color.mosaicMuted.opacity(0.8))
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                    .background(Color.mosaicCardBg)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.mosaicCardBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    // Quick Actions
                    VStack(spacing: 10) {
                        Button(action: { selectedTab = 1 }) {
                            HStack {
                                Image(systemName: "doc.viewfinder.fill")
                                Text("Compare Credit Reports")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.mosaicCardBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
                        }

                        Button(action: { selectedTab = 2 }) {
                            HStack {
                                Image(systemName: "envelope.badge.fill")
                                Text("Manage Dispute Drafts")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.mosaicCardBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.mosaicNavy.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

private struct RecentScanCard: View {
    let snapshot: ReportSnapshot
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Active Report Snapshot", systemImage: "doc.text.fill")
                        .font(.headline)
                        .foregroundColor(Color.mosaicAccent)
                    Spacer()
                    Text("\(snapshot.pageCount) Pages")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                }

                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accounts")
                            .font(.caption)
                            .foregroundColor(Color.mosaicMuted)
                        Text("\(snapshot.accounts.count)")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Inquiries")
                            .font(.caption)
                            .foregroundColor(Color.mosaicMuted)
                        Text("\(snapshot.inquiries.count)")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Addresses")
                            .font(.caption)
                            .foregroundColor(Color.mosaicMuted)
                        Text("\(snapshot.addresses.count)")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                }

                Divider().background(Color.mosaicCardBorder)

                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.mosaicTeal)
                    Text("Local Fingerprint: \(snapshot.localFingerprint.prefix(18))...")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color.mosaicMuted)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption.bold())
                        .foregroundColor(Color.mosaicAccent)
                }
            }
            .padding(16)
            .background(Color.mosaicCardBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.mosaicCardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct NoScanCard: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 36))
                .foregroundColor(Color.mosaicAccent)

            Text("No Credit Report Loaded")
                .font(.headline)
                .foregroundColor(.white)

            Text("Import a credit report PDF or load our synthetic demo dataset to review changes.")
                .font(.subheadline)
                .foregroundColor(Color.mosaicMuted)
                .multilineTextAlignment(.center)

            Button("Import or Load Demo", action: onStart)
                .font(.subheadline.bold())
                .foregroundColor(Color.mosaicNavy)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.mosaicAccent)
                .cornerRadius(10)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.mosaicCardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mosaicCardBorder, lineWidth: 1)
        )
    }
}

private struct OpenTasksCard: View {
    let tasks: [TaskItem]
    let onViewAll: () -> Void
    let onToggleTask: (UUID) -> Void

    var openTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Action Items & Deadlines")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("View All (\(tasks.count))", action: onViewAll)
                    .font(.caption.bold())
                    .foregroundColor(Color.mosaicAccent)
            }

            if openTasks.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.mosaicTeal)
                    Text("No pending deadlines. All tasks completed!")
                        .font(.subheadline)
                        .foregroundColor(Color.mosaicMuted)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(openTasks.prefix(2)) { task in
                    HStack(spacing: 12) {
                        Button(action: { onToggleTask(task.id) }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(task.isCompleted ? Color.mosaicTeal : Color.mosaicMuted)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("\(task.recipientType.displayName) • \(task.status.displayName)")
                                .font(.caption)
                                .foregroundColor(Color.mosaicAmber)
                        }

                        Spacer()

                        if let due = task.dueAt {
                            Text(due, style: .date)
                                .font(.caption2)
                                .foregroundColor(Color.mosaicMuted)
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color.mosaicCardBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mosaicCardBorder, lineWidth: 1)
        )
    }
}

private struct MetricBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                Spacer()
            }
            Text(value)
                .font(.title.bold())
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(Color.mosaicMuted)
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}
