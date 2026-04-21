import Foundation
import Vision
import AppKit

actor OCRService {
    static let shared = OCRService()

    func recognize(request: OCRRequest) async throws -> OCRResponse {
        let startTime = Date()

        guard let imageData = Data(base64Encoded: request.image) else {
            throw MLError.invalidInput("Invalid base64 image data")
        }

        guard let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw MLError.invalidInput("Could not decode image")
        }

        let result = try await performOCR(cgImage: cgImage, language: request.language)
        let processingTime = Int64(Date().timeIntervalSince(startTime) * 1000)

        let fullText = result.map { $0.text }.joined(separator: "\n")
        let avgConfidence = result.isEmpty ? 0 : result.map { $0.confidence }.reduce(0, +) / Float(result.count)

        return OCRResponse(
            text: fullText,
            blocks: result,
            confidence: avgConfidence,
            processingTimeMs: processingTime,
            error: nil
        )
    }

    /// OCR from a local file URL (used by GUI path).
    func recognizeFile(url: URL, language: String?) async throws -> OCRResponse {
        let startTime = Date()

        let imageData = try Data(contentsOf: url)
        guard let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw MLError.invalidInput("Could not decode image")
        }

        let result = try await performOCR(cgImage: cgImage, language: language)
        let processingTime = Int64(Date().timeIntervalSince(startTime) * 1000)

        let fullText = result.map { $0.text }.joined(separator: "\n")
        let avgConfidence = result.isEmpty ? 0 : result.map { $0.confidence }.reduce(0, +) / Float(result.count)

        return OCRResponse(
            text: fullText,
            blocks: result,
            confidence: avgConfidence,
            processingTimeMs: processingTime,
            error: nil
        )
    }

    private func performOCR(cgImage: CGImage, language: String?) async throws -> [OCRResponse.TextBlock] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: MLError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let blocks = observations.compactMap { observation -> OCRResponse.TextBlock? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    let bbox = observation.boundingBox
                    return OCRResponse.TextBlock(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: OCRResponse.BoundingBox(
                            xMin: Float(bbox.origin.x),
                            yMin: Float(1.0 - bbox.origin.y - bbox.height),
                            xMax: Float(bbox.origin.x + bbox.width),
                            yMax: Float(1.0 - bbox.origin.y)
                        )
                    )
                }
                continuation.resume(returning: blocks)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            if let lang = language, !lang.isEmpty {
                request.recognitionLanguages = [lang]
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: MLError.recognitionFailed(error.localizedDescription))
                }
            }
        }
    }
}
