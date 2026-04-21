import Foundation
@preconcurrency import Speech
import AVFoundation

actor TranscribeService {
    static let shared = TranscribeService()

    func transcribe(request: TranscribeRequest) async throws -> TranscribeResponse {
        let startTime = Date()

        guard let audioData = Data(base64Encoded: request.audio) else {
            throw MLError.invalidInput("Invalid base64 audio data")
        }

        let authStatus = SFSpeechRecognizer.authorizationStatus()
        if authStatus == .notDetermined {
            let granted = await requestAuthorization()
            if !granted {
                throw MLError.notAuthorized
            }
        } else if authStatus != .authorized {
            throw MLError.notAuthorized
        }

        let format = request.format?.lowercased() ?? "m4a"

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "." + format)
        try audioData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Detect language if not specified
        let lang: String
        if let requestLang = request.language, !requestLang.isEmpty {
            lang = requestLang
        } else {
            lang = await LanguageDetector.detect(audioURL: tempURL)
        }

        let timeoutSeconds = TimeInterval(request.timeout ?? 300)
        let result = try await SpeechWorker.shared.transcribe(
            audioURL: tempURL,
            language: lang,
            includeTimestamps: request.timestamps ?? false,
            timeout: timeoutSeconds
        )

        let processingTime = Int64(Date().timeIntervalSince(startTime) * 1000)

        return TranscribeResponse(
            transcript: result.transcript,
            confidence: result.confidence,
            language: lang,
            words: result.words,
            processingTimeMs: processingTime,
            error: nil
        )
    }

    /// Transcribe from a local file URL (used by GUI path).
    func transcribeFile(url: URL, language: String?, timestamps: Bool) async throws -> TranscribeResponse {
        let startTime = Date()

        let authStatus = SFSpeechRecognizer.authorizationStatus()
        if authStatus == .notDetermined {
            let granted = await requestAuthorization()
            if !granted { throw MLError.notAuthorized }
        } else if authStatus != .authorized {
            throw MLError.notAuthorized
        }

        let lang: String
        if let requestLang = language, !requestLang.isEmpty {
            lang = requestLang
        } else {
            lang = await LanguageDetector.detect(audioURL: url)
        }

        let result = try await SpeechWorker.shared.transcribe(
            audioURL: url,
            language: lang,
            includeTimestamps: timestamps,
            timeout: 300
        )

        let processingTime = Int64(Date().timeIntervalSince(startTime) * 1000)

        return TranscribeResponse(
            transcript: result.transcript,
            confidence: result.confidence,
            language: lang,
            words: result.words,
            processingTimeMs: processingTime,
            error: nil
        )
    }

    private func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
