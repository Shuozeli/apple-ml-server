# Design Notes

<!-- agent-updated: 2026-04-20T15:30:00Z -->

## Architecture: Swift Vapor REST API

The server is a pure Swift application using Vapor, Apple's web framework. No Rust FFI or gRPC.

Rationale:
- Vapor provides high-performance async HTTP handling
- Swift native access to Speech.framework and Vision.framework
- Simple REST API for broad client compatibility
- OpenAPI 3.0 spec embedded for documentation

### Threading Model

Speech recognition callbacks fire on a dedicated thread's RunLoop, not Vapor's async context. `SpeechWorker` manages a persistent thread with its own RunLoop for recognition tasks.

```swift
SpeechWorker.shared.transcribe(audioURL:audioURL, language:language, includeTimestamps:timeout:)
```

---

## Speech Recognition (Speech.framework)

### Authorization

Speech recognition requires user permission. `SFSpeechRecognizer.requestAuthorization` triggers a system dialog on first call. Authorization is per-binary (TCC), not per-session.

```swift
let status = SFSpeechRecognizer.authorizationStatus()
if status == .notDetermined {
    let granted = await requestAuthorization()
    // System dialog shown to user
}
```

First call must be user-initiated (not background). The binary needs permission via `System Settings > Privacy & Security > Speech Recognition`.

### Supported Formats

Speech.framework supports: WAV, MP3, M4A, FLAC, AAC, AIFF.

### Usage Pattern

```swift
import Speech

let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
let request = SFSpeechURLRecognitionRequest(url: audioFileURL)
request.shouldReportPartialResults = false  // batch mode

recognizer.recognitionTask(with: request) { result, error in
    if let result = result, result.isFinal {
        // process result.bestTranscription
    }
}
```

### On-Device Recognition

Use `SFSpeechRecognizer.supportsOnDeviceRecognition` to verify on-device capability. Falls back to cloud when on-device is unavailable.

---

## OCR (Vision.framework)

**Important:** OCR accepts only images (JPEG, PNG, TIFF, BMP). PDFs must be pre-converted using `scripts/pdf_to_images.py`.

### Usage Pattern

```swift
import Vision
import AppKit

guard let nsImage = NSImage(data: imageData),
      let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    throw MLError.invalidInput("Could not decode image")
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true

if let lang = language, !lang.isEmpty {
    request.recognitionLanguages = [lang]
}

let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])
```

### Recognition Level

- `.accurate`: Slower but more accurate. Uses ANE for best performance on Apple Silicon.
- `.fast`: Quicker recognition, may miss difficult text.

### Image Loading

`NSImage(data:)` + `cgImage(forProposedRect:context:hints:)` handles JPEG, PNG, TIFF, BMP reliably.

### Bounding Box Coordinates

Vision uses normalized coordinates (0.0-1.0) with origin at **bottom-left**. Convert to top-left for standard image coordinates:

```swift
yMin = 1.0 - bbox.origin.y - bbox.height
yMax = 1.0 - bbox.origin.y
```

---

## Error Handling

All errors implement `MLError` and map to HTTP status codes:

```swift
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
}
```

| Error | HTTP Status | Description |
|-------|-------------|-------------|
| `invalidInput(msg)` | 400 | Malformed base64, unsupported format |
| `notAuthorized` | 403 | Speech recognition not permitted |
| `languageNotSupported` | 400 | Language not available |
| `recognitionFailed(msg)` | 500 | Speech/Vision processing error |

---

## Request/Response Types

### TranscribeRequest

```swift
struct TranscribeRequest: Content {
    let audio: String           // Base64-encoded audio
    let format: String?         // "wav", "mp3", "m4a", "flac"
    let language: String?       // BCP-47 (e.g., "en-US")
    let timestamps: Bool?       // Include word timings
    let timeout: Int?           // Seconds, default 300
}
```

### TranscribeResponse

```swift
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
```

### OCRRequest

```swift
struct OCRRequest: Content {
    let image: String     // Base64-encoded image
    let language: String? // BCP-47 (e.g., "en-US")
}
```

### OCRResponse

```swift
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
```

---

## Performance Considerations

1. **Apple Silicon ANE:** Both Speech and Vision frameworks automatically use the Apple Neural Engine for acceleration.
2. **Recognition Level:** Use `.accurate` for OCR — better results on real-world images with minimal speed penalty on ANE.
3. **Image Resolution:** Render PDFs at 2x resolution for better OCR accuracy (handled by `pdf_to_images.py`).
4. **Thread-per-Request:** `SpeechWorker` spawns a dedicated thread per recognition task to handle RunLoop-based callbacks.

---

## Privacy & Permissions

Speech recognition requires user authorization:
1. First call triggers `SFSpeechRecognizer.requestAuthorization`
2. System shows permission dialog (must be user-initiated)
3. Permission is cached per-binary in TCC database

OCR (Vision.framework) does not require special permissions.
