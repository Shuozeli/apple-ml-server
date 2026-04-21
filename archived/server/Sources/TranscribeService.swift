import Foundation
@preconcurrency import Speech
import AVFoundation

actor TranscribeService {
    static func transcribe(request: TranscribeRequest) async throws -> TranscribeResponse {
        let startTime = Date()

        // Decode base64 audio
        guard let audioData = Data(base64Encoded: request.audio) else {
            throw MLError.invalidInput("Invalid base64 audio data")
        }

        // Check authorization
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        if authStatus == .notDetermined {
            let granted = await requestAuthorization()
            if !granted {
                throw MLError.notAuthorized
            }
        } else if authStatus != .authorized {
            throw MLError.notAuthorized
        }

        // Determine format
        let format = request.format?.lowercased() ?? "m4a"

        // Write to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "." + format)
        try audioData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Detect language if not specified
        let lang: String
        if let requestLang = request.language, !requestLang.isEmpty {
            lang = requestLang
        } else {
            print("No language specified, detecting...")
            lang = await LanguageDetector.detect(audioURL: tempURL)
        }

        // Use the persistent speech worker
        let timeoutSeconds = TimeInterval(request.timeout ?? 300)
        let result = try await SpeechWorker.shared.transcribe(
            audioURL: tempURL,
            language: lang,
            includeTimestamps: request.timestamps ?? false,
            timeout: timeoutSeconds
        )

        let processingTime = Int64(Date().timeIntervalSince(startTime) * 1000)

        return TranscribeResponse(
            transcript: result.0,
            confidence: result.1,
            language: lang,
            words: result.2,
            processingTimeMs: processingTime,
            error: nil
        )
    }

    private static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
