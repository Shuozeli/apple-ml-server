# API Reference

<!-- agent-updated: 2026-04-20T15:30:00Z -->

Base URL: `http://localhost:8080`

All endpoints accept and return JSON. Audio and image data are base64-encoded in request/response bodies.

---

## System

### GET /health

Health check endpoint.

**Response:** `200 OK`
```
OK
```

---

### GET /version

Returns server version information.

**Response:** `200 OK`
```json
{
  "version": "1.0.0",
  "name": "apple-ml-server"
}
```

---

### GET /openapi.yaml

Returns the OpenAPI 3.0 specification as YAML.

**Response:** `200 OK`
```
openapi: 3.0.3
...
```

---

## ML Services

### POST /transcribe

Speech-to-text transcription using Apple's Speech.framework.

**Request:**
```json
{
  "audio": "<base64-encoded audio>",
  "format": "wav",
  "language": "en-US",
  "timestamps": true,
  "timeout": 300
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `audio` | `string` | Yes | Base64-encoded audio data |
| `format` | `string` | No | Audio format: `wav`, `mp3`, `m4a`, `flac`. Default: `m4a` |
| `language` | `string` | No | BCP-47 language code (e.g., `en-US`, `zh-CN`). Omit for auto-detect |
| `timestamps` | `boolean` | No | Include word-level timestamps. Default: `false` |
| `timeout` | `integer` | No | Timeout in seconds. Default: `300` |

**Response:** `200 OK`
```json
{
  "transcript": "Hello world",
  "confidence": 0.95,
  "language": "en-US",
  "words": [
    {
      "word": "Hello",
      "confidence": 0.98,
      "startMs": 0,
      "endMs": 500
    }
  ],
  "processingTimeMs": 1234,
  "error": null
}
```

| Field | Type | Description |
|-------|------|-------------|
| `transcript` | `string` | Full transcribed text |
| `confidence` | `float` | Overall confidence score (0.0-1.0) |
| `language` | `string` | Detected or specified language code |
| `words` | `array` | Word-level details (if `timestamps=true`) |
| `processingTimeMs` | `int64` | Server-side processing time in milliseconds |
| `error` | `string` | Error message if failed, `null` on success |

**Error Responses:**

| Status | Error | Description |
|--------|-------|-------------|
| `400` | `Invalid input` | Malformed base64 or unsupported audio format |
| `403` | `Speech recognition not authorized` | User has not granted permission |
| `500` | `Recognition failed` | Speech.framework processing error |

---

### POST /ocr

Optical character recognition using Apple's Vision.framework.

**Request:**
```json
{
  "image": "<base64-encoded image>",
  "language": "en-US"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `image` | `string` | Yes | Base64-encoded image (JPEG, PNG, TIFF, BMP) |
| `language` | `string` | No | BCP-47 language code. Omit for auto-detect |

**Response:** `200 OK`
```json
{
  "text": "Hello world\nThis is OCR",
  "blocks": [
    {
      "text": "Hello world",
      "confidence": 0.95,
      "boundingBox": {
        "xMin": 0.1,
        "yMin": 0.2,
        "xMax": 0.9,
        "yMax": 0.3
      }
    }
  ],
  "confidence": 0.92,
  "processingTimeMs": 567,
  "error": null
}
```

| Field | Type | Description |
|-------|------|-------------|
| `text` | `string` | Full extracted text (blocks joined by newlines) |
| `blocks` | `array` | Structured text blocks with bounding boxes |
| `confidence` | `float` | Overall confidence score (0.0-1.0) |
| `processingTimeMs` | `int64` | Server-side processing time in milliseconds |
| `error` | `string` | Error message if failed, `null` on success |

**TextBlock:**
| Field | Type | Description |
|-------|------|-------------|
| `text` | `string` | Text content of this block |
| `confidence` | `float` | Confidence score (0.0-1.0) |
| `boundingBox` | `object` | Normalized bounding box (0.0-1.0, top-left origin) |

**BoundingBox:**
| Field | Type | Description |
|-------|------|-------------|
| `xMin` | `float` | Left edge |
| `yMin` | `float` | Top edge |
| `xMax` | `float` | Right edge |
| `yMax` | `float` | Bottom edge |

**Error Responses:**

| Status | Error | Description |
|--------|-------|-------------|
| `400` | `Invalid input` | Malformed base64 or unsupported image format |
| `500` | `Recognition failed` | Vision.framework processing error |

**Note:** PDFs are not supported. Pre-convert using `scripts/pdf_to_images.py`.

---

## Error Response Format

Errors return HTTP status codes with JSON body:

```json
{
  "error": true,
  "reason": "Invalid input: Could not decode image"
}
```

| HTTP Status | Reason | Description |
|-------------|--------|-------------|
| `400` | `Invalid input` | Malformed request (bad base64, wrong format) |
| `400` | `Language not supported` | Language code not available |
| `403` | `Speech recognition not authorized` | TCC permission not granted |
| `500` | `Recognition failed` | ML framework error |

---

## Example Calls

### Transcribe (cURL)

```bash
curl -X POST http://localhost:8080/transcribe \
  -H "Content-Type: application/json" \
  -d '{
    "audio": "'$(base64 -i audio.wav)'",
    "format": "wav",
    "language": "en-US",
    "timestamps": true
  }'
```

### Transcribe (Rust CLI)

```bash
apple-ml transcribe audio.wav --format wav --language en-US --timestamps
```

### OCR (cURL)

```bash
curl -X POST http://localhost:8080/ocr \
  -H "Content-Type: application/json" \
  -d '{
    "image": "'$(base64 -i image.png)'",
    "language": "en-US"
  }'
```

### OCR (Rust CLI)

```bash
apple-ml ocr image.png --language en-US
```

### PDF Workflow

```bash
# 1. Convert PDF to images
python3 scripts/pdf_to_images.py book.pdf /tmp/book_pages

# 2. OCR each image
for page in /tmp/book_pages/book_page*.png; do
    apple-ml ocr "$page"
done
```
