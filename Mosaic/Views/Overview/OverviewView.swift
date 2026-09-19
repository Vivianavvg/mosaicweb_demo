import SwiftUI
import UniformTypeIdentifiers

struct OverviewView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedTab: Int

    @State private var assistantSummary = "Upload a credit report PDF to get started. Mosaic will read it on-device, explain each change, and help you decide what to review next."
    @State private var assistantReply: String?
    @State private var lastUserPrompt = ""
    @State private var prompt = ""
    @State private var isAgentProcessing = false
    @State private var showFileImporter = false
    @State private var showImportMessage = false
    @State private var importMessage = ""
    @State private var isImporting = false
    @FocusState private var isPromptFocused: Bool

    private var openTaskCount: Int {
        appState.tasks.filter { !$0.isCompleted }.count
    }

    var body: some View {
        ZStack {
            MosaicPaletteBackground(opacity: 1.0)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    reportMetric
                    header

                    if appState.isDemoMode {
                        HStack(alignment: .top, spacing: 10) {
                            SyntheticBadge()
                            Text("Sample data only — not your credit report.")
                                .font(MosaicFont.regular(12))
                                .foregroundColor(Color.mosaicSubtle)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                    }

                    VStack(alignment: .leading, spacing: 22) {
                        if !lastUserPrompt.isEmpty {
                            userBubble(text: lastUserPrompt)
                        }

                        if lastUserPrompt.isEmpty {
                            Text("Your next step")
                                .font(MosaicFont.medium(12))
                                .tracking(0.6)
                                .foregroundColor(Color.mosaicSubtle)

                            Text(assistantSummary)
                                .font(MosaicFont.regular(17))
                                .foregroundColor(Color.mosaicInk)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
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

                            Button {
                                showFileImporter = true
                            } label: {
                                HStack(spacing: 10) {
                                    if isImporting {
                                        ProgressView()
                                            .tint(Color.mosaicViolet)
                                    } else {
                                        Image(systemName: "doc.badge.plus")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Color.mosaicViolet)
                                    }

                                    Text(isImporting ? "Reading report…" : "Add a credit report")
                                        .font(MosaicFont.medium(15))
                                        .foregroundColor(Color.mosaicInk)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .liquidGlass(tint: Color.mosaicLavender, cornerRadius: 18, shadowRadius: 0)
                            }
                            .disabled(isImporting)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 28)
                }
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
        .task(id: appState.changeItems.count) {
            await refreshAssistantSummary()
        }
    }

    private var reportMetric: some View {
        VStack(spacing: 5) {
            Text("\(appState.changeItems.count)")
                .font(MosaicFont.medium(54))
                .foregroundColor(Color.mosaicInk)
                .monospacedDigit()

            Text("CHANGES TO REVIEW")
                .font(MosaicFont.medium(11))
                .tracking(1.2)
                .foregroundColor(Color.mosaicSubtle)

            HStack(spacing: 18) {
                metricIndicator(icon: "rectangle.stack.fill", label: "Review", value: appState.changeItems.count)
                metricIndicator(icon: "arrow.right.circle.fill", label: "Next", value: openTaskCount)
                metricIndicator(icon: "checkmark.circle.fill", label: "Saved", value: appState.savedItems.count)
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
        .padding(.bottom, 26)
    }

    private func metricIndicator(icon: String, label: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.mosaicViolet)
            Text(label)
                .font(MosaicFont.medium(11))
                .foregroundColor(Color.mosaicInk)
            Text("\(value)")
                .font(MosaicFont.regular(11))
                .foregroundColor(Color.mosaicSubtle)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Your credit report")
                .font(MosaicFont.medium(28))
                .foregroundColor(Color.mosaicInk)
            Text("Mosaic finds important changes, explains what they mean, and helps you decide what to do next.")
                .font(MosaicFont.regular(15))
                .foregroundColor(Color.mosaicSubtle)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
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
                    Text("Ask what changed or what to do next")
                        .font(MosaicFont.regular(15))
                        .foregroundColor(Color.mosaicSubtle)
                        .allowsHitTesting(false)
                }

                TextField("", text: $prompt, axis: .vertical)
                    .font(MosaicFont.regular(15))
                    .foregroundColor(Color.mosaicInk)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1...4)
                    .focused($isPromptFocused)
                    .submitLabel(.send)
                    .textInputAutocapitalization(.sentences)
                    .textFieldStyle(.plain)
                    .onSubmit(submitPrompt)
                    .onTapGesture { isPromptFocused = true }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { isPromptFocused = true }

            Button(action: submitPrompt) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
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
        .padding(.vertical, 10)
        .liquidGlass(tint: Color.mosaicLavender, cornerRadius: 28, shadowRadius: 0)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
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
        let changeCount = appState.changeItems.count
        if changeCount == 0 {
            return "Upload a credit report PDF to get started. Mosaic will read it on-device, explain each change, and help you decide what to review next."
        }
        return "You have \(changeCount) report change\(changeCount == 1 ? "" : "s") to review. Open Review to confirm what you recognize, or ask Mosaic to explain what matters first."
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
