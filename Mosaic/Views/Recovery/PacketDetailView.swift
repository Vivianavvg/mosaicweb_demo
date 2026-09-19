import SwiftUI

struct PacketDetailView: View {
    @Binding var packet: RecoveryPacket
    @EnvironmentObject private var appState: AppState

    @State private var exportedPDFURL: URL? = nil
    @State private var showShareSheet: Bool = false
    @State private var showSourcePDF: Bool = false
    @State private var sourcePDFURL: URL? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Section 1: Selected Item & Classification Banner
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(packet.itemName)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            if let last4 = packet.itemLast4 {
                                Text("Account Identifier: **** \(last4)")
                                    .font(.caption)
                                    .foregroundColor(Color.mosaicMuted)
                            }
                        }
                        Spacer()
                        Text(packet.status.displayName)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.mosaicTeal.opacity(0.15))
                            .foregroundColor(Color.mosaicTeal)
                            .cornerRadius(6)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(.caption)
                            .foregroundColor(Color.mosaicAmber)
                        Text("Classification: \(packet.classificationAtCreation.title)")
                            .font(.caption.bold())
                            .foregroundColor(Color.mosaicAmber)
                        Spacer()
                        Text("Source: Page \(packet.sourcePage)")
                            .font(.caption2.bold())
                            .foregroundColor(Color.mosaicAccent)
                    }
                }
                .padding(16)
                .background(Color.mosaicCardBg)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mosaicCardBorder, lineWidth: 1))

                // Section 2: Source Page Visual Reference & Inspection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(Color.mosaicAccent)
                        Text("Referenced on credit report page \(packet.sourcePage). Include this page copy with your disputes.")
                            .font(.caption)
                            .foregroundColor(Color.mosaicMuted)
                    }

                    Button(action: {
                        sourcePDFURL = SyntheticDataService.shared.generateSyntheticPDFFile(isCurrentReport: true)
                        showSourcePDF = true
                    }) {
                        HStack {
                            Image(systemName: "eye.fill")
                            Text("Inspect Source Report Page \(packet.sourcePage)")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption.bold())
                        .foregroundColor(Color.mosaicAccent)
                        .padding(10)
                        .background(Color.mosaicAccent.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.02))
                .cornerRadius(10)

                // Section 3: Interactive Evidence & Freeze Checklists
                NavigationLink(destination: InteractiveChecklistView()) {
                    HStack {
                        Image(systemName: "checklist.checked")
                            .font(.title3)
                            .foregroundColor(Color.mosaicTeal)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Interactive Evidence & Freeze Checklist")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Check off documents, track postal receipts & record bureau PINs")
                                .font(.caption)
                                .foregroundColor(Color.mosaicMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.mosaicMuted)
                    }
                    .padding(14)
                    .background(Color.mosaicCardBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
                }

                // Section 4-7: Packet Documents / Drafts
                Text("Draft Materials & Worksheets")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 4)

                ForEach($packet.documents) { $doc in
                    NavigationLink(destination: DraftEditorView(document: $doc)) {
                        DocumentRow(document: doc)
                    }
                    .buttonStyle(.plain)
                }

                // Section 8: Export Complete Packet (PDF)
                Button(action: {
                    if let pdfUrl = PDFPacketExporter.shared.exportPacketPDF(packet: packet) {
                        exportedPDFURL = pdfUrl
                        showShareSheet = true
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Export Multi-Page Recovery Packet (PDF)")
                    }
                    .font(.headline)
                    .foregroundColor(Color.mosaicNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.mosaicAccent)
                    .cornerRadius(12)
                }
                .padding(.top, 6)

                // Section 9: Quick Deadline Tracker Link
                NavigationLink(destination: DeadlineTrackerView()) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title3)
                            .foregroundColor(Color.mosaicAmber)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dispute Deadlines & Follow-ups")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Track 30-day FCRA response windows & certified mail")
                                .font(.caption)
                                .foregroundColor(Color.mosaicMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.mosaicMuted)
                    }
                    .padding(14)
                    .background(Color.mosaicCardBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
                }

                // Official Resources & Links
                VStack(alignment: .leading, spacing: 8) {
                    Text("Official Government Resources")
                        .font(.headline)
                        .foregroundColor(.white)

                    LinkCard(
                        title: "FTC IdentityTheft.gov",
                        subtitle: "File an official Identity Theft Report and affidavit",
                        urlString: "https://www.identitytheft.gov/"
                    )
                    LinkCard(
                        title: "CFPB Credit Dispute Guide",
                        subtitle: "Consumer rights and model dispute instructions",
                        urlString: "https://www.consumerfinance.gov/ask-cfpb/how-do-i-dispute-an-error-on-my-credit-report-en-314/"
                    )
                    LinkCard(
                        title: "FTC Credit Freeze Guide",
                        subtitle: "Instructions for placing free credit freezes",
                        urlString: "https://consumer.ftc.gov/articles/credit-freezes-and-fraud-alerts"
                    )
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Color.mosaicNavy.ignoresSafeArea())
        .navigationTitle("Recovery Packet")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedPDFURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showSourcePDF) {
            if let url = sourcePDFURL {
                PDFViewerModal(url: url, title: "Source Report (Page \(packet.sourcePage))")
            }
        }
        .onAppear {
            BackboardService.shared.recordLastViewedPacket(id: packet.id)
        }
    }
}

private struct DocumentRow: View {
    let document: PacketDocument

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    Text(document.generatedBy)
                        .font(.caption2)
                        .foregroundColor(Color.mosaicTeal)
                    if document.reviewedByUserAt != nil {
                        Text("• Reviewed")
                            .font(.caption2.bold())
                            .foregroundColor(Color.mosaicAccent)
                    } else {
                        Text("• Draft Needs Review")
                            .font(.caption2)
                            .foregroundColor(Color.mosaicAmber)
                    }
                }
            }
            Spacer()
            Image(systemName: "pencil.and.list.clipboard")
                .foregroundColor(Color.mosaicAccent)
        }
        .padding(14)
        .background(Color.mosaicCardBg)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
    }
}

private struct LinkCard: View {
    let title: String
    let subtitle: String
    let urlString: String

    var body: some View {
        if let url = URL(string: urlString) {
            Link(destination: url) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundColor(Color.mosaicAccent)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(Color.mosaicMuted)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption.bold())
                        .foregroundColor(Color.mosaicAccent)
                }
                .padding(12)
                .background(Color.mosaicCardBg)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mosaicCardBorder, lineWidth: 1))
            }
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
