import Vapor
import Foundation

// MARK: - OCR

struct OCRRequest: Content {
    /// Base64-encoded image data
    let image: String
    /// BCP-47 language code (optional, e.g., "en-US", "zh-CN")
    let language: String?
}

struct OCRResponse: Content {
    let text: String
    let blocks: [TextBlock]
    let confidence: Float
    let processingTimeMs: Int64
    let error: String?

    struct TextBlock: Content {
        let text: String
        let confidence: Float
        let boundingBox: BoundingBox
    }

    struct BoundingBox: Content {
        let xMin: Float
        let yMin: Float
        let xMax: Float
        let yMax: Float
    }
}

// MARK: - Transcribe

struct TranscribeRequest: Content {
    /// Base64-encoded audio data
    let audio: String
    /// Audio format: "wav", "mp3", "m4a", "flac"
    let format: String?
    /// BCP-47 language code (optional, e.g., "en-US", "zh-CN")
    let language: String?
    /// Include word-level timestamps
    let timestamps: Bool?
    /// Timeout in seconds (default: 300)
    let timeout: Int?
}

struct TranscribeResponse: Content {
    let transcript: String
    let confidence: Float
    let language: String
    let words: [WordTiming]?
    let processingTimeMs: Int64
    let error: String?

    struct WordTiming: Content {
        let word: String
        let confidence: Float
        let startMs: Int64
        let endMs: Int64
    }
}

// MARK: - Errors

enum MLError: Error, AbortError {
    case invalidInput(String)
    case notAuthorized
    case languageNotSupported
    case recognitionFailed(String)

    var status: HTTPResponseStatus {
        switch self {
        case .invalidInput: return .badRequest
        case .notAuthorized: return .forbidden
        case .languageNotSupported: return .badRequest
        case .recognitionFailed: return .internalServerError
        }
    }

    var reason: String {
        switch self {
        case .invalidInput(let msg): return "Invalid input: \(msg)"
        case .notAuthorized: return "Speech recognition not authorized. Grant permission in System Settings > Privacy & Security > Speech Recognition."
        case .languageNotSupported: return "Language not supported"
        case .recognitionFailed(let msg): return "Recognition failed: \(msg)"
        }
    }
}
