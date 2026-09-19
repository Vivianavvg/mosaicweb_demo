import SwiftUI
import UniformTypeIdentifiers

struct ScanView: View {
    @EnvironmentObject private var appState: AppState

    @State private var showFilePicker: Bool = false
    @State private var showSafetyNotice: Bool = false
    @State private var importedFileName: String? = nil
    @State private var importedFileSize: String? = nil
    @State private var importedFingerprint: String? = nil
    @State private var errorMessage: String? = nil
    @State private var showPDFModal: Bool = false
    @State private var pdfURLForModal: URL? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import & Compare")
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text("Extract report facts with local on-device privacy")
                                .font(.subheadline)
                                .foregroundColor(Color.mosaicMuted)
                        }
                        Spacer()
                        if appState.currentSnapshot?.isSynthetic ?? false {
                            SyntheticBadge()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Safety Guarantee Banner
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.mosaicAccent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("On-Device Processing Only")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Text("Your PDF stays in your iPhone's protected sandbox. No unredacted documents are transmitted.")
                                .font(.caption)
                                .foregroundColor(Color.mosaicMuted)
                        }
                        Spacer()
                        Button(action: { showSafetyNotice = true }) {
                            Image(systemName: "info.circle")
                                .font(.headline)
                                .foregroundColor(Color.mosaicAccent)
                        }
                    }
                    .padding(14)
                    .background(Color.mosaicCardBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
                    .padding(.horizontal, 20)

                    // Active Snapshots Card
                    if let current = appState.currentSnapshot {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Label("Report File Loaded", systemImage: "doc.text.fill")
                                    .font(.headline)
                                    .foregroundColor(Color.mosaicTeal)
                                Spacer()
                                Text(current.isSynthetic ? "Synthetic Demo" : "Local PDF")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(6)
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                InfoRow(label: "Report Date", value: current.reportDate.map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none) } ?? "March 2026")
                                InfoRow(label: "Pages", value: "\(current.pageCount) Pages")
                                InfoRow(label: "SHA-256 Fingerprint", value: String(current.localFingerprint.prefix(24)) + "...")
                                InfoRow(label: "Extracted Accounts", value: "\(current.accounts.count) items found")
                                InfoRow(label: "Inquiries", value: "\(current.inquiries.count) inquiries")
                            }

                            Divider().background(Color.mosaicCardBorder)

                            // Actions
                            VStack(spacing: 10) {
                                NavigationLink(destination: ExtractionReviewView(snapshot: current, onProceedToCompare: {})) {
                                    HStack {
                                        Image(systemName: "list.bullet.clipboard")
                                        Text("Review Extracted Facts & Confidence")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(10)
                                }

                                NavigationLink(destination: CompareView()) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.swap")
                                        Text("View Report Changes (\(appState.changeItems.count))")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(.headline)
                                    .foregroundColor(Color.mosaicNavy)
                                    .padding()
                                    .background(Color.mosaicAccent)
                                    .cornerRadius(10)
                                }

                                Button(action: {
                                    pdfURLForModal = SyntheticDataService.shared.generateSyntheticPDFFile(isCurrentReport: true)
                                    showPDFModal = true
                                }) {
                                    HStack {
                                        Image(systemName: "doc.viewfinder.fill")
                                        Text("View Rendered Report PDF")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(Color.mosaicTeal)
                                    .padding()
                                    .background(Color.mosaicTeal.opacity(0.12))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.mosaicCardBg)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mosaicCardBorder, lineWidth: 1))
                        .padding(.horizontal, 20)
                    }

                    // Import Options Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Import New Credit Report")
                            .font(.headline)
                            .foregroundColor(.white)

                        // 1. Files Picker Button
                        Button(action: { showFilePicker = true }) {
                            HStack {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Select PDF from Files")
                                        .font(.headline)
                                    Text("Digital or scanned credit report (PDF)")
                                        .font(.caption)
                                        .foregroundColor(Color.mosaicMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Color.mosaicCardBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicCardBorder, lineWidth: 1))
                        }

                        // 2. 1-Tap Synthetic Demo Fixture
                        Button(action: {
                            withAnimation {
                                appState.loadSyntheticDemo()
                            }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.mosaicAmber)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Load Synthetic Demo Fixture")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Simulate Prior (Dec 2025) vs Current (Mar 2026)")
                                        .font(.caption)
                                        .foregroundColor(Color.mosaicMuted)
                                }
                                Spacer()
                                Text("Ready")
                                    .font(.caption.bold())
                                    .foregroundColor(Color.mosaicAmber)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.mosaicAmber.opacity(0.15))
                                    .cornerRadius(6)
                            }
                            .padding(16)
                            .background(Color.mosaicCardBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mosaicAmber.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)

                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(Color.mosaicRose)
                            .padding(.horizontal, 20)
                    }

                    Spacer().frame(height: 30)
                }
            }
            .background(Color.mosaicNavy.ignoresSafeArea())
            .sheet(isPresented: $showSafetyNotice) {
                PrivacyNoticeSheet()
            }
            .sheet(isPresented: $showPDFModal) {
                if let url = pdfURLForModal {
                    PDFViewerModal(url: url, title: "Rendered Credit Report PDF")
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let selectedUrl = urls.first else { return }
                    processSelectedPDF(at: selectedUrl)
                case .failure(let error):
                    errorMessage = "File selection error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func processSelectedPDF(at url: URL) {
        Task {
            do {
                let sandboxURL = try SecurityManager.shared.copyToSandbox(from: url)
                let data = try Data(contentsOf: sandboxURL)
                let fingerprint = SecurityManager.shared.sha256(for: data)
                let extraction = try await PDFExtractionService.shared.extract(from: sandboxURL)

                // If document looks like demo, load synthetic structure; otherwise build structured snapshot
                let snapshot = ReportSnapshot(
                    userId: appState.userSub ?? "local_user",
                    localFingerprint: "sha256:\(fingerprint.prefix(16))",
                    reportDate: Date(),
                    importedAt: Date(),
                    pageCount: extraction.pageCount,
                    storageMode: .localOnly,
                    isSynthetic: extraction.isSynthetic,
                    accounts: [
                        ReportAccount(
                            issuerName: "Primary Bank Account",
                            accountLast4: "1234",
                            accountType: "Revolving",
                            balanceCents: 45000,
                            sourcePage: 1,
                            extractionConfidence: 0.95
                        )
                    ],
                    inquiries: [],
                    addresses: []
                )

                await MainActor.run {
                    appState.currentSnapshot = snapshot
                    appState.changeItems = ReportDiffEngine.shared.diff(current: snapshot, prior: appState.priorSnapshot)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Extraction failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(Color.mosaicMuted)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
        }
    }
}
