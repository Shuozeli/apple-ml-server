import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HistoryItem.timestamp, order: .reverse) private var historyItems: [HistoryItem]
    @State private var selectedHistoryItem: HistoryItem?
    @State private var isShowingNewTask = true
    @State private var searchText = ""
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if isShowingNewTask {
                NewTaskView()
            } else if let item = selectedHistoryItem {
                HistoryDetailView(item: item)
            } else {
                placeholder
            }
        }
        .frame(minWidth: 750, minHeight: 500)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // New task button
            Button {
                selectedHistoryItem = nil
                isShowingNewTask = true
            } label: {
                Label("New Task", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Divider()
                .padding(.vertical, 4)

            // History list
            List(selection: $selectedHistoryItem) {
                ForEach(groupedHistory.keys.sorted().reversed(), id: \.self) { section in
                    Section(section) {
                        ForEach(groupedHistory[section] ?? []) { item in
                            HistorySidebarRow(item: item)
                                .tag(item)
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        deleteItem(item)
                                    }
                                }
                        }
                        .onDelete { indexSet in
                            deleteItems(in: section, at: indexSet)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $searchText, prompt: "Search history...")
            .onChange(of: selectedHistoryItem) { _, newValue in
                if newValue != nil {
                    isShowingNewTask = false
                }
            }

            Divider()

            // Clear all button
            Button(role: .destructive) {
                showClearConfirmation = true
            } label: {
                Label("Clear History", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .disabled(historyItems.isEmpty)
            .confirmationDialog("Clear all history?", isPresented: $showClearConfirmation) {
                Button("Clear All", role: .destructive) {
                    clearAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all history items.")
            }
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 350)
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Select a history item or start a new task")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Delete

    private func deleteItem(_ item: HistoryItem) {
        if selectedHistoryItem == item {
            selectedHistoryItem = nil
            isShowingNewTask = true
        }
        modelContext.delete(item)
        try? modelContext.save()
    }

    private func deleteItems(in section: String, at offsets: IndexSet) {
        guard let sectionItems = groupedHistory[section] else { return }
        for index in offsets {
            deleteItem(sectionItems[index])
        }
    }

    private func clearAll() {
        selectedHistoryItem = nil
        isShowingNewTask = true
        for item in historyItems {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }

    // MARK: - Grouping

    private var filteredHistory: [HistoryItem] {
        if searchText.isEmpty {
            return historyItems
        }
        return historyItems.filter {
            $0.result.localizedCaseInsensitiveContains(searchText) ||
            ($0.inputFileName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var groupedHistory: [String: [HistoryItem]] {
        Dictionary(grouping: filteredHistory) { item in
            let calendar = Calendar.current
            if calendar.isDateInToday(item.timestamp) {
                return "Today"
            } else if calendar.isDateInYesterday(item.timestamp) {
                return "Yesterday"
            } else {
                return item.timestamp.formatted(.dateTime.month().day())
            }
        }
    }
}

// MARK: - Sidebar Row

struct HistorySidebarRow: View {
    let item: HistoryItem

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.type == .transcribe ? "waveform" : "doc.text.viewfinder")
                .foregroundStyle(item.type == .transcribe ? .blue : .orange)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.result.prefix(40) + (item.result.count > 40 ? "..." : ""))
                    .lineLimit(1)
                    .font(.callout)

                HStack(spacing: 6) {
                    Text(item.language)
                    if let name = item.inputFileName {
                        Text(name)
                            .lineLimit(1)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
