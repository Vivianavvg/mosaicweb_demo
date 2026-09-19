import SwiftUI
import UniformTypeIdentifiers

struct ScanView: View {
    @EnvironmentObject private var appState: AppState

    @State private var showFileImporter = false
    @State private var showUploadGuide = false
    @State private var showImportMessage = false
    @State private var importMessage = ""
    @State private var isImporting = false
    @State private var isClassifying = false
    @State private var cardOffset: CGFloat = 0
    @State private var recommendation = ""
    @State private var recommendationItemID: UUID?
    @State private var showPDFModal = false
    @State private var pdfURLForModal: URL?

    private var pendingItems: [ChangeItem] {
        appState.changeItems.filter { $0.classification == nil }
    }

    private var currentItem: ChangeItem? {
        pendingItems.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MosaicPageBackground(opacity: 0.3)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        intro

                        if isImporting {
                            HStack(spacing: 10) {
                                ProgressView().tint(Color.mosaicViolet)
                                Text("Reading your PDF on this device…")
                                    .font(MosaicFont.regular(13))
                                    .foregroundColor(Color.mosaicSubtle)
                            }
                        }

                        if let item = currentItem {
                            reviewDeck(item: item)
                        } else if appState.changeItems.isEmpty {
                            emptyState
                        } else {
                            finishedState
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }

                if let feedback = appState.reviewFeedback {
                    VStack {
                        Spacer()
                        HStack(spacing: 14) {
                            Text(feedback)
                                .font(MosaicFont.medium(13))
                                .foregroundColor(Color.mosaicInk)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if appState.canUndoLastReview {
                                Button("Undo") { appState.undoLastReview() }
                                    .font(MosaicFont.medium(13))
                                    .foregroundColor(Color.mosaicViolet)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.mosaicLavender.opacity(0.86))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                uploadActionBar
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
            .sheet(isPresented: $showPDFModal) {
                if let url = pdfURLForModal {
                    PDFViewerModal(url: url, title: "Report Document")
                }
            }
            .sheet(isPresented: $showUploadGuide) {
                UploadReportGuide()
            }
            .task(id: currentItem?.id) {
                await loadRecommendation(for: currentItem)
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("One item at a time")
                .font(MosaicFont.medium(28))
                .foregroundColor(Color.mosaicInk)
            Text("Mosaic explains each change, then you decide what it means.")
                .font(MosaicFont.regular(15))
                .foregroundColor(Color.mosaicSubtle)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var uploadActionBar: some View {
        VStack(spacing: 6) {
            Button {
                showFileImporter = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 15, weight: .bold))
                    Text(isImporting ? "Reading report…" : "Upload report PDF")
                        .font(MosaicFont.medium(15))
                        .tracking(0.2)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.liquidGlass(tint: Color.mosaicViolet, isProminent: true))
            .disabled(isImporting)

            Button("How do I do that?") {
                showUploadGuide = true
            }
            .font(MosaicFont.regular(12))
            .foregroundColor(Color.mosaicSubtle)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func reviewDeck(item: ChangeItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("REVIEW DECK")
                    .font(MosaicFont.medium(11))
                    .tracking(1.1)
                    .foregroundColor(Color.mosaicSubtle)
                Spacer()
                Text("\(pendingItems.count) left")
                    .font(MosaicFont.medium(12))
                    .foregroundColor(Color.mosaicViolet)
            }

            ReviewDeckCard(
                item: item,
                recommendation: recommendationItemID == item.id ? recommendation : "",
                isLoadingRecommendation: recommendationItemID == item.id && recommendation.isEmpty,
                onClassify: { classification, exit in
                    classify(item, as: classification, exit: exit)
                }
            )
            .offset(x: cardOffset)
            .rotationEffect(.degrees(Double(cardOffset / 24)))
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        guard !isClassifying,
                              abs(value.translation.width) > abs(value.translation.height) else { return }
                        cardOffset = value.translation.width
                    }
                    .onEnded { value in
                        guard !isClassifying else { return }

                        let horizontalDistance = value.translation.width
                        let isHorizontalSwipe = abs(horizontalDistance) > abs(value.translation.height)
                        if isHorizontalSwipe, horizontalDistance > 90 {
                            classify(item, as: .recognized, exit: 460)
                        } else if isHorizontalSwipe, horizontalDistance < -90 {
                            classify(item, as: .unrecognized, exit: -460)
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                cardOffset = 0
                            }
                        }
                    }
            )
            .frame(minHeight: 360)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 34, weight: .medium))
                .foregroundColor(Color.mosaicViolet)
            Text("Add your first report")
                .font(MosaicFont.medium(20))
                .foregroundColor(Color.mosaicInk)
            Text("Download a report from AnnualCreditReport.com, then upload the PDF here.")
                .font(MosaicFont.regular(14))
                .foregroundColor(Color.mosaicSubtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .liquidGlass(cornerRadius: 24, shadowRadius: 8)
    }

    private var finishedState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 34))
                .foregroundColor(Color.mosaicTeal)
            Text("You reviewed this deck")
                .font(MosaicFont.medium(20))
                .foregroundColor(Color.mosaicInk)
            Text("Open Letters to continue with any drafts you created.")
                .font(MosaicFont.regular(14))
                .foregroundColor(Color.mosaicSubtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .liquidGlass(cornerRadius: 24, shadowRadius: 8)
    }

    private func classify(_ item: ChangeItem, as classification: UserClassification, exit: CGFloat) {
        guard !isClassifying else { return }
        isClassifying = true

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            cardOffset = exit == 0 ? 0 : exit
        }

        let delay: UInt64 = exit == 0 ? 50_000_000 : 220_000_000
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            appState.classifyItem(itemId: item.id, classification: classification)
            cardOffset = 0
            isClassifying = false
        }
    }

    private func loadRecommendation(for item: ChangeItem?) async {
        guard let item else {
            recommendation = ""
            recommendationItemID = nil
            return
        }

        recommendation = ""
        recommendationItemID = item.id
        recommendation = await GeminiService.shared.generateRecommendedNextStep(for: item)
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

private struct ReviewDeckCard: View {
    let item: ChangeItem
    let recommendation: String
    let isLoadingRecommendation: Bool
    let onClassify: (UserClassification, CGFloat) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.mosaicViolet)
                    .frame(width: 44, height: 44)
                    .background(Color.mosaicMint)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.changeType.displayName)
                        .font(MosaicFont.medium(13))
                        .foregroundColor(Color.mosaicSubtle)
                    Text("Page \(item.sourcePages.map(String.init).joined(separator: ", "))")
                        .font(MosaicFont.regular(11))
                        .foregroundColor(Color.mosaicMuted)
                }
                Spacer()
                Text(item.severity.label)
                    .font(MosaicFont.medium(10))
                    .foregroundColor(Color.mosaicViolet)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.mosaicViolet.opacity(0.10))
                    .clipShape(Capsule())
            }

            Text(item.summary)
                .font(MosaicFont.medium(19))
                .foregroundColor(Color.mosaicInk)
                .fixedSize(horizontal: false, vertical: true)

            if let delta = item.deltaSummary {
                Text(delta)
                    .font(MosaicFont.regular(14))
                    .foregroundColor(Color.mosaicSubtle)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Mosaic's next step", systemImage: "sparkles")
                    .font(MosaicFont.medium(12))
                    .foregroundColor(Color.mosaicViolet)

                if isLoadingRecommendation {
                    ProgressView()
                        .tint(Color.mosaicViolet)
                } else {
                    Text(recommendation)
                        .font(MosaicFont.regular(14))
                        .foregroundColor(Color.mosaicInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) {
                Divider().overlay(Color.mosaicLine)
            }
            .overlay(alignment: .bottom) {
                Divider().overlay(Color.mosaicLine)
            }

            Text("Choose the description that best matches your records. Swipe is optional.")
                .font(MosaicFont.regular(11))
                .foregroundColor(Color.mosaicSubtle)
                .frame(maxWidth: .infinity, alignment: .center)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                decisionButton(title: "Mine", icon: "checkmark", color: Color.mosaicTeal) {
                    onClassify(.recognized, 460)
                }
                decisionButton(title: "Not mine", icon: "xmark", color: Color.mosaicPurple) {
                    onClassify(.unrecognized, -460)
                }
                decisionButton(title: "Joint / shared", icon: "person.2", color: Color.mosaicViolet) {
                    onClassify(.jointOrShared, 0)
                }
                decisionButton(title: "Authorized user", icon: "person.badge.key", color: Color.mosaicViolet) {
                    onClassify(.authorizedUser, 0)
                }
                decisionButton(title: "Someone else", icon: "person.crop.circle.badge.questionmark", color: Color.mosaicPurple) {
                    onClassify(.someoneElseOpened, -460)
                }
                decisionButton(title: "No safe consent", icon: "exclamationmark.shield", color: Color.mosaicRose) {
                    onClassify(.pressuredOrNotFreelyAgreed, 0)
                }
                decisionButton(title: "Not sure", icon: "questionmark", color: Color.mosaicSubtle) {
                    onClassify(.notSure, 0)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 360, alignment: .top)
        .liquidGlass(tint: Color.white, cornerRadius: 28, shadowRadius: 14)
    }

    private func decisionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(MosaicFont.medium(10))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch item.changeType {
        case .collectionOrChargeoffChange: return "exclamationmark.triangle.fill"
        case .newInquiry: return "magnifyingglass"
        case .newAddress: return "mappin.and.ellipse"
        case .balanceIncrease, .balanceDecrease: return "creditcard.fill"
        default: return "arrow.triangle.2.circlepath"
        }
    }
}

private struct UploadReportGuide: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("How do I do that?")
                        .font(MosaicFont.medium(28))
                        .foregroundColor(Color.mosaicInk)

                    Text("Get a report, save the PDF, then bring it back to Mosaic for a private review.")
                        .font(MosaicFont.regular(15))
                        .foregroundColor(Color.mosaicSubtle)

                    GuideStep(number: "1", title: "Open the official site", detail: "Use AnnualCreditReport.com to request your Equifax, Experian, or TransUnion report.") {
                        if let url = URL(string: "https://www.annualcreditreport.com") {
                            Link("Open AnnualCreditReport.com", destination: url)
                                .font(MosaicFont.medium(13))
                                .foregroundColor(Color.mosaicViolet)
                        }
                    }
                    GuideStep(number: "2", title: "Download the PDF", detail: "Complete the bureau’s identity checks, view the report, and choose its download or print-to-PDF option.")
                    GuideStep(number: "3", title: "Return to Mosaic", detail: "Tap Upload report PDF, choose the saved file, and wait while Mosaic reads and redacts it on-device.")
                    GuideStep(number: "4", title: "Review one item at a time", detail: "Choose Mine, Not mine, Joint / shared, Authorized user, Someone else, No safe consent, or Not sure. Mosaic keeps the decision in your review workspace.")
                }
                .padding(24)
            }
            .navigationTitle("Report upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct GuideStep<Accessory: View>: View {
    let number: String
    let title: String
    let detail: String
    private let accessory: Accessory

    init(number: String, title: String, detail: String, @ViewBuilder accessory: () -> Accessory) {
        self.number = number
        self.title = title
        self.detail = detail
        self.accessory = accessory()
    }

    init(number: String, title: String, detail: String) where Accessory == EmptyView {
        self.init(number: number, title: title, detail: detail) { EmptyView() }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text(number)
                    .font(MosaicFont.medium(13))
                    .foregroundColor(Color.mosaicViolet)
                    .frame(width: 26, height: 26)
                    .background(Color.mosaicMint)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(MosaicFont.medium(15))
                        .foregroundColor(Color.mosaicInk)
                    Text(detail)
                        .font(MosaicFont.regular(13))
                        .foregroundColor(Color.mosaicSubtle)
                        .fixedSize(horizontal: false, vertical: true)
                    accessory
                }
            }
            Divider().overlay(Color.mosaicLine)
        }
    }
}
