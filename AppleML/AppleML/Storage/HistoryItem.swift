import Foundation
import SwiftData

@Model
final class HistoryItem {
    var id: UUID
    var timestamp: Date
    var type: ItemType
    var inputFileName: String?
    var language: String
    var result: String
    var confidence: Float
    var processingTimeMs: Int64

    enum ItemType: String, Codable {
        case transcribe
        case ocr
    }

    init(
        type: ItemType,
        inputFileName: String?,
        language: String,
        result: String,
        confidence: Float,
        processingTimeMs: Int64
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.inputFileName = inputFileName
        self.language = language
        self.result = result
        self.confidence = confidence
        self.processingTimeMs = processingTimeMs
    }
}
