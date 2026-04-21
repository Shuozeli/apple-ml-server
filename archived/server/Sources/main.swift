import Vapor
import Foundation

let VERSION = "1.0.0"

// Entry point
let app = try await Application.make(.detect())

// Configure
let host = Environment.get("HOST") ?? "0.0.0.0"
let port = Environment.get("PORT").flatMap(Int.init) ?? 8080
app.http.server.configuration.hostname = host
app.http.server.configuration.port = port
app.routes.defaultMaxBodySize = "50mb"

// CORS middleware
let corsConfig = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .OPTIONS],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
)
app.middleware.use(CORSMiddleware(configuration: corsConfig))

// ============== API Routes ==============

app.get("health") { req -> String in
    "OK"
}

app.get("version") { req -> [String: String] in
    ["version": VERSION, "name": "apple-ml-server"]
}

app.post("ocr") { req -> Response in
    let ocrRequest = try req.content.decode(OCRRequest.self)
    let result = try await OCRService.recognize(request: ocrRequest)
    return try await result.encodeResponse(for: req)
}

app.post("transcribe") { req -> Response in
    let transcribeRequest = try req.content.decode(TranscribeRequest.self)
    let result = try await TranscribeService.transcribe(request: transcribeRequest)
    return try await result.encodeResponse(for: req)
}

// ============== OpenAPI / Swagger ==============

let openAPISpec = """
openapi: 3.0.3
info:
  title: Apple ML Server API
  description: |
    On-device speech-to-text and OCR inference server using Apple's Vision and Speech frameworks.
    Runs locally on macOS with Apple Silicon acceleration.
  version: \(VERSION)
  contact:
    name: Apple ML Server

servers:
  - url: http://localhost:8080
    description: Local development server
  - url: http://{host}:{port}
    description: Custom server
    variables:
      host:
        default: localhost
        description: Server hostname or IP
      port:
        default: "8080"
        description: Server port

paths:
  /health:
    get:
      summary: Health check
      operationId: healthCheck
      tags: [System]
      responses:
        '200':
          description: Server is healthy
          content:
            text/plain:
              schema:
                type: string
                example: OK

  /version:
    get:
      summary: Get server version
      operationId: getVersion
      tags: [System]
      responses:
        '200':
          description: Version info
          content:
            application/json:
              schema:
                type: object
                properties:
                  version:
                    type: string
                  name:
                    type: string

  /ocr:
    post:
      summary: Perform OCR on an image
      operationId: ocr
      tags: [ML]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/OCRRequest'
      responses:
        '200':
          description: OCR completed successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/OCRResponse'
        '400':
          description: Invalid input
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Recognition failed
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

  /transcribe:
    post:
      summary: Transcribe audio to text
      operationId: transcribe
      tags: [ML]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/TranscribeRequest'
      responses:
        '200':
          description: Transcription completed successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TranscribeResponse'
        '400':
          description: Invalid input
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '403':
          description: Not authorized for speech recognition
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Recognition failed
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

components:
  schemas:
    OCRRequest:
      type: object
      required:
        - image
      properties:
        image:
          type: string
          format: byte
          description: Base64-encoded image data (JPEG, PNG, TIFF, BMP)
        language:
          type: string
          description: BCP-47 language code (e.g., "en-US", "zh-CN"). Omit for auto-detect.
          example: en-US

    OCRResponse:
      type: object
      properties:
        text:
          type: string
          description: Full extracted text
        blocks:
          type: array
          items:
            $ref: '#/components/schemas/TextBlock'
        confidence:
          type: number
          format: float
          description: Overall confidence score (0.0-1.0)
        processingTimeMs:
          type: integer
          format: int64
          description: Server-side processing time in milliseconds
        error:
          type: string
          nullable: true
          description: Error message if failed

    TextBlock:
      type: object
      properties:
        text:
          type: string
        confidence:
          type: number
          format: float
        boundingBox:
          $ref: '#/components/schemas/BoundingBox'

    BoundingBox:
      type: object
      properties:
        xMin:
          type: number
          format: float
          description: Normalized X minimum (0.0-1.0)
        yMin:
          type: number
          format: float
        xMax:
          type: number
          format: float
        yMax:
          type: number
          format: float

    TranscribeRequest:
      type: object
      required:
        - audio
      properties:
        audio:
          type: string
          format: byte
          description: Base64-encoded audio data
        format:
          type: string
          enum: [wav, mp3, m4a, flac]
          default: m4a
          description: Audio format
        language:
          type: string
          description: BCP-47 language code (e.g., "en-US", "zh-CN"). Omit for auto-detect.
          example: zh-CN
        timestamps:
          type: boolean
          default: false
          description: Include word-level timestamps
        timeout:
          type: integer
          default: 300
          description: Timeout in seconds

    TranscribeResponse:
      type: object
      properties:
        transcript:
          type: string
          description: Full transcribed text
        confidence:
          type: number
          format: float
          description: Overall confidence score (0.0-1.0)
        language:
          type: string
          description: Detected or specified language code
        words:
          type: array
          nullable: true
          items:
            $ref: '#/components/schemas/WordTiming'
          description: Word-level details (present if timestamps=true)
        processingTimeMs:
          type: integer
          format: int64
          description: Server-side processing time in milliseconds
        error:
          type: string
          nullable: true
          description: Error message if failed

    WordTiming:
      type: object
      properties:
        word:
          type: string
        confidence:
          type: number
          format: float
        startMs:
          type: integer
          format: int64
          description: Start time in milliseconds
        endMs:
          type: integer
          format: int64
          description: End time in milliseconds

    ErrorResponse:
      type: object
      properties:
        error:
          type: boolean
          example: true
        reason:
          type: string
          description: Error description
"""

// Serve OpenAPI spec
app.get("openapi.yaml") { req -> Response in
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/yaml")
    return Response(status: .ok, headers: headers, body: .init(string: openAPISpec))
}


print("Apple ML Server v\(VERSION)")
print("  API:     http://\(host):\(port)")
print("  OpenAPI: http://\(host):\(port)/openapi.yaml")
try await app.execute()
