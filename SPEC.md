# apple-ml-server Specification

<!-- agent-updated: 2026-04-20T15:30:00Z -->

## Overview

On-device Apple ML inference server exposing REST API endpoints for speech-to-text transcription and OCR. Built with Swift Vapor, leveraging Apple Silicon Neural Engine (ANE) acceleration via Speech.framework and Vision.framework.

## Features & Capabilities

### Speech-to-Text (Transcription)
- **Input:** Base64-encoded audio files (WAV, MP3, M4A, FLAC)
- **Language:** Client-specified BCP-47 tag or auto-detection
- **Output:** Transcript with confidence scores and optional word-level timestamps
- **Mode:** Synchronous REST request/response

### OCR (Optical Character Recognition)
- **Input:** Base64-encoded images only (JPEG, PNG, TIFF, BMP)
- **Language:** Client-specified or auto-detection
- **Output:** Text blocks with bounding boxes and confidence scores
- **Mode:** Synchronous REST request/response
- **Note:** PDFs are not supported. Use `scripts/pdf_to_images.py` to convert first.

## Architecture

```
Client (HTTP/JSON) ──► Apple ML Server (Swift / Vapor)
                              │
                              ├── Speech.framework (SFSpeechRecognizer)
                              └── Vision.framework (VNRecognizeTextRequest)
```

- **Transport:** HTTP/JSON over TCP
- **Serialization:** JSON with base64-encoded binary data
- **Port:** 8080 (configurable via `PORT` env var)

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| GET | `/version` | Server version info |
| GET | `/openapi.yaml` | OpenAPI 3.0 specification |
| POST | `/transcribe` | Speech-to-text transcription |
| POST | `/ocr` | Image OCR |

## Error Handling

All errors return JSON with `error: true` and `reason` field. HTTP status codes indicate error type:

| Status | Description |
|--------|-------------|
| `400` | Invalid input (malformed base64, unsupported format) |
| `403` | Not authorized (speech recognition permission denied) |
| `500` | Recognition failed (ML framework error) |

## Deployment

- **Runtime:** Swift binary (Vapor)
- **Target:** macOS 14+ (Apple Silicon preferred for ANE acceleration)
- **Port:** 8080 (configurable via `PORT` env var)
- **Env:** `HOST` (default: `0.0.0.0`), `PORT` (default: `8080`)

## Repository Structure

```
apple-ml-server/
├── server/                   # Swift Vapor REST API server
│   ├── Package.swift
│   └── Sources/
│       ├── main.swift        # Entry point, routes, OpenAPI spec
│       ├── Models.swift      # Request/Response types, MLError
│       ├── TranscribeService.swift
│       ├── OCRService.swift
│       └── SpeechWorker.swift
├── cli/                      # Rust CLI client
│   ├── Cargo.toml
│   └── src/main.rs
├── openapi.yaml              # OpenAPI 3.0 specification
├── scripts/
│   └── pdf_to_images.py      # PDF → image pre-processor
├── docs/                     # Design documentation
│   ├── architecture.md
│   ├── design.md
│   ├── API.md
│   └── tasks.md
└── Makefile
```
