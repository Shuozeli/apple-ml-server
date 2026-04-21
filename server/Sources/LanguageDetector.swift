import Foundation
@preconcurrency import Speech
import AVFoundation

actor LanguageDetector {
    /// Candidate locales in priority order.
    private static let candidates = [
        "en-US", "zh-CN", "ja-JP", "ko-KR", "es-ES",
        "fr-FR", "de-DE", "pt-BR",
    ]

    /// How many seconds of audio to extract for the detection sample.
    private static let sampleSeconds: TimeInterval = 10

    /// Per-candidate recognition timeout.
    private static let detectionTimeout: TimeInterval = 30

    /// If a candidate's confidence exceeds this, use it immediately.
    private static let earlyExitThreshold: Float = 0.15

    /// Detect the language of an audio file.
    ///
    /// 1. Extract a short sample from the beginning of the audio.
    /// 2. Try candidate locales sequentially on that sample.
    /// 3. Return the first locale above the confidence threshold, or the best.
    static func detect(audioURL: URL) async -> String {
        // Extract a short sample to speed up each recognition pass
        let sampleURL: URL
        do {
            sampleURL = try await extractSample(from: audioURL)
        } catch {
            log("Sample extraction failed (\(error)), falling back to full file")
            sampleURL = audioURL
        }
        defer {
            if sampleURL != audioURL {
                try? FileManager.default.removeItem(at: sampleURL)
            }
        }

        var results: [(locale: String, confidence: Float)] = []

        for locale in candidates {
            let confidence: Float
            do {
                let result = try await SpeechWorker.shared.transcribe(
                    audioURL: sampleURL,
                    language: locale,
                    includeTimestamps: false,
                    timeout: detectionTimeout
                )
                confidence = result.confidence
            } catch {
                log("  \(locale): error - \(error)")
                confidence = 0
            }

            results.append((locale, confidence))
            log("  \(locale): \(String(format: "%.3f", confidence))")

            if confidence >= earlyExitThreshold {
                log("Language detected: \(locale) (early exit)")
                return locale
            }
        }

        let best = results.max(by: { $0.confidence < $1.confidence })
        let detected = best?.locale ?? "en-US"
        log("Language detected: \(detected) (best of \(results.count))")
        return detected
    }

    /// Extract the first N seconds of audio into a temp .m4a file.
    private static func extractSample(from url: URL) async throws -> URL {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let sampleDuration = min(
            CMTime(seconds: sampleSeconds, preferredTimescale: 44100),
            duration
        )

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("langdetect_\(UUID().uuidString).m4a")

        guard let exporter = AVAssetExportSession(
            asset: asset, presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw MLError.recognitionFailed("Cannot create audio export session")
        }

        exporter.outputURL = tempURL
        exporter.outputFileType = .m4a
        exporter.timeRange = CMTimeRange(start: .zero, duration: sampleDuration)

        await exporter.export()

        guard exporter.status == .completed else {
            let msg = exporter.error?.localizedDescription ?? "unknown error"
            throw MLError.recognitionFailed("Audio sample export failed: \(msg)")
        }

        log("Extracted \(String(format: "%.1f", sampleDuration.seconds))s sample")
        return tempURL
    }

    private static func log(_ message: String) {
        FileHandle.standardError.write(Data(("[LangDetect] " + message + "\n").utf8))
    }
}
