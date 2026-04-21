# AppleML

On-device speech-to-text and OCR as a native macOS app. Uses Apple's Speech and Vision frameworks with Neural Engine acceleration. All processing runs locally -- no cloud dependencies.

Follows the Ollama pattern: one app, two ways to run it.

## Features

- **Speech-to-Text**: Transcription via `SFSpeechRecognizer` with word-level timestamps
- **OCR**: Text recognition via `VNRecognizeTextRequest` with bounding boxes
- **Automatic Language Detection**: Detects language from audio when not specified
- **On-Device**: All processing on Apple Neural Engine, no data leaves your machine
- **REST API**: JSON API with OpenAPI 3.0 spec, backward-compatible with CLI/SDK
- **GUI**: Drag-drop file upload, history browser, settings
- **Menu Bar**: Always-visible server status indicator

## Requirements

- macOS 14+ (Sonoma)
- Apple Silicon (M1/M2/M3/M4)
- Xcode 15+ (to build)
- Rust 1.75+ (for CLI client, optional)

## Quick Start

### Run as app (GUI + server)

```bash
open AppleML.app
```

Menu bar icon appears, API server starts on port 8080, GUI window available for file uploads and history.

### Run as headless server (like `ollama serve`)

```bash
./AppleML.app/Contents/MacOS/AppleML --serve
```

Server starts on port 8080 with no GUI. Ideal for remote machines or automation.

### Use the CLI client

```bash
# Health check
apple-ml health

# Transcribe (language auto-detected)
apple-ml transcribe -f audio.mp3

# Transcribe with explicit language
apple-ml transcribe -f audio.m4a -l zh-CN --timestamps

# OCR
apple-ml ocr -f screenshot.png
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/version` | GET | Server version |
| `/openapi.yaml` | GET | OpenAPI spec |
| `/transcribe` | POST | Speech-to-text |
| `/ocr` | POST | Image OCR |

See [docs/API.md](docs/API.md) for full API documentation.

## macOS Permissions

As a native `.app` bundle, macOS handles permissions automatically:

- **Speech Recognition**: Prompted automatically on app launch. Click **Allow** in the system dialog.
- **Incoming Network**: Prompted on first remote connection.
- **OCR**: No special permissions required.

No manual TCC configuration or `tccutil` needed.

## Project Structure

```
apple-ml-server/
├── AppleML/                     # Xcode project (macOS app)
│   ├── AppleML.xcodeproj
│   └── AppleML/
│       ├── App/                 # SwiftUI entry, menu bar, lifecycle
│       ├── Views/               # Transcribe, OCR, History, Settings
│       ├── Server/              # Embedded Vapor server + routes
│       ├── Core/                # ML services (shared by GUI and API)
│       └── Storage/             # SwiftData history
├── cli/                         # Rust CLI client
│   ├── Cargo.toml
│   └── src/main.rs
├── sdk/                         # Rust SDK library
│   ├── Cargo.toml
│   └── src/
├── docs/                        # Architecture & design docs
└── README.md
```

## Building

### App (Xcode)

```bash
# Open in Xcode
open AppleML/AppleML.xcodeproj

# Or build from command line
xcodebuild -project AppleML/AppleML.xcodeproj -scheme AppleML -configuration Release build
```

### CLI (Rust)

```bash
cargo build --release
# Binary at ./target/release/apple-ml
```

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| Port | 8080 | API server port |
| Bind address | 0.0.0.0 | Network interface to listen on |
| Launch at login | Off | Start app automatically on login |
| Default language | Auto-detect | Default transcription language |

Settings configurable via the GUI (Settings tab) or environment variables (`PORT`, `HOST`) in headless mode.

## CLI Client

```bash
# Set endpoint (default: localhost:8080)
export APPLE_ML_ENDPOINT=http://mac-mini:8080

# Transcribe
apple-ml transcribe -f audio.m4a -l zh-CN --timestamps -o json

# OCR
apple-ml ocr -f image.png -o json

# Health
apple-ml health
```

## Example: Transcribe with cURL

```bash
curl -X POST http://localhost:8080/transcribe \
  -H "Content-Type: application/json" \
  -d "{\"audio\": \"$(base64 -i audio.m4a)\", \"format\": \"m4a\"}"
```

Language is auto-detected when omitted.
