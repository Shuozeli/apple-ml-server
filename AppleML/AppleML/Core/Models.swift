import Foundation
import Vapor

// Request/Response types - conform to both Codable and Vapor's Content
struct TranscribeRequest: Content {
    let audio: String
    let format: String?
    let language: String?
    let timestamps: Bool?
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

struct OCRRequest: Content {
    let image: String
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
