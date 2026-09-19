import SwiftUI
import UniformTypeIdentifiers

struct OverviewView: View {
    @EnvironmentObject private var appState: AppState
    let resetToken: Int

    @State private var assistantReply: String?
    @State private var agentSuggestions: [AgentSuggestion] = []
    @State private var lastUserPrompt = ""
    @State private var prompt = ""
    @State private var isAgentProcessing = false
    @State private var showFileImporter = false
    @State private var showImportMessage = false
    @State private var importMessage = ""
    @State private var isImporting = false
    @State private var isClassifying = false
    @State private var showMoreReviewOptions = false
    @FocusState private var isPromptFocused: Bool

    init(resetToken: Int = 0) {
        self.resetToken = resetToken
    }

    private var pendingItems: [ChangeItem] {
        appState.changeItems.filter { $0.classification == nil }
    }

    private var currentReviewItem: ChangeItem? {
        pendingItems.first
    }

    private var openTaskCount: Int {
        appState.tasks.filter { !$0.isCompleted }.count
    }

    var body: some View {
        ZStack {
            MosaicPaletteBackground(opacity: 1.0)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    reportMetric
                    uploadReportAction

                    VStack(alignment: .leading, spacing: 22) {
                        if !lastUserPrompt.isEmpty {
                            userBubble(text: lastUserPrompt)
                        }

                        if lastUserPrompt.isEmpty {
                            nextStepSection
                        } else if let assistantReply, !assistantReply.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                assistantReplyView(assistantReply)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                suggestionActions
                            }
                        }

                        if isAgentProcessing {
                            ProgressView()
                                .tint(Color.mosaicViolet)
                        }

                        if lastUserPrompt.isEmpty {
                            suggestions
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 28)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // The composer lives outside this scroll view, so tapping any
                // content area dismisses the keyboard without stealing focus
                // when the user taps the message field itself.
                isPromptFocused = false
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            composer
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false,
            onCompletion: handleImport
        )
        .alert("Report import", isPresented: $showImportMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importMessage)
        }
        .onChange(of: resetToken) { _ in
            resetHomeState()
        }
    }

    private var reportMetric: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Your credit report")
                .font(MosaicFont.medium(22))
                .foregroundColor(Color.mosaicInk)
                .multilineTextAlignment(.center)

            netDebtIndicator

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(pendingItems.count)")
                    .font(MosaicFont.medium(22))
                    .foregroundColor(Color.mosaicInk)
                    .monospacedDigit()
                Text(pendingItems.count == 1 ? "change left to review" : "changes left to review")
                    .font(MosaicFont.regular(13))
                    .foregroundColor(Color.mosaicSubtle)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 20)
        .padding(.top, 52)
        .padding(.bottom, 22)
    }

    private func assistantReplyView(_ reply: String) -> some View {
        let brief = decisionBrief(from: reply)

        return VStack(alignment: .leading, spacing: 14) {
            Text("Mosaic's read")
                .font(MosaicFont.medium(18))
                .foregroundColor(Color.mosaicInk)

            decisionSection(
                title: "What matters",
                text: brief.whatMatters,
                icon: "scope"
            )
            decisionSection(
                title: "Next action",
                text: brief.nextAction,
                icon: "arrow.right.circle.fill"
            )
            decisionSection(
                title: "What Mosaic can prepare",
                text: brief.whatMosaicCanPrepare,
                icon: "doc.text.fill"
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(tint: Color.white.opacity(0.78), cornerRadius: 24, shadowRadius: 8)
    }

    private func decisionSection(title: String, text: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.mosaicViolet)
                .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(MosaicFont.medium(13))
                    .foregroundColor(Color.mosaicViolet)
                Text(text)
                    .font(MosaicFont.regular(16))
                    .foregroundColor(Color.mosaicInk)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private struct DecisionBrief {
        let whatMatters: String
        let nextAction: String
        let whatMosaicCanPrepare: String
    }

    private func decisionBrief(from reply: String) -> DecisionBrief {
        var sections: [String: String] = [:]
        var activeSection: String?

        func append(_ text: String, to key: String) {
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else { return }
            if sections[key]?.isEmpty == false {
                sections[key] = (sections[key] ?? "") + " " + cleaned
            } else {
                sections[key] = cleaned
            }
        }

        for rawLine in reply.components(separatedBy: .newlines) {
            var line = rawLine
                .replacingOccurrences(of: "**", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("- ") || line.hasPrefix("• ") {
                line = String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if line.count > 3,
               line.first?.isNumber == true,
               line.dropFirst(1).first == "." {
                line = String(line.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let normalized = line.lowercased()
            let headings: [(String, String)] = [
                ("what matters", "matters"),
                ("next action", "next"),
                ("what mosaic can prepare", "prepare")
            ]
            if let heading = headings.first(where: { normalized.hasPrefix($0.0) }) {
                activeSection = heading.1
                let remainder = String(line.dropFirst(heading.0.count))
                    .trimmingCharacters(in: CharacterSet(charactersIn: " :—-"))
                append(remainder, to: heading.1)
            } else if let activeSection {
                append(line, to: activeSection)
            }
        }

        let fallback = reply
            .components(separatedBy: .newlines)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return DecisionBrief(
            whatMatters: sections["matters"] ?? fallback,
            nextAction: sections["next"] ?? "Review the source page and confirm the facts before taking action.",
            whatMosaicCanPrepare: sections["prepare"] ?? "Mosaic can prepare an editable email draft, checklist, or follow-up reminder for your approval."
        )
    }

    private var uploadReportAction: some View {
        Button {
            showFileImporter = true
        } label: {
            HStack(spacing: 9) {
                if isImporting {
                    ProgressView()
                        .tint(Color.mosaicViolet)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(isImporting
                     ? "Reading report…"
                     : (appState.changeItems.isEmpty ? "Add a credit report" : "Import another report"))
                    .font(MosaicFont.medium(15))
            }
            .foregroundColor(Color.mosaicViolet)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .liquidGlass(tint: Color.mosaicLavender, cornerRadius: 18, shadowRadius: 0)
        }
        .disabled(isImporting)
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
        .accessibilityLabel(appState.changeItems.isEmpty ? "Add a credit report" : "Import another credit report")
        .accessibilityHint("Opens the PDF picker")
    }

    @ViewBuilder
    private var netDebtIndicator: some View {
        if let deltaCents = netBalanceDeltaCents {
            let isAdded = deltaCents > 0
            let isReduced = deltaCents < 0
            let indicatorColor = isAdded ? Color.red : (isReduced ? Color.green : Color.mosaicSubtle)
            let icon = isAdded ? "arrow.down.right" : (isReduced ? "arrow.up.right" : "arrow.right")
            let label = isAdded ? "Net debt added" : (isReduced ? "Net debt reduced" : "No net debt change")

            // Balance the leading trend icon with an invisible trailing rail so
            // the amount itself stays mathematically centered in the screen.
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(indicatorColor)
                    .frame(width: 28)
                VStack(alignment: .center, spacing: 1) {
                    Text(formattedCurrency(cents: abs(deltaCents)))
                        .font(MosaicFont.medium(48))
                        .foregroundColor(Color.mosaicInk)
                        .monospacedDigit()
                    Text(label.uppercased())
                        .font(MosaicFont.medium(11))
                        .tracking(1.1)
                        .foregroundColor(Color.mosaicSubtle)
                }
                Color.clear
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label), \(formattedCurrency(cents: abs(deltaCents)))")
        }
    }

    private var netBalanceDeltaCents: Int? {
        guard let currentSnapshot = appState.currentSnapshot,
              let priorSnapshot = appState.priorSnapshot else {
            return nil
        }

        let priorBalances = Dictionary(
            priorSnapshot.accounts.map { ($0.localFingerprint, $0.balanceCents ?? 0) },
            uniquingKeysWith: { first, _ in first }
        )
        let deltas = currentSnapshot.accounts.compactMap { account -> Int? in
            guard let currentBalance = account.balanceCents else { return nil }
            return currentBalance - (priorBalances[account.localFingerprint] ?? 0)
        }

        return deltas.isEmpty ? nil : deltas.reduce(0, +)
    }

    private func formattedCurrency(cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0"
    }

    @ViewBuilder
    private var nextStepSection: some View {
        if let item = currentReviewItem {
            reviewStepCard(for: item)
        } else if appState.changeItems.isEmpty {
            uploadReportCard
        } else {
            finishedReviewCard
        }
    }

    private func reviewStepCard(for item: ChangeItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(item.changeType.displayName)
                    .font(MosaicFont.medium(18))
                    .foregroundColor(Color.mosaicInk)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 12)
                Text("\(pendingItems.count) left")
                    .font(MosaicFont.medium(12))
                    .foregroundColor(Color.mosaicViolet)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.mosaicLavender.opacity(0.7))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.summary)
                    .font(MosaicFont.regular(15))
                    .foregroundColor(Color.mosaicSubtle)
                    .fixedSize(horizontal: false, vertical: true)
                if let deltaSummary = item.deltaSummary, !deltaSummary.isEmpty {
                    Text(deltaSummary)
                        .font(MosaicFont.medium(13))
                        .foregroundColor(Color.mosaicViolet)
                }
            }

            Text("Tell Mosaic whether this change is yours, unfamiliar, or unclear.")
                .font(MosaicFont.regular(13))
                .foregroundColor(Color.mosaicSubtle)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                reviewChoice(
                    title: "I recognize it",
                    subtitle: "Save it to my records",
                    icon: "checkmark.circle.fill",
                    tint: Color.mosaicTeal,
                    classification: .recognized,
                    item: item
                )
                reviewChoice(
                    title: "I don't recognize it",
                    subtitle: "Create an email draft · pending approval",
                    icon: "exclamationmark.triangle.fill",
                    tint: Color.mosaicViolet,
                    classification: .unrecognized,
                    item: item
                )
                reviewChoice(
                    title: "I'm not sure yet",
                    subtitle: "Remind me to check later",
                    icon: "questionmark.circle.fill",
                    tint: Color.mosaicIndigo,
                    classification: .notSure,
                    item: item
                )
            }

            DisclosureGroup(isExpanded: $showMoreReviewOptions) {
                VStack(spacing: 8) {
                    reviewChoice(title: "Joint or shared", subtitle: "This may be shared with someone else", icon: "person.2.fill", tint: Color.mosaicViolet, classification: .jointOrShared, item: item)
                    reviewChoice(title: "Authorized user", subtitle: "I may be listed on someone else's account", icon: "person.badge.key.fill", tint: Color.mosaicViolet, classification: .authorizedUser, item: item)
                    reviewChoice(title: "Someone else opened it", subtitle: "I may not have opened this account", icon: "person.crop.circle.badge.exclamationmark", tint: Color.mosaicViolet, classification: .someoneElseOpened, item: item)
                    reviewChoice(title: "I felt pressured or didn't consent", subtitle: "Create a safer follow-up path", icon: "hand.raised.fill", tint: Color.mosaicViolet, classification: .pressuredOrNotFreelyAgreed, item: item)
                }
                .padding(.top, 8)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                    Text("More situations")
                }
                .font(MosaicFont.medium(13))
                .foregroundColor(Color.mosaicViolet)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(tint: Color.white.opacity(0.78), cornerRadius: 26, shadowRadius: 8)
        .accessibilityElement(children: .contain)
    }

    private func reviewChoice(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        classification: UserClassification,
        item: ChangeItem
    ) -> some View {
        Button {
            classify(item, as: classification)
        } label: {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MosaicFont.medium(14))
                        .foregroundColor(Color.mosaicInk)
                    Text(subtitle)
                        .font(MosaicFont.regular(12))
                        .foregroundColor(Color.mosaicSubtle)
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.mosaicMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.52))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isClassifying)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }

    private var uploadReportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Start with a report", systemImage: "doc.badge.plus")
                .font(MosaicFont.medium(19))
                .foregroundColor(Color.mosaicInk)
            Text("Add a credit report and Mosaic will turn it into a short, guided list of changes.")
                .font(MosaicFont.regular(14))
                .foregroundColor(Color.mosaicSubtle)
                .fixedSize(horizontal: false, vertical: true)
            Text("Use the Add a credit report button above to choose a PDF.")
                .font(MosaicFont.regular(13))
                .foregroundColor(Color.mosaicSubtle)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(tint: Color.white.opacity(0.72), cornerRadius: 26, shadowRadius: 8)
    }

    private var finishedReviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("You're caught up", systemImage: "checkmark.circle.fill")
                .font(MosaicFont.medium(19))
                .foregroundColor(Color.mosaicTeal)
            Text("Mosaic has a decision for every change in this report.")
                .font(MosaicFont.regular(14))
                .foregroundColor(Color.mosaicSubtle)
            if openTaskCount > 0 {
                Text("You have \(openTaskCount) follow-up task\(openTaskCount == 1 ? "" : "s") to revisit.")
                    .font(MosaicFont.medium(13))
                    .foregroundColor(Color.mosaicInk)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(tint: Color.mosaicTeal.opacity(0.14), cornerRadius: 26, shadowRadius: 8)
    }

    private func classify(_ item: ChangeItem, as classification: UserClassification) {
        guard !isClassifying else { return }
        isClassifying = true
        appState.classifyItem(itemId: item.id, classification: classification)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isClassifying = false
        }
    }

    private func userBubble(text: String) -> some View {
        HStack {
            Spacer(minLength: 36)
            Text(text)
                .font(MosaicFont.regular(15))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.mosaicViolet)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Try asking")
                .font(MosaicFont.medium(16))
                .foregroundColor(Color.mosaicSubtle)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(suggestedQuestions, id: \.self) { question in
                    Button {
                        chooseSuggestion(question)
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 13, weight: .semibold))
                            Text(question)
                                .font(MosaicFont.medium(15))
                        }
                        .foregroundColor(Color.mosaicViolet)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Puts this question in the Ask Mosaic message field")
                }
            }
        }
    }

    @ViewBuilder
    private var suggestionActions: some View {
        if !agentSuggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Suggested next step")
                    .font(MosaicFont.medium(14))
                    .foregroundColor(Color.mosaicSubtle)

                ForEach(agentSuggestions) { suggestion in
                    Button {
                        handleSuggestion(suggestion)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: suggestion.action == "make_letter" ? "doc.text.fill" : "arrow.up.right")
                                .font(.system(size: 14, weight: .semibold))
                            Text(suggestion.label)
                                .font(MosaicFont.medium(14))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Color.mosaicViolet)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.mosaicLavender.opacity(0.62))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isAgentProcessing)
                    .accessibilityLabel(suggestion.label)
                }
            }
        }
    }

    private func chooseSuggestion(_ question: String) {
        prompt = question
        assistantReply = nil
        isPromptFocused = true
    }

    private var suggestedQuestions: [String] {
        if appState.changeItems.isEmpty {
            return [
                "How do I get my report?",
                "What changed?",
                "What should I do first?"
            ]
        }

        if openTaskCount > 0 {
            return [
                "What should I review first?",
                "Which task matters most?",
                "Explain the biggest change"
            ]
        }

        return [
            "What should I review first?",
            "Explain the biggest change",
            "What can I do next?"
        ]
    }

    private var composer: some View {
        HStack(alignment: .center, spacing: 10) {
            TextField("Ask Mosaic…", text: $prompt, axis: .vertical)
                .font(MosaicFont.regular(15))
                .foregroundColor(Color.mosaicInk)
                .multilineTextAlignment(.leading)
                .lineLimit(1...2)
                .focused($isPromptFocused)
                .submitLabel(.send)
                .textInputAutocapitalization(.sentences)
                .textFieldStyle(.plain)
                .onSubmit(submitPrompt)
            .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)

            Button(action: submitPrompt) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundColor(
                        prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.mosaicMuted
                            : Color(red: 0.35, green: 0.45, blue: 0.78)
                    )
            }
            .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAgentProcessing)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .liquidGlass(
            tint: Color.white.opacity(0.18),
            cornerRadius: 28,
            borderOpacity: 0.86,
            material: .ultraThinMaterial,
            shadowRadius: 0
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.clear)
    }

    private func submitPrompt() {
        let value = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !isAgentProcessing else { return }

        lastUserPrompt = value
        prompt = ""
        assistantReply = nil
        agentSuggestions = []
        isPromptFocused = false
        isAgentProcessing = true
        let intent = GeminiService.shared.classifyChatIntent(
            value,
            hasReportContext: !appState.changeItems.isEmpty
        )

        Task { @MainActor in
            if intent == .letterDraft {
                await prepareLetter(for: value)
                isAgentProcessing = false
                return
            }

            if let backboardReply = await BackboardService.shared.generateAgentReply(
                userMessage: value,
                changeItems: appState.changeItems,
                openTaskCount: openTaskCount,
                intent: intent
            ), !backboardReply.isEmpty {
                assistantReply = backboardReply
                agentSuggestions = GeminiService.shared.suggestions(
                    for: value,
                    intent: intent,
                    hasReportContext: !appState.changeItems.isEmpty
                )
            } else {
                let turn = await GeminiService.shared.generateAgentTurn(
                    userMessage: value,
                    changeItems: appState.changeItems,
                    openTaskCount: openTaskCount,
                    intent: intent
                )
                if let reply = turn.reply, !reply.isEmpty {
                    assistantReply = reply
                    agentSuggestions = turn.suggestions
                }
            }
            isAgentProcessing = false
        }
    }

    private func prepareLetter(for value: String) async {
        guard let target = draftTarget(for: value) else {
            assistantReply = "Import a credit report first, then ask me to draft an email about a specific change."
            return
        }

        let classification = draftClassification(for: value)
        let alreadyPrepared = appState.recoveryPackets.contains { $0.changeItemId == target.id }
        await appState.createRecoveryPacket(for: target, classification: classification)
        let itemName = target.issuerName ?? target.changeType.displayName
        let preparedPacket = appState.recoveryPackets.first { $0.changeItemId == target.id }
        assistantReply = alreadyPrepared
            ? "You already have a reviewable draft for \(itemName). I opened Letters so you can continue editing it."
            : "I prepared a reviewable email draft for \(itemName). Check every fact before sending."
        appState.requestedRecoveryPacketID = preparedPacket?.id
        appState.requestedTabIndex = preparedPacket == nil ? nil : 1
        agentSuggestions = []
    }

    private func handleSuggestion(_ suggestion: AgentSuggestion) {
        guard !isAgentProcessing else { return }

        if suggestion.action == "make_letter" {
            let letterPrompt = suggestion.prompt ?? "Draft a dispute letter for the most important unfamiliar change."
            lastUserPrompt = letterPrompt
            prompt = ""
            assistantReply = nil
            agentSuggestions = []
            isPromptFocused = false
            isAgentProcessing = true
            Task { @MainActor in
                await prepareLetter(for: letterPrompt)
                isAgentProcessing = false
            }
        } else if let suggestedPrompt = suggestion.prompt {
            chooseSuggestion(suggestedPrompt)
        }
    }

    private func resetHomeState() {
        lastUserPrompt = ""
        prompt = ""
        assistantReply = nil
        agentSuggestions = []
        isAgentProcessing = false
        isPromptFocused = false
        showMoreReviewOptions = false
    }

    private func draftTarget(for value: String) -> ChangeItem? {
        let lowercased = value.lowercased()
        let matchingItem = appState.changeItems.first { item in
            let searchableText = [item.issuerName, item.summary, item.changeType.displayName]
                .compactMap { $0?.lowercased() }
                .joined(separator: " ")
            let keywords = lowercased.split { !$0.isLetter && !$0.isNumber }
            return keywords.contains { keyword in
                keyword.count > 3 && searchableText.contains(keyword)
            }
        }

        return matchingItem
            ?? appState.changeItems.first(where: { $0.classification == nil })
            ?? appState.changeItems.first
    }

    private func draftClassification(for value: String) -> UserClassification {
        let lowercased = value.lowercased()
        if lowercased.contains("someone else") || lowercased.contains("not mine") || lowercased.contains("didn't open") {
            return .someoneElseOpened
        }
        if lowercased.contains("pressured") || lowercased.contains("without consent") || lowercased.contains("didn't consent") {
            return .pressuredOrNotFreelyAgreed
        }
        if lowercased.contains("joint") || lowercased.contains("shared") {
            return .jointOrShared
        }
        if lowercased.contains("authorized user") {
            return .authorizedUser
        }
        return .unrecognized
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importMessage = "Mosaic could not open that file: \(error.localizedDescription)"
            showImportMessage = true
        case .success(let urls):
            guard let url = urls.first else { return }
            Task { @MainActor in
                isImporting = true
                defer { isImporting = false }

                do {
                    let extraction = try await appState.importCreditReport(from: url)
                    if extraction.isSynthetic {
                        importMessage = "Sample report loaded. Mosaic read \(extraction.pageCount) pages and generated the review deck."
                    } else {
                        importMessage = "Mosaic read and redacted \(extraction.pageCount) pages on-device. This build can preview the extracted text, but structured account mapping for arbitrary bureau PDFs still needs to be connected."
                    }
                } catch {
                    importMessage = error.localizedDescription
                }
                showImportMessage = true
            }
        }
    }
}
