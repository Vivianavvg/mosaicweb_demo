import SwiftUI

struct InteractiveChecklistView: View {
    @State private var idCopied = false
    @State private var addressProof = false
    @State private var reportPageAttached = true
    @State private var certifiedMailTracked = false
    @State private var correspondenceLogged = false
    @State private var collectionNoticeAttached = false

    @State private var equifaxPIN = ""
    @State private var experianPIN = ""
    @State private var transunionPIN = ""
    @State private var fraudAlertPlaced = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section 1: Evidence & Records Checklist
                VStack(alignment: .leading, spacing: 14) {
                    Label("Dispute Evidence Gathering", systemImage: "folder.fill.badge.plus")
                        .font(.headline)
                        .foregroundColor(Color.mosaicInk)

                    Text("Keep copies of all records you send. Credit bureaus require positive identification before investigating.")
                        .font(.caption)
                        .foregroundColor(Color.mosaicMuted)

                    VStack(spacing: 8) {
                        ChecklistRow(isOn: $idCopied, text: "Government-Issued Photo ID (Driver's License / Passport)")
                        ChecklistRow(isOn: $addressProof, text: "Proof of Address (Utility bill, bank statement, or lease)")
                        ChecklistRow(isOn: $reportPageAttached, text: "Credit report page highlighting the disputed trade line")
                        ChecklistRow(isOn: $certifiedMailTracked, text: "USPS Certified Mail tracking # & signed return receipt card")
                        ChecklistRow(isOn: $correspondenceLogged, text: "Date & summary log of any phone calls with creditor")
                        ChecklistRow(isOn: $collectionNoticeAttached, text: "Original billing notice or collection letter (if received)")
                    }
                }
                .padding(16)
                .background(Color.mosaicCardBg)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mosaicCardBorder, lineWidth: 1))

                // Section 2: Nationwide Credit Freeze Checklist
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Three-Bureau Security Freezes", systemImage: "lock.shield.fill")
                            .font(.headline)
                            .foregroundColor(Color.mosaicInk)
                        Spacer()
                        Text("100% Free by Law")
                            .font(.caption2.bold())
                            .foregroundColor(Color.mosaicTeal)
                    }

                    Text("A credit freeze stops anyone from opening new credit in your name without your PIN/password.")
                        .font(.caption)
                        .foregroundColor(Color.mosaicMuted)

                    VStack(spacing: 12) {
                        FreezeInputCard(
                            bureauName: "Equifax",
                            urlText: "equifax.com/personal/credit-freeze",
                            phone: "1-800-349-9960",
                            urlString: "https://www.equifax.com/personal/credit-report-services/credit-freeze/",
                            pinText: $equifaxPIN
                        )

                        FreezeInputCard(
                            bureauName: "Experian",
                            urlText: "experian.com/freeze",
                            phone: "1-888-397-3742",
                            urlString: "https://www.experian.com/freeze/center.html",
                            pinText: $experianPIN
                        )

                        FreezeInputCard(
                            bureauName: "TransUnion",
                            urlText: "transunion.com/credit-freeze",
                            phone: "1-888-909-8872",
                            urlString: "https://www.transunion.com/credit-freeze",
                            pinText: $transunionPIN
                        )
                    }

                    Divider().background(Color.mosaicCardBorder)

                    Toggle(isOn: $fraudAlertPlaced) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Placed 1-Year Fraud Alert")
                                .font(.subheadline.bold())
                                .foregroundColor(Color.mosaicInk)
                            Text("Notifying one bureau automatically notifies the other two")
                                .font(.caption2)
                                .foregroundColor(Color.mosaicMuted)
                        }
                    }
                    .tint(Color.mosaicAccent)
                }
                .padding(16)
                .background(Color.mosaicCardBg)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mosaicCardBorder, lineWidth: 1))
            }
            .padding(16)
        }
        .background(Color.mosaicPage.ignoresSafeArea())
        .hidesFloatingTabBar()
        .navigationTitle("Evidence & Freeze Checklist")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ChecklistRow: View {
    @Binding var isOn: Bool
    let text: String

    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 10) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isOn ? Color.mosaicTeal : Color.mosaicMuted)

                Text(text)
                    .font(.caption)
                    .foregroundColor(isOn ? Color.mosaicInk : Color.mosaicMuted)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(10)
            .background(Color.mosaicFill)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

private struct FreezeInputCard: View {
    let bureauName: String
    let urlText: String
    let phone: String
    let urlString: String
    @Binding var pinText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(bureauName)
                    .font(.subheadline.bold())
                    .foregroundColor(Color.mosaicInk)
                Spacer()
                if let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack(spacing: 2) {
                            Text("Freeze Online")
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.caption2.bold())
                        .foregroundColor(Color.mosaicAccent)
                    }
                }
            }

            Text("Phone: \(phone)")
                .font(.caption2)
                .foregroundColor(Color.mosaicMuted)

            HStack {
                Text("PIN / Ref #:")
                    .font(.caption.bold())
                    .foregroundColor(Color.mosaicMuted)
                TextField("Optional confirmation #", text: $pinText)
                    .font(.caption)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(Color.mosaicFill)
                    .cornerRadius(6)
                    .foregroundColor(Color.mosaicInk)
            }
        }
        .padding(10)
        .background(Color.mosaicFill)
        .cornerRadius(10)
    }
}
