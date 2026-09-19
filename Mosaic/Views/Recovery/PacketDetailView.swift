import SwiftUI

struct PacketDetailView: View {
    @Binding var packet: RecoveryPacket
    @EnvironmentObject private var appState: AppState

    @State private var exportedPDFURL: URL?
    @State private var showShareSheet = false
    @State private var showSourcePDF = false
    @State private var sourcePDFURL: URL?
    @State private var showMore = false

    private var relatedAccount: ReportAccount? {
        appState.currentSnapshot?.accounts.first { $0.accountLast4 == packet.itemLast4 }
    }

    private var primaryDocumentID: UUID? {
        packet.documents.first { $0.documentType == .bureauDispute }?.id ?? packet.documents.first?.id
    }

    private var primaryBinding: Binding<PacketDocument>? {
        guard let id = primaryDocumentID,
              let index = packet.documents.firstIndex(where: { $0.id == id }) else { return nil }
        return $packet.documents[index]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 16) {
                    Text(relatedAccount?.formattedBalance ?? "Letter")
                        .font(MosaicFont.medium(40))
                        .foregroundColor(Color.mosaicInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .frame(minWidth: 118, alignment: .leading)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(packet.itemName)
                            .font(MosaicFont.medium(18))
                            .foregroundColor(Color.mosaicInk)
                        Text(plainReason)
                            .font(MosaicFont.regular(13))
                            .foregroundColor(Color.mosaicSubtle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(20)
                .liquidGlass(tint: Color.mosaicMint, cornerRadius: 28, shadowRadius: 12)

                Text("Mosaic wrote a letter you can edit. It will not be mailed unless you mail it.")
                    .font(MosaicFont.regular(16))
                    .foregroundColor(Color.mosaicInk)
                    .lineSpacing(3)

                if let primary = primaryBinding {
                    NavigationLink {
                        DraftEditorView(document: primary)
                    } label: {
                        Text("Open the letter")
                            .font(MosaicFont.medium(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.liquidGlass(tint: Color.mosaicViolet, isProminent: true))
                }

                Button {
                    sourcePDFURL = SyntheticDataService.shared.generateSyntheticPDFFile(isCurrentReport: true)
                    showSourcePDF = true
                } label: {
                    Text("See it on my report")
                        .font(MosaicFont.medium(15))
                        .foregroundColor(Color.mosaicInk)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.liquidGlass(tint: Color.mosaicMint))

                Button("More options") {
                    showMore = true
                }
                .font(MosaicFont.regular(14))
                .foregroundColor(Color.mosaicSubtle)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Color.mosaicPage.ignoresSafeArea())
        .hidesFloatingTabBar()
        .navigationTitle("This letter")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMore) {
            moreSheet
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedPDFURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showSourcePDF) {
            if let url = sourcePDFURL {
                PDFViewerModal(url: url, title: "Your report")
            }
        }
        .onAppear {
            BackboardService.shared.recordLastViewedPacket(id: packet.id)
        }
    }

    private var plainReason: String {
        switch packet.classificationAtCreation {
        case .unrecognized:
            return "You said you did not open this."
        case .recognized:
            return "You said you know this account."
        case .pressuredOrNotFreelyAgreed:
            return "You said you did not freely agree to this."
        case .notSure:
            return "You were not sure about this yet."
        case .ignored:
            return "You chose to leave this for now."
        }
    }

    private var moreSheet: some View {
        NavigationStack {
            List {
                Section("Other letters") {
                    ForEach(packet.documents.indices, id: \.self) { index in
                        if packet.documents[index].id != primaryDocumentID {
                            NavigationLink(packet.documents[index].documentType.shortTitle) {
                                DraftEditorView(document: $packet.documents[index])
                            }
                        }
                    }
                }

                Section("If you need help") {
                    NavigationLink("Checklist of papers to keep") {
                        InteractiveChecklistView()
                    }
                    NavigationLink("Dates to remember") {
                        DeadlineTrackerView()
                    }
                    Button("Save a PDF copy") {
                        if let pdfUrl = PDFPacketExporter.shared.exportPacketPDF(packet: packet) {
                            exportedPDFURL = pdfUrl
                            showMore = false
                            showShareSheet = true
                        }
                    }
                    if let ftc = URL(string: "https://www.identitytheft.gov/") {
                        Link("Official FTC site", destination: ftc)
                    }
                    if let cfpb = URL(string: "https://www.consumerfinance.gov/ask-cfpb/how-do-i-dispute-an-error-on-my-credit-report-en-314/") {
                        Link("How to dispute a credit item", destination: cfpb)
                    }
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showMore = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
