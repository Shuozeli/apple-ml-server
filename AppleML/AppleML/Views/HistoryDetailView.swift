import SwiftUI

struct HistoryDetailView: View {
    let item: HistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: item.type == .transcribe ? "waveform" : "doc.text.viewfinder")
                    .font(.title2)
                    .foregroundStyle(item.type == .transcribe ? .blue : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.type == .transcribe ? "Transcription" : "OCR Result")
                        .font(.title3.weight(.semibold))
                    Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.result, forType: .string)
                }
                .buttonStyle(.bordered)
            }

            // Metadata
            HStack(spacing: 16) {
                Label(item.language, systemImage: "globe")
                Label("\(Int(item.confidence * 100))%", systemImage: "checkmark.circle")
                Label("\(item.processingTimeMs)ms", systemImage: "timer")
                if let fileName = item.inputFileName {
                    Label(fileName, systemImage: "doc")
                }
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            Divider()

            // Result text
            ScrollView {
                Text(item.result)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.body)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
