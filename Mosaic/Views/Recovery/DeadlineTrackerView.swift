import SwiftUI

struct DeadlineTrackerView: View {
    @EnvironmentObject private var appState: AppState
    @State private var filterIndex: Int = 0

    var filteredTasks: [TaskItem] {
        switch filterIndex {
        case 1: return appState.tasks.filter { !$0.isCompleted }
        case 2: return appState.tasks.filter { $0.isCompleted }
        default: return appState.tasks
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter
            Picker("Filter", selection: $filterIndex) {
                Text("All (\(appState.tasks.count))").tag(0)
                Text("Open (\(appState.tasks.filter { !$0.isCompleted }.count))").tag(1)
                Text("Resolved (\(appState.tasks.filter { $0.isCompleted }.count))").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.mosaicNavy)

            ScrollView {
                VStack(spacing: 14) {
                    if filteredTasks.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "checkmark.seal")
                                .font(.system(size: 36))
                                .foregroundColor(Color.mosaicTeal)
                            Text("No tasks found in this view")
                                .font(.subheadline)
                                .foregroundColor(Color.mosaicMuted)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredTasks) { task in
                            TaskRowCard(task: task) {
                                let newStatus: TaskStatus = task.isCompleted ? .draft : .resolved
                                appState.updateTaskStatus(taskId: task.id, newStatus: newStatus)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color.mosaicNavy.ignoresSafeArea())
        .navigationTitle("Deadline & Status Tracker")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TaskRowCard: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(task.isCompleted ? Color.mosaicTeal : Color.mosaicMuted)
                }
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(task.isCompleted ? Color.mosaicMuted : .white)
                        .strikethrough(task.isCompleted)

                    HStack(spacing: 8) {
                        Text(task.recipientType.displayName)
                            .font(.caption.bold())
                            .foregroundColor(Color.mosaicAccent)

                        Text("•")
                            .foregroundColor(Color.mosaicMuted)

                        Text(task.status.displayName)
                            .font(.caption.bold())
                            .foregroundColor(task.isCompleted ? Color.mosaicTeal : Color.mosaicAmber)
                    }
                }

                Spacer()
            }

            Divider().background(Color.mosaicCardBorder)

            // Metadata & Details
            VStack(alignment: .leading, spacing: 4) {
                if let due = task.dueAt {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Color.mosaicAmber)
                            .font(.caption)
                        Text("Due Date: \(DateFormatter.localizedString(from: due, dateStyle: .medium, timeStyle: .none))")
                            .font(.caption)
                            .foregroundColor(Color.mosaicMuted)
                    }
                }

                if let method = task.deliveryMethod {
                    HStack {
                        Image(systemName: "shippingbox")
                            .foregroundColor(Color.mosaicAccent)
                            .font(.caption)
                        Text("Delivery: \(method)")
                            .font(.caption)
                            .foregroundColor(Color.mosaicMuted)
                    }
                }

                if !task.notes.isEmpty {
                    Text("Notes: \(task.notes)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 2)
                }

                HStack {
                    Image(systemName: "book.closed")
                        .font(.caption2)
                        .foregroundColor(Color.mosaicMuted)
                    Text("Rule: \(task.ruleVersion)")
                        .font(.caption2)
                        .foregroundColor(Color.mosaicMuted.opacity(0.8))
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(Color.mosaicCardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mosaicCardBorder, lineWidth: 1)
        )
    }
}
