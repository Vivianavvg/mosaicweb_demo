import SwiftUI
import UniformTypeIdentifiers

struct OverviewView: View {
    @EnvironmentObject private var appState: AppState

    @State private var assistantSummary = "Your report workspace is ready. Import a report to see the changes that matter. Mosaic will explain what to review next."
    @State private var assistantReply: String?
    @State private var lastUserPrompt = ""
    @State private var prompt = ""
    @State private var isAgentProcessing = false
    @State private var showFileImporter = false
    @State private var showImportMessage = false
    @State private var importMessage = ""
    @State private var isImporting = false
    @State private var isClassifying = false
    @State private var showMoreReviewOptions = false
    @State private var showComposer = false
    @FocusState private var isPromptFocused: Bool

    private var pendingItems: [ChangeItem] {
        appState.changeItems.filter { $0.classification == nil }
    }

    private var reviewedItemCount: Int {
        appState.changeItems.count - pendingItems.count
    }

    private var currentReviewItem: ChangeItem? {
        pendingItems.first
    }

    private var openTaskCount: Int {
        appState.tasks.filter { !$0.isCompleted }.count
    }

    private var reviewStateKey: String {
        appState.changeItems
            .map { "\($0.id.uuidString):\($0.classification?.rawValue ?? "pending")" }
            .joined(separator: "|")
    }

    var body: some View {
        ZStack {
            MosaicPaletteBackground(opacity: 1.0)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    reportMetric

                    VStack(alignment: .leading, spacing: 22) {
                        if !lastUserPrompt.isEmpty {
                            userBubble(text: lastUserPrompt)
                        }

                        if lastUserPrompt.isEmpty {
                            summarySection
                            nextStepSection
                        } else if let assistantReply, !assistantReply.isEmpty {
                            Text(assistantReply)
                                .font(MosaicFont.regular(17))
                                .foregroundColor(Color.mosaicInk)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if currentReviewItem == nil || showComposer || !lastUserPrompt.isEmpty {
                composer
            }
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
        .task(id: reviewStateKey) {
            await refreshAssistantSummary()
        }
    }

    private var reportMetric: some View {
        VStack(spacing: 5) {
            Text("Your credit report")
                .font(MosaicFont.medium(27))
                .foregroundColor(Color.mosaicInk)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(pendingItems.count)")
                .font(MosaicFont.medium(54))
                .foregroundColor(Color.mosaicInk)
                .monospacedDigit()

            Text(pendingItems.count == 1 ? "CHANGE LEFT TO REVIEW" : "CHANGES LEFT TO REVIEW")
                .font(MosaicFont.medium(11))
                .tracking(1.2)
                .foregroundColor(Color.mosaicSubtle)

            if reviewedItemCount > 0 {
                Text("\(reviewedItemCount) reviewed")
                    .font(MosaicFont.regular(12))
                    .foregroundColor(Color.mosaicSubtle)
            }

            netDebtIndicator
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 30)
        .padding(.bottom, 22)
    }

    @ViewBuilder
    private var netDebtIndicator: some View {
        if let deltaCents = netBalanceDeltaCents {
            let isAdded = deltaCents > 0
            let isReduced = deltaCents < 0
            let indicatorColor = isAdded ? Color.red : (isReduced ? Color.green : Color.mosaicSubtle)
            let icon = isAdded ? "arrow.up.right" : (isReduced ? "arrow.down.right" : "arrow.right")
            let label = isAdded ? "Net debt added" : (isReduced ? "Net debt reduced" : "No net debt change")

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(label)
                    .font(MosaicFont.medium(12))
                Text(formattedCurrency(cents: abs(deltaCents)))
                    .font(MosaicFont.medium(12))
            }
            .foregroundColor(indicatorColor)
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

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mosaic summary")
                .font(MosaicFont.medium(12))
                .tracking(0.6)
                .foregroundColor(Color.mosaicSubtle)

            Text(assistantSummary)
                .font(MosaicFont.regular(16))
                .foregroundColor(Color.mosaicInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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

            Text("Choose the answer that matches your records. Your choice tells Mosaic whether to save it, schedule a follow-up, or prepare a draft.")
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
                    subtitle: "Prepare a reviewable draft",
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

            Button {
                showFileImporter = true
            } label: {
                HStack(spacing: 9) {
                    if isImporting {
                        ProgressView()
                            .tint(Color.mosaicViolet)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text(isImporting ? "Reading report…" : "Add a credit report")
                }
                .font(MosaicFont.medium(15))
                .foregroundColor(Color.mosaicViolet)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .liquidGlass(tint: Color.mosaicLavender, cornerRadius: 16, shadowRadius: 0)
            }
            .disabled(isImporting)
            .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Try asking")
                .font(MosaicFont.medium(12))
                .tracking(0.6)
                .foregroundColor(Color.mosaicSubtle)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(suggestedQuestions, id: \.self) { question in
                    Button {
                        chooseSuggestion(question)
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .semibold))
                            Text(question)
                                .font(MosaicFont.medium(13))
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

    private func chooseSuggestion(_ question: String) {
        prompt = question
        assistantReply = nil
        showComposer = true
        isPromptFocused = true
    }

    private var suggestedQuestions: [String] {
        if appState.changeItems.isEmpty {
            return [
                "How do I upload a report?",
                "What does my report show?",
                "What should I do first?"
            ]
        }

        if openTaskCount > 0 {
            return [
                "What should I review first?",
                "Which task matters most?",
                "Explain my biggest change"
            ]
        }

        return [
            "What should I review first?",
            "Explain my biggest change",
            "What can I do next?"
        ]
    }

    private var composer: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack(alignment: .leading) {
                if prompt.isEmpty {
                    Text("Ask Mosaic…")
                        .font(MosaicFont.regular(14))
                        .foregroundColor(Color.mosaicSubtle)
                        .allowsHitTesting(false)
                }

                TextField("", text: $prompt, axis: .vertical)
                    .font(MosaicFont.regular(15))
                    .foregroundColor(Color.mosaicInk)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1...2)
                    .focused($isPromptFocused)
                    .submitLabel(.send)
                    .textInputAutocapitalization(.sentences)
                    .textFieldStyle(.plain)
                    .onSubmit(submitPrompt)
                    .onTapGesture { isPromptFocused = true }
            }
            .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { isPromptFocused = true }

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
        .padding(.vertical, 5)
        .liquidGlass(tint: Color.white.opacity(0.92), cornerRadius: 24, shadowRadius: 0)
        .padding(.horizontal, 16)
        .padding(.top, 5)
        .padding(.bottom, 6)
        .background(.clear)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { isPromptFocused = true })
    }

    private func refreshAssistantSummary() async {
        assistantSummary = localSummary
        let generatedSummary = await GeminiService.shared.generateOverviewSummary(
            changeItems: appState.changeItems,
            openTaskCount: openTaskCount
        )
        if !generatedSummary.isEmpty {
            assistantSummary = generatedSummary
        }
    }

    private var localSummary: String {
        if appState.changeItems.isEmpty {
            return "Your report workspace is ready. Import a report to see the changes that matter. Mosaic will explain what to review next."
        }
        if pendingItems.isEmpty {
            return "You reviewed every change in this report. Ask Mosaic a question or revisit a follow-up task. Mosaic keeps the next decision clear."
        }
        return "You have \(pendingItems.count) change\(pendingItems.count == 1 ? "" : "s") left to review. Start with the guided choice below and check its source page. Mosaic will help you decide what to save, revisit, or draft."
    }

    private func submitPrompt() {
        let value = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !isAgentProcessing else { return }

        lastUserPrompt = value
        prompt = ""
        assistantReply = nil
        isPromptFocused = false
        isAgentProcessing = true

        Task { @MainActor in
            if let backboardReply = await BackboardService.shared.generateAgentReply(
                userMessage: value,
                changeItems: appState.changeItems,
                openTaskCount: openTaskCount
            ), !backboardReply.isEmpty {
                assistantReply = backboardReply
            } else {
                let turn = await GeminiService.shared.generateAgentTurn(
                    userMessage: value,
                    changeItems: appState.changeItems,
                    openTaskCount: openTaskCount
                )
                if let reply = turn.reply, !reply.isEmpty {
                    assistantReply = reply
                }
            }
            isAgentProcessing = false
        }
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
