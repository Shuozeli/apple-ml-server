import SwiftUI
import UniformTypeIdentifiers

struct TranscribeView: View {
    @State private var selectedFileURL: URL?
    @State private var fileName: String = ""
    @State private var language: String = ""
    @State private var includeTimestamps = false
    @State private var isProcessing = false
    @State private var result: TranscribeResponse?
    @State private var errorMessage: String?
    @State private var isDragOver = false

    private let supportedTypes: [UTType] = [.audio, .mpeg4Audio, .mp3, .wav, .aiff]

    var body: some View {
        VStack(spacing: 20) {
            // Drop zone
            dropZone

            // Options
            HStack(spacing: 16) {
                HStack {
                    Text("Language:")
                    TextField("Auto-detect", text: $language)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                }

                Toggle("Timestamps", isOn: $includeTimestamps)

                Spacer()

                Button("Transcribe") {
                    transcribe()
                }
                .disabled(selectedFileURL == nil || isProcessing)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            // Progress
            if isProcessing {
                ProgressView("Transcribing...")
                    .padding()
            }

            // Result
            if let result = result {
                resultView(result)
            }

            // Error
            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .padding()
            }

            Spacer()
        }
        .padding()
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDragOver ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDragOver ? Color.accentColor.opacity(0.05) : Color.clear)
                )

            VStack(spacing: 8) {
                Image(systemName: selectedFileURL != nil ? "checkmark.circle.fill" : "waveform.badge.plus")
                    .font(.system(size: 36))
                    .foregroundStyle(selectedFileURL != nil ? .green : .secondary)

                if let url = selectedFileURL {
                    Text(url.lastPathComponent)
                        .font(.headline)
                } else {
                    Text("Drop audio file here")
                        .font(.headline)
                    Text("WAV, MP3, M4A, FLAC, AAC, AIFF")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 120)
        .padding(.horizontal)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers)
        }
        .onTapGesture {
            pickFile()
        }
    }

    private func resultView(_ result: TranscribeResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Result")
                    .font(.headline)
                Spacer()
                Text("Language: \(result.language)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Confidence: \(Int(result.confidence * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(result.processingTimeMs)ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(result.transcript, forType: .string)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            ScrollView {
                Text(result.transcript)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = supportedTypes
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            selectedFileURL = url
            fileName = url.lastPathComponent
            result = nil
            errorMessage = nil
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async {
                selectedFileURL = url
                fileName = url.lastPathComponent
                result = nil
                errorMessage = nil
            }
        }
        return true
    }

    private func transcribe() {
        guard let url = selectedFileURL else { return }
        isProcessing = true
        errorMessage = nil
        result = nil

        Task {
            do {
                let lang = language.isEmpty ? nil : language
                let response = try await TranscribeService.shared.transcribeFile(
                    url: url,
                    language: lang,
                    timestamps: includeTimestamps
                )
                await MainActor.run {
                    result = response
                    isProcessing = false
                }
                // Save to history
                await HistoryStore.shared.add(
                    type: .transcribe,
                    inputFileName: fileName,
                    language: response.language,
                    result: response.transcript,
                    confidence: response.confidence,
                    processingTimeMs: response.processingTimeMs
                )
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
}
