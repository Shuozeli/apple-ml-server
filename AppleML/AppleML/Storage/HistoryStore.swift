import Foundation
import SwiftData

actor HistoryStore {
    static let shared = HistoryStore()

    private var container: ModelContainer?

    private init() {}

    func setup(container: ModelContainer) {
        self.container = container
    }

    @discardableResult
    func add(
        type: HistoryItem.ItemType,
        inputFileName: String?,
        language: String,
        result: String,
        confidence: Float,
        processingTimeMs: Int64
    ) -> HistoryItem? {
        guard let container = container else { return nil }
        let context = ModelContext(container)
        let item = HistoryItem(
            type: type,
            inputFileName: inputFileName,
            language: language,
            result: result,
            confidence: confidence,
            processingTimeMs: processingTimeMs
        )
        context.insert(item)
        try? context.save()
        return item
    }

    func fetchAll() -> [HistoryItem] {
        guard let container = container else { return [] }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HistoryItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func search(query: String) -> [HistoryItem] {
        guard let container = container else { return [] }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HistoryItem>(
            predicate: #Predicate { item in
                item.result.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func delete(id: UUID) {
        guard let container = container else { return }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HistoryItem>(
            predicate: #Predicate { item in
                item.id == id
            }
        )
        if let items = try? context.fetch(descriptor), let item = items.first {
            context.delete(item)
            try? context.save()
        }
    }

    func clearAll() {
        guard let container = container else { return }
        let context = ModelContext(container)
        do {
            try context.delete(model: HistoryItem.self)
            try context.save()
        } catch {
            print("Failed to clear history: \(error)")
        }
    }
}
