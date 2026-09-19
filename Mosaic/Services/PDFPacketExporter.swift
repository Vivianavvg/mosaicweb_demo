import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class PDFPacketExporter {
    public static let shared = PDFPacketExporter()

    private init() {}

    /// Generates a comprehensive multi-page PDF Recovery Packet for printing or mailing
    public func exportPacketPDF(packet: RecoveryPacket) -> URL? {
        let fileName = "Mosaic_Recovery_Packet_\(packet.itemName.replacingOccurrences(of: " ", with: "_"))_\(packet.itemLast4 ?? "dispute").pdf"
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("mosaic_packets", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent(fileName)

        let pageWidth: CGFloat = 612.0
        let pageHeight: CGFloat = 792.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        do {
            try renderer.writePDF(to: fileURL) { context in
                // 1. COVER PAGE
                context.beginPage()
                drawCoverHeader(context: context, packet: packet, pageRect: pageRect)

                let coverSummary = """
                RECOVERY PACKET OVERVIEW & CASE FILE
                Item in Review: \(packet.itemName)
                Account Identifier: **** \(packet.itemLast4 ?? "Unknown")
                Consumer Status Selection: \(packet.classificationAtCreation.title)
                Source Reference: Credit Report Page \(packet.sourcePage)
                Generated On: \(DateFormatter.localizedString(from: packet.createdAt, dateStyle: .long, timeStyle: .short))

                INCLUDED MATERIALS IN THIS PACKET:
                1. FTC IdentityTheft.gov Incident Preparation Worksheet
                2. Formal Notice of Dispute to Credit Reporting Agencies (FCRA § 611)
                3. Direct Dispute Notice to Furnisher / Creditor (12 CFR § 1022.43)
                4. Evidence & Postal Records Retention Checklist
                5. Three-Bureau Security Freeze Log

                NOTICE & DISCLAIMER:
                This dispute packet was generated with assistance from Mosaic for the consumer's personal review and records. Mosaic is not a credit repair organization or law firm. The consumer must independently verify all facts, attach required identification copies, and mail directly to the respective entities using USPS Certified Mail with Return Receipt Requested.
                """
                drawText(coverSummary, in: CGRect(x: 50, y: 140, width: 512, height: 580), fontSize: 11)

                // 2. FOR EACH DRAFT DOCUMENT
                for doc in packet.documents {
                    context.beginPage()
                    drawDocumentHeader(context: context, title: doc.title, pageRect: pageRect)
                    drawText(doc.draftText, in: CGRect(x: 50, y: 90, width: 512, height: 650), fontSize: 10)
                }
            }
            return fileURL
        } catch {
            print("Failed to render packet PDF: \(error.localizedDescription)")
            return nil
        }
    }

    private func drawCoverHeader(context: UIGraphicsPDFRendererContext, packet: RecoveryPacket, pageRect: CGRect) {
        let bannerRect = CGRect(x: 40, y: 40, width: 532, height: 75)
        UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1.0).setFill()
        UIRectFill(bannerRect)

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.white
        ]
        NSString(string: "MOSAIC — CREDIT DISPUTE & RECOVERY PACKET").draw(in: CGRect(x: 55, y: 52, width: 500, height: 26), withAttributes: titleAttrs)

        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1.0)
        ]
        NSString(string: "PERSONAL RECORD & DISPUTE SUBMISSION DRAFTS • CONFIDENTIAL").draw(in: CGRect(x: 55, y: 82, width: 500, height: 20), withAttributes: subAttrs)
    }

    private func drawDocumentHeader(context: UIGraphicsPDFRendererContext, title: String, pageRect: CGRect) {
        let bannerRect = CGRect(x: 40, y: 35, width: 532, height: 40)
        UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1.0).setFill()
        UIRectFill(bannerRect)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.white
        ]
        NSString(string: title.uppercased()).draw(in: CGRect(x: 50, y: 46, width: 512, height: 20), withAttributes: attrs)
    }

    private func drawText(_ text: String, in rect: CGRect, fontSize: CGFloat) {
        let para = NSMutableParagraphStyle()
        para.lineSpacing = 3

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: para
        ]
        NSString(string: text).draw(in: rect, withAttributes: attrs)
    }
}
