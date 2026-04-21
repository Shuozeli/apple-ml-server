import SwiftUI
import UniformTypeIdentifiers

struct OCRView: View {
    @State private var selectedFileURL: URL?
    @State private var fileName: String = ""
    @State private var language: String = ""
    @State private var isProcessing = false
    @State private var result: OCRResponse?
    @State private var errorMessage: String?
    @State private var isDragOver = false
    @State private var previewImage: NSImage?

    private let supportedTypes: [UTType] = [.image, .jpeg, .png, .tiff, .bmp]

    var body: some View {
        VStack(spacing: 20) {
            // Drop zone / preview
            dropZone

            // Options
            HStack(spacing: 16) {
                HStack {
                    Text("Language:")
                    TextField("Auto-detect", text: $language)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                }

                Spacer()

                Button("Recognize Text") {
                    runOCR()
                }
                .disabled(selectedFileURL == nil || isProcessing)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            if isProcessing {
                ProgressView("Recognizing...")
                    .padding()
            }

            if let result = result {
                resultView(result)
            }

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

            if let image = previewImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Drop image here")
                        .font(.headline)
                    Text("JPEG, PNG, TIFF, BMP")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 150)
        .padding(.horizontal)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers)
        }
        .onTapGesture {
            pickFile()
        }
    }

    private func resultView(_ result: OCRResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Result")
                    .font(.headline)
                Spacer()
                Text("Confidence: \(Int(result.confidence * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(result.processingTimeMs)ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(result.text, forType: .string)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            ScrollView {
                Text(result.text)
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
            setFile(url)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async { setFile(url) }
        }
        return true
    }

    private func setFile(_ url: URL) {
        selectedFileURL = url
        fileName = url.lastPathComponent
        previewImage = NSImage(contentsOf: url)
        result = nil
        errorMessage = nil
    }

    private func runOCR() {
        guard let url = selectedFileURL else { return }
        isProcessing = true
        errorMessage = nil
        result = nil

        Task {
            do {
                let lang = language.isEmpty ? nil : language
                let response = try await OCRService.shared.recognizeFile(url: url, language: lang)
                await MainActor.run {
                    result = response
                    isProcessing = false
                }
                await HistoryStore.shared.add(
                    type: .ocr,
                    inputFileName: fileName,
                    language: lang ?? "auto",
                    result: response.text,
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
