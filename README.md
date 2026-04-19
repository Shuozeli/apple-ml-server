# Apple ML Server

On-device speech-to-text and OCR REST API server using Apple's Vision and Speech frameworks. All inference runs locally on Apple Silicon with Neural Engine acceleration.

## Features

- **Speech-to-Text**: Transcription via `SFSpeechRecognizer` with word-level timestamps
- **OCR**: Text recognition via `VNRecognizeTextRequest` with bounding boxes
- **On-Device**: No cloud dependencies, all processing on Apple Neural Engine
- **REST API**: Simple JSON API with OpenAPI 3.0 spec
- **Multi-language**: Supports multiple languages (en-US, zh-CN, etc.)

## Requirements

- macOS 14+ (Sonoma)
- Apple Silicon (M1/M2/M3/M4)
- Swift 5.9+
- Rust 1.75+ (for CLI)

## Quick Start

```bash
# Build server and CLI
make release

# Run the server
make run-release

# Test with CLI
./cli/target/release/apple-ml health
./cli/target/release/apple-ml transcribe -f audio.m4a -l zh-CN
./cli/target/release/apple-ml ocr -f image.png
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/version` | GET | Server version |
| `/openapi.yaml` | GET | OpenAPI spec |
| `/transcribe` | POST | Speech-to-text |
| `/ocr` | POST | Image OCR |

See [openapi.yaml](openapi.yaml) for full API documentation.

## CLI Usage

```bash
# Set server endpoint (default: localhost:8080)
export APPLE_ML_ENDPOINT=http://mac-mini:8080

# Transcribe audio
apple-ml transcribe -f audio.m4a -l zh-CN

# With timestamps and JSON output
apple-ml transcribe -f audio.m4a -l en-US --timestamps -o json

# OCR an image
apple-ml ocr -f screenshot.png

# Health check
apple-ml health
```

## Project Structure

```
apple-ml-server/
├── server/                 # Vapor REST API server
│   ├── Package.swift
│   └── Sources/
│       ├── main.swift
│       ├── Models.swift
│       ├── OCRService.swift
│       ├── TranscribeService.swift
│       └── SpeechWorker.swift
├── cli/                    # Rust CLI client
│   ├── Cargo.toml
│   └── src/main.rs
├── openapi.yaml            # OpenAPI 3.0 spec
├── Makefile
└── README.md
```

## Build Commands

| Command | Description |
|---------|-------------|
| `make build` | Build server + CLI (debug) |
| `make release` | Build server + CLI (release) |
| `make run` | Run server (debug) |
| `make run-release` | Run server (release) |
| `make stop` | Stop server |
| `make clean` | Clean build artifacts |
| `make install-cli` | Install CLI to /usr/local/bin |
| `make test` | Test server endpoints |

## Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | `0.0.0.0` | Server bind address |
| `PORT` | `8080` | Server port |
| `APPLE_ML_ENDPOINT` | `http://localhost:8080` | CLI server endpoint |

## Example: Transcribe Audio

```bash
# Using curl
curl -X POST http://localhost:8080/transcribe \
  -H "Content-Type: application/json" \
  -d "{\"audio\": \"$(base64 -i audio.m4a)\", \"language\": \"zh-CN\"}"

# Using CLI
apple-ml transcribe -f audio.m4a -l zh-CN --timestamps -o json
```

## Example: OCR Image

```bash
# Using curl
curl -X POST http://localhost:8080/ocr \
  -H "Content-Type: application/json" \
  -d "{\"image\": \"$(base64 -i image.png)\"}"

# Using CLI
apple-ml ocr -f image.png -o json
```
