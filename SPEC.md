<!-- agent-updated: 2026-04-21T06:00:00Z -->

# AppleML Specification

## Overview

AppleML is a native macOS application providing on-device speech-to-text and OCR via Apple's ML frameworks. It follows the Ollama pattern: a single app that serves as both a GUI application and an HTTP API server. All inference runs locally on Apple Silicon with Neural Engine acceleration.

## Launch Modes

| Mode | Command | Behavior |
|------|---------|----------|
| **App** | Double-click or `open AppleML.app` | Menu bar icon + GUI window + API server |
| **Headless** | `AppleML.app/Contents/MacOS/AppleML --serve` | API server only, no GUI |

## Features

### Speech-to-Text (Transcription)
- **Input:** Audio files (WAV, MP3, M4A, FLAC, AAC, AIFF) via API (base64) or GUI (file picker/drag-drop)
- **Language:** Client-specified BCP-47 tag or automatic detection
- **Auto-detection:** Extracts 10s sample, tries candidate locales sequentially, picks highest confidence
- **Output:** Transcript with confidence scores and optional word-level timestamps
- **Framework:** Speech.framework (`SFSpeechRecognizer`)

### OCR (Optical Character Recognition)
- **Input:** Images (JPEG, PNG, TIFF, BMP) via API (base64) or GUI (file picker/drag-drop)
- **Language:** Client-specified or auto-detection
- **Output:** Text blocks with bounding boxes and confidence scores
- **Framework:** Vision.framework (`VNRecognizeTextRequest`, `.accurate` level)
- **Note:** PDFs not directly supported; pre-convert to images

### GUI
- **Menu bar icon:** Always-visible server status indicator (green/red)
- **Transcribe tab:** Drag-drop audio upload, language picker, progress, results
- **OCR tab:** Drag-drop image upload, results with text blocks
- **History tab:** Searchable list of all past results (SwiftData)
- **Settings tab:** Port, bind address, launch at login, default language

### History
- All transcription and OCR results stored locally via SwiftData
- Shared between GUI and API requests
- Searchable, filterable by type and date

## API

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| GET | `/version` | Server version info |
| GET | `/openapi.yaml` | OpenAPI 3.0 specification |
| POST | `/transcribe` | Speech-to-text transcription |
| POST | `/ocr` | Image OCR |

API is fully backward-compatible with the previous CLI server version.

### Transport
- **Protocol:** HTTP/JSON over TCP
- **Data encoding:** Base64 for binary payloads
- **Default port:** 8080 (configurable)
- **Default bind:** 0.0.0.0 (configurable)

### Error Handling

| Status | Error | Description |
|--------|-------|-------------|
| 400 | Invalid input | Malformed base64, unsupported format, unsupported language |
| 403 | Not authorized | Speech recognition permission not granted |
| 500 | Recognition failed | ML framework processing error |

## Requirements

- macOS 14+ (Sonoma)
- Apple Silicon (M1/M2/M3/M4) for ANE acceleration
- Xcode 15+ (to build)
- Rust 1.75+ (for CLI client, optional)

## Permissions

| Permission | When prompted | Required for |
|------------|---------------|--------------|
| Speech Recognition | App launch (prompted automatically) | Transcription |
| Incoming Network | First remote connection | API server |

As a proper `.app` bundle, macOS handles permission prompts natively. No manual TCC configuration needed.

## Client Ecosystem

| Component | Language | Description |
|-----------|----------|-------------|
| AppleML.app | Swift | Server + GUI (this project) |
| `apple-ml` CLI | Rust | Command-line client |
| `apple-ml-sdk` | Rust | Library for programmatic access |

## Repository Structure

```
apple-ml-server/
├── AppleML/                     # Xcode project (macOS app)
│   ├── AppleML.xcodeproj
│   └── AppleML/
│       ├── App/                 # SwiftUI app entry, menu bar
│       ├── Views/               # Transcribe, OCR, History, Settings
│       ├── Server/              # Embedded Vapor server + routes
│       ├── Core/                # ML services (transcribe, OCR, language detect)
│       └── Storage/             # SwiftData history
├── cli/                         # Rust CLI client
├── sdk/                         # Rust SDK library
├── docs/                        # Documentation
└── README.md
```
