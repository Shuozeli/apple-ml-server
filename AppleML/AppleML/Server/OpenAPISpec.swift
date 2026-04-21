import Foundation

enum OpenAPISpec {
    static let yaml = """
openapi: 3.0.3
info:
  title: AppleML API
  description: |
    On-device speech-to-text and OCR server using Apple's Vision and Speech frameworks.
    Runs locally on macOS with Apple Silicon acceleration.
  version: \(AppConstants.version)

servers:
  - url: http://localhost:8080
    description: Local server

paths:
  /health:
    get:
      summary: Health check
      tags: [System]
      responses:
        '200':
          description: Server is healthy
          content:
            text/plain:
              schema:
                type: string

  /version:
    get:
      summary: Get server version
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

  /transcribe:
    post:
      summary: Transcribe audio to text
      tags: [ML]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [audio]
              properties:
                audio:
                  type: string
                  format: byte
                format:
                  type: string
                  enum: [wav, mp3, m4a, flac]
                  default: m4a
                language:
                  type: string
                timestamps:
                  type: boolean
                  default: false
                timeout:
                  type: integer
                  default: 300
      responses:
        '200':
          description: Transcription result
        '400':
          description: Invalid input
        '403':
          description: Not authorized
        '500':
          description: Recognition failed

  /ocr:
    post:
      summary: Perform OCR on an image
      tags: [ML]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [image]
              properties:
                image:
                  type: string
                  format: byte
                language:
                  type: string
      responses:
        '200':
          description: OCR result
        '400':
          description: Invalid input
        '500':
          description: Recognition failed
"""
}
