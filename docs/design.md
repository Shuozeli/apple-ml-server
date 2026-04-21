<!-- agent-updated: 2026-04-21T06:00:00Z -->

# Design Notes

## App Model: The Ollama Pattern

AppleML follows the same pattern as Ollama: a native app that embeds an HTTP API server. Users interact either through the GUI or by sending requests to the API from any HTTP client.

### Why an app instead of a CLI server?

| Concern | CLI server (old) | App (new) |
|---------|-----------------|-----------|
| Permissions | Requires hacky Info.plist embedding in Mach-O binary; TCC often fails silently | Native `.app` bundle; macOS prompts naturally on first use |
| Lifecycle | Manual start/stop, easy to forget | Menu bar always-on, launch at login |
| Discoverability | Hidden in terminal | Visible in Applications, Dock, menu bar |
| User interaction | CLI/cURL only | GUI for uploads, history browsing, settings |
| Distribution | `swift build` | DMG, Homebrew cask, or `.app` drag-to-install |

### Dual-mode entry point

```swift
@main
struct AppleMLApp: App {
    init() {
        // Detect --serve flag for headless mode
        if CommandLine.arguments.contains("--serve") {
            // Start server only, no GUI
            ServerManager.shared.start()
            RunLoop.main.run() // Block forever
        }
    }

    var body: some Scene {
        MenuBarExtra("AppleML", systemImage: "waveform.circle.fill") {
            MenuBarView()
        }
        Window("AppleML", id: "main") {
            MainView()
        }
    }
}
```

---

## GUI Design

### Layout: NavigationSplitView

The app uses a two-column layout inspired by Gemini/ChatGPT:

```
┌──── Sidebar ─────┬──────────── Main Area ──────────────────┐
│                  │                                          │
│  [+ New Task]    │   What would you like to do?             │
│                  │                                          │
│  [Search...]     │   ┌────────────┐  ┌────────────┐       │
│                  │   │  Transcribe │  │    OCR     │  ...  │
│  -- Today --     │   │  Audio>Text │  │  Image>Text│       │
│  ~ "今天我们..." │   └────────────┘  └────────────┘       │
│    zh-CN audio   │                                          │
│  ~ "Hello..."    │                                          │
│    en-US image   │                                          │
│                  │                                          │
│  -- Yesterday -- │                                          │
│  ~ ...           │                                          │
│                  │                                          │
│  [Clear History] │                                          │
└──────────────────┴──────────────────────────────────────────┘
```

- **Sidebar**: "New Task" button, searchable history grouped by date, "Clear History" at bottom
- **Main area**: Feature selection cards (initial), or the active workspace after selecting a feature
- **History click**: Shows result detail in the main area
- **Feature strip**: After selecting a feature, a vertical icon strip on the left lets you switch tools

### Menu Bar

Always-visible menu bar icon (`waveform.circle.fill`):
- Server status (green/red dot)
- Port and request count
- Open main window
- Start/stop server
- Quit

### Feature Cards

Each ML capability is represented as a card in the `NewTaskView`. Adding a new feature requires only adding a case to the `MLFeature` enum -- the card and feature strip render automatically.

Current features:
- **Transcribe** (waveform icon, blue) -- Audio to text
- **OCR** (doc.text.viewfinder icon, orange) -- Image to text

### Workspace Views

After selecting a feature card:

**Transcribe**: Drop zone for audio files (WAV, MP3, M4A, FLAC), language field (auto-detect default), timestamps toggle, transcribe button, scrollable result with copy button.

**OCR**: Drop zone for images (JPEG, PNG, TIFF, BMP) with preview, language field, recognize button, scrollable result with copy button.

### History

- Sidebar shows history grouped by date (Today, Yesterday, date)
- Right-click any item to delete
- Click to view full detail in main area (type, language, confidence, processing time, full text)
- "Clear History" button at bottom with confirmation dialog
- Search filters across all result text and file names

---

## Server Architecture

### ServerManager

Owns the Vapor `Application` lifecycle. Exposes observable state for the GUI.

```swift
@Observable
final class ServerManager {
    static let shared = ServerManager()

    var isRunning = false
    var port: Int = 8080
    var bindAddress: String = "0.0.0.0"
    var requestCount: Int = 0

    func start() { ... }
    func stop() { ... }
}
```

### Routes

Same API as before, registered on the Vapor app:

```swift
func registerRoutes(on app: Application) {
    app.get("health") { _ in "OK" }
    app.get("version") { _ in ["version": VERSION, "name": "AppleML"] }
    app.post("transcribe") { req in ... }
    app.post("ocr") { req in ... }
    app.get("openapi.yaml") { req in ... }
}
```

### History Integration

Both GUI and API paths write to the same `HistoryStore`:

```swift
// After transcription completes (in both GUI and API paths):
await HistoryStore.shared.add(
    type: .transcribe,
    inputFileName: filename,
    language: detectedLanguage,
    result: transcript,
    confidence: confidence,
    processingTimeMs: elapsed
)
```

---

## Core Services (Unchanged)

### TranscribeService

- Decodes base64 audio, writes temp file
- If language not specified: calls `LanguageDetector.detect()`
- Delegates to `SpeechWorker.shared.transcribe()`
- Returns transcript + confidence + word timings

### LanguageDetector

- Extracts 10-second audio sample via `AVAssetExportSession`
- Tries candidate locales sequentially (en-US, zh-CN, ja-JP, ko-KR, ...)
- Stops on first locale above confidence threshold
- Returns detected BCP-47 locale

### SpeechWorker

- Spawns dedicated `Thread` per recognition (required for RunLoop callbacks)
- Uses `SFSpeechURLRecognitionRequest` for batch recognition
- Tracks partial confidence from intermediate results
- Returns on completion or timeout

### OCRService

- Decodes base64 image to `NSImage` -> `CGImage`
- `VNRecognizeTextRequest` with `.accurate` level
- Converts Vision bottom-left coordinates to top-left
- Returns text blocks with bounding boxes

---

## Storage

### SwiftData Model

```swift
@Model
final class HistoryItem {
    var id: UUID
    var timestamp: Date
    var type: ItemType  // .transcribe or .ocr
    var inputFileName: String?
    var language: String
    var result: String
    var confidence: Float
    var processingTimeMs: Int64

    enum ItemType: String, Codable {
        case transcribe
        case ocr
    }
}
```

SwiftData handles persistence automatically in the app's container directory.

---

## Permissions & Entitlements

### Info.plist keys

| Key | Value |
|-----|-------|
| `NSSpeechRecognitionUsageDescription` | "AppleML uses speech recognition to transcribe audio files." |
| `NSMicrophoneUsageDescription` | "AppleML can record audio for transcription." (future) |

### Entitlements

| Entitlement | Purpose |
|-------------|---------|
| `com.apple.security.network.server` | Accept incoming HTTP connections |
| `com.apple.security.network.client` | Outgoing connections (if cloud fallback needed) |
| `com.apple.security.files.user-selected.read-only` | Read user-selected files (file picker) |

---

## Settings

Stored in `UserDefaults` (standard for macOS apps):

| Setting | Default | Description |
|---------|---------|-------------|
| `port` | 8080 | API server port |
| `bindAddress` | "0.0.0.0" | Bind address |
| `launchAtLogin` | false | Start app on login |
| `defaultLanguage` | nil (auto-detect) | Default transcription language |

---

## Future Considerations

- **Live audio recording**: Add microphone input for real-time transcription
- **Drag-drop from Finder**: Already supported by SwiftUI `onDrop`
- **Keyboard shortcuts**: Global hotkey to start/stop recording
- **Export history**: CSV/JSON export of all results
- **Homebrew cask**: `brew install --cask apple-ml` for easy installation
