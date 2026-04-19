# Tasks

<!-- agent-updated: 2026-04-20T15:20:00Z -->

## Pending

- [ ] **Production deployment**: Build release binary, deploy to mac mini
- [ ] **Code review**: Address Swift/Rust code quality issues (see below)
- [ ] **Tests**: Add unit/integration tests for TranscribeService and OCRService
- [ ] **PDF OCR support**: Pre-convert PDFs to images using scripts/pdf_to_images.py
- [ ] **Streaming responses**: Support chunked streaming for long audio transcription
- [ ] **Batch OCR**: Accept multiple images in single request

## In Progress

## Completed

- [x] Swift Vapor REST API server (2026-04-20)
- [x] Rust CLI client with clap (2026-04-20)
- [x] OpenAPI 3.0 specification embedded in server (2026-04-20)
- [x] OCR with Vision.framework (accurate recognition level) (2026-04-20)
- [x] Transcription with Speech.framework (2026-04-20)
- [x] Authorization handling with requestAuthorization (2026-04-20)
- [x] CORS middleware enabled (2026-04-20)
- [x] Health check and version endpoints (2026-04-20)
- [x] Base64-encoded request/response (2026-04-20)

## Code Quality Issues

### Swift Server

| Issue | Severity | Description |
|-------|----------|-------------|
| No tests | High | Missing unit tests for TranscribeService, OCRService |
| Embedded OpenAPI string | Low | OpenAPI spec should be loaded from file, not embedded |
| Thread-per-request | Medium | SpeechWorker spawns thread per request; consider thread pool |
| No rate limiting | Medium | Server vulnerable to abuse without rate limits |
| No request logging | Low | Missing request ID tracking for debugging |
| No input validation | Medium | Only base64 decoding validated; no file size limits |

### Rust CLI

| Issue | Severity | Description |
|-------|----------|-------------|
| No tests | High | Missing integration tests |
| Exit code on error | Low | Should return proper exit codes |

## Known Issues

- **Transcription authorization**: Speech recognition requires user permission via `System Settings > Privacy & Security > Speech Recognition`. The first call triggers a system dialog.
- **Audio format**: Speech.framework supports WAV, MP3, M4A, FLAC, AAC, AIFF. Other formats may fail.
- **OCR images**: Only JPEG, PNG, TIFF, BMP supported. PDFs must be pre-converted.
