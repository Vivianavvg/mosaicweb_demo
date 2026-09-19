import SwiftUI
import UniformTypeIdentifiers

struct ScanView: View {
    @EnvironmentObject private var appState: AppState

    @State private var showFilePicker: Bool = false
    @State private var showSafetyNotice: Bool = false
    @State private var showPDFModal: Bool = false
    @State private var pdfURLForModal: URL? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Bar
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Credit Reports")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                Text("Spot new accounts, balance spikes, and collections.")
                                    .font(.footnote)
                                    .foregroundColor(Color.mosaicMuted)
                            }
                            Spacer()
                            QuickExitButton()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // Privacy & Confidentiality Guarantee
                        LiquidGlassCard(tint: Color.mosaicTeal, cornerRadius: 16, borderOpacity: 0.25, contentPadding: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.mosaicTeal)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("100% Private On-Device Analysis")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text("Your reports stay inside your iPhone. Social Security numbers and personal addresses are masked automatically.")
                                        .font(.caption)
                                        .foregroundColor(Color.mosaicMuted)
                                        .lineSpacing(2)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // If Report Is Loaded
                        if let current = appState.currentSnapshot {
                            LiquidGlassCard(tint: Color.mosaicAccent, cornerRadius: 22, borderOpacity: 0.35, contentPadding: 20) {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("ACTIVE COMPARISON")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(Color.mosaicAccent)
                                                .tracking(1)
                                            Text("March 2026 vs December 2025")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                        Text("\(appState.changeItems.count) Changes")
                                            .font(.caption.bold())
                                            .foregroundColor(Color.mosaicNavy)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.mosaicAccent)
                                            .clipShape(Capsule())
                                    }

                                    VStack(spacing: 10) {
                                        ReportSummaryRow(title: "Current Snapshot", subtitle: "March 2026 Report (14 accounts)", icon: "doc.text.fill", color: Color.mosaicAccent)
                                        ReportSummaryRow(title: "Prior Baseline", subtitle: "December 2025 Report (12 accounts)", icon: "clock.arrow.circlepath", color: Color.mosaicIndigo)
                                        ReportSummaryRow(title: "Key Finding", subtitle: "1 new collection, 1 large balance surge", icon: "exclamationmark.triangle.fill", color: Color.mosaicRose)
                                    }

                                    Divider().background(Color.white.opacity(0.12))

                                    // Action: Inspect Changes
                                    NavigationLink(destination: CompareView()) {
                                        HStack {
                                            Image(systemName: "sparkles")
                                            Text("Review What Changed (\(appState.changeItems.count) items)")
                                                .fontWeight(.bold)
                                            Spacer()
                                            Image(systemName: "arrow.right")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(Color.mosaicNavy)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 16)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.mosaicAccent, Color.mosaicRoseGold],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                    }

                                    // View PDF Modal
                                    Button(action: {
                                        pdfURLForModal = SyntheticDataService.shared.generateSyntheticPDFFile(isCurrentReport: true)
                                        showPDFModal = true
                                    }) {
                                        HStack {
                                            Image(systemName: "eye.fill")
                                            Text("View Clean Report PDF")
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.footnote.weight(.semibold))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 10)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // Empty State / Demo Button
                            LiquidGlassCard(tint: Color.mosaicAccent, cornerRadius: 22, borderOpacity: 0.35, contentPadding: 22) {
                                VStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.mosaicAccent.opacity(0.15))
                                            .frame(width: 64, height: 64)
                                        Image(systemName: "doc.viewfinder.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(Color.mosaicAccent)
                                    }

                                    Text("Start Your Credit Review")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Text("Upload your official credit report PDF or load our pre-configured sample report to see how Mosaic protects your rights.")
                                        .font(.footnote)
                                        .foregroundColor(Color.mosaicMuted)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(3)

                                    Button(action: {
                                        appState.loadSyntheticDemo()
                                    }) {
                                        HStack {
                                            Image(systemName: "sparkles")
                                            Text("Load Sample Report (Dec vs Mar)")
                                                .fontWeight(.bold)
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(Color.mosaicNavy)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.mosaicAccent)
                                        .cornerRadius(12)
                                    }

                                    Button(action: {
                                        showFilePicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.up.doc")
                                            Text("Choose PDF from Files")
                                        }
                                        .font(.footnote.weight(.medium))
                                        .foregroundColor(Color.mosaicMuted)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Helpful Credit Advice Card
                        LiquidGlassCard(tint: Color.mosaicAmber, cornerRadius: 16, borderOpacity: 0.20, contentPadding: 16) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.mosaicAmber)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("How to get your free official reports")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text("You are legally entitled to a free weekly credit report from Equifax, Experian, and TransUnion at AnnualCreditReport.com. Never pay for your own report.")
                                        .font(.caption)
                                        .foregroundColor(Color.mosaicMuted)
                                        .lineSpacing(2)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 96)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showPDFModal) {
                if let url = pdfURLForModal {
                    PDFViewerModal(url: url, title: "Report Document")
                }
            }
        }
    }
}

private struct ReportSummaryRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Color.mosaicMuted)
            }
            Spacer()
        }
    }
}
