import Foundation
@preconcurrency import Vision
import AppKit

actor OCRService {
    static func recognize(request: OCRRequest) async throws -> OCRResponse {
        let startTime = Date()

        // Decode base64 image
        guard let imageData = Data(base64Encoded: request.image) else {
            throw MLError.invalidInput("Invalid base64 image data")
        }

        // Create CGImage
        guard let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw MLError.invalidInput("Could not decode image")
        }

        // Perform OCR
        let result = try await performOCR(cgImage: cgImage, language: request.language)

        let processingTime = Int64(Date().timeIntervalSince(startTime) * 1000)

        return OCRResponse(
            text: result.text,
            blocks: result.blocks,
            confidence: result.confidence,
            processingTimeMs: processingTime,
            error: nil
        )
    }

    private static func performOCR(cgImage: CGImage, language: String?) async throws -> (text: String, blocks: [OCRResponse.TextBlock], confidence: Float) {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: MLError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: MLError.recognitionFailed("No results"))
                    return
                }

                var blocks: [OCRResponse.TextBlock] = []
                var confidences: [Float] = []

                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }

                    let bbox = observation.boundingBox
                    let block = OCRResponse.TextBlock(
                        text: topCandidate.string,
                        confidence: topCandidate.confidence,
                        boundingBox: OCRResponse.BoundingBox(
                            xMin: Float(bbox.origin.x),
                            yMin: Float(1.0 - bbox.origin.y - bbox.height),
                            xMax: Float(bbox.origin.x + bbox.width),
                            yMax: Float(1.0 - bbox.origin.y)
                        )
                    )
                    blocks.append(block)
                    confidences.append(topCandidate.confidence)
                }

                let fullText = blocks.map { $0.text }.joined(separator: "\n")
                let avgConfidence = confidences.isEmpty ? 0.0 : confidences.reduce(0, +) / Float(confidences.count)

                continuation.resume(returning: (fullText, blocks, avgConfidence))
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
