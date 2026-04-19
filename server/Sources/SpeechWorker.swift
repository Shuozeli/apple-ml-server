import Foundation
@preconcurrency import Speech

/// Speech recognition service that spawns a dedicated thread per request
/// Each thread has its own RunLoop to properly handle Speech framework callbacks
final class SpeechWorker: @unchecked Sendable {
    static let shared = SpeechWorker()

    private init() {}

    func transcribe(
        audioURL: URL,
        language: String?,
        includeTimestamps: Bool,
        timeout: TimeInterval = 300
    ) async throws -> (transcript: String, confidence: Float, words: [TranscribeResponse.WordTiming]?) {

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(String, Float, [TranscribeResponse.WordTiming]?), Error>) in
            // Spawn a dedicated thread for this recognition task
            let thread = Thread {
                Self.runRecognition(
                    audioURL: audioURL,
                    language: language,
                    includeTimestamps: includeTimestamps,
                    timeout: timeout,
                    continuation: continuation
                )
            }
            thread.name = "SpeechRecognition-\(UUID().uuidString.prefix(8))"
            thread.qualityOfService = .userInitiated
            thread.start()
        }
    }

    private static func runRecognition(
        audioURL: URL,
        language: String?,
        includeTimestamps: Bool,
        timeout: TimeInterval,
        continuation: CheckedContinuation<(String, Float, [TranscribeResponse.WordTiming]?), Error>
    ) {
        // Create recognizer
        let recognizer: SFSpeechRecognizer?
        if let lang = language, !lang.isEmpty {
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: lang))
        } else {
            recognizer = SFSpeechRecognizer()
        }

        guard let sr = recognizer, sr.isAvailable else {
            continuation.resume(throwing: MLError.languageNotSupported)
            return
        }

        // Create request
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false

        var isDone = false
        var partialTranscript = ""
        let deadline = Date().addingTimeInterval(timeout)

        // Start recognition
        let task = sr.recognitionTask(with: request) { result, error in
            guard !isDone else { return }

            if let error = error {
                let nsError = error as NSError
                // Ignore cancellation errors (216, 1)
                if nsError.code != 216 && nsError.code != 1 {
                    isDone = true
                    continuation.resume(throwing: MLError.recognitionFailed(error.localizedDescription))
                }
                return
            }

            guard let result = result else { return }
            partialTranscript = result.bestTranscription.formattedString

            if result.isFinal {
                isDone = true
                let segments = result.bestTranscription.segments
                let confidences = segments.map { $0.confidence }
                let avgConfidence = confidences.isEmpty ? 0 : confidences.reduce(0, +) / Float(confidences.count)

                var words: [TranscribeResponse.WordTiming]? = nil
                if includeTimestamps {
                    words = segments.map { segment in
                        TranscribeResponse.WordTiming(
                            word: segment.substring,
                            confidence: segment.confidence,
                            startMs: Int64(segment.timestamp * 1000),
                            endMs: Int64((segment.timestamp + segment.duration) * 1000)
                        )
                    }
                }

                continuation.resume(returning: (result.bestTranscription.formattedString, avgConfidence, words))
            }
        }

        // Run the run loop until done or timeout
        while !isDone && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.1))
        }

        // Handle timeout
        if !isDone {
            isDone = true
            task.cancel()
            if !partialTranscript.isEmpty {
                continuation.resume(returning: (partialTranscript, 0.5, nil))
            } else {
                continuation.resume(throwing: MLError.recognitionFailed("Timeout after \(Int(timeout))s"))
            }
        }
    }
}
