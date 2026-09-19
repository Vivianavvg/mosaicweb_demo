import Foundation
import PDFKit
import Vision
#if canImport(UIKit)
import UIKit
#endif

public struct PageExtractionResult {
    public let pageNumber: Int
    public let rawText: String
    public let redactedText: String
    public let isOCR: Bool
    public let confidence: Double
}

public final class PDFExtractionService {
    public static let shared = PDFExtractionService()

    private init() {}

    /// Extracts text from PDF document at URL, falling back to Vision OCR if digital text is empty
    public func extract(from url: URL) async throws -> (pages: [PageExtractionResult], isSynthetic: Bool, pageCount: Int) {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw NSError(domain: "PDFExtractionService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Unable to read PDF file format."])
        }

        let pageCount = pdfDocument.pageCount
        var results: [PageExtractionResult] = []
        var detectedSynthetic = false

        for index in 0..<pageCount {
            guard let page = pdfDocument.page(at: index) else { continue }
            let pageNumber = index + 1
            var pageText = page.string ?? ""
            var usedOCR = false
            var confidence = 0.98

            // Fallback to Vision OCR if digital text is negligible
            if pageText.trimmingCharacters(in: .whitespacesAndNewlines).count < 50 {
                if let ocrText = await performOCR(on: page) {
                    pageText = ocrText
                    usedOCR = true
                    confidence = 0.88
                }
            }

            // Check if document contains synthetic demo tags
            let upper = pageText.uppercased()
            if upper.contains("SYNTHETIC") || upper.contains("DEMO") || upper.contains("NORTHSTAR LENDING") || upper.contains("HARBOR RECOVERY") {
                detectedSynthetic = true
            }

            let redacted = RedactionEngine.shared.redactText(pageText)
            results.append(PageExtractionResult(
                pageNumber: pageNumber,
                rawText: pageText,
                redactedText: redacted,
                isOCR: usedOCR,
                confidence: confidence
            ))
        }

        return (results, detectedSynthetic, pageCount)
    }

    /// Vision OCR fallback for scanned PDF pages
    private func performOCR(on page: PDFPage) async -> String? {
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }

        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil, let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}
