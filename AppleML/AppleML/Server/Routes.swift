import Vapor
import Foundation

enum Routes {
    static func register(on app: Application, serverManager: ServerManager) {
        app.get("health") { req -> String in
            serverManager.incrementRequestCount()
            return "OK"
        }

        app.get("version") { req -> [String: String] in
            serverManager.incrementRequestCount()
            return ["version": AppConstants.version, "name": AppConstants.name]
        }

        app.post("transcribe") { req -> Response in
            serverManager.incrementRequestCount()
            let transcribeRequest = try req.content.decode(TranscribeRequest.self)
            let result = try await TranscribeService.shared.transcribe(request: transcribeRequest)

            // Save to history
            await HistoryStore.shared.add(
                type: .transcribe,
                inputFileName: nil,
                language: result.language,
                result: result.transcript,
                confidence: result.confidence,
                processingTimeMs: result.processingTimeMs
            )

            return try await result.encodeResponse(for: req)
        }

        app.post("ocr") { req -> Response in
            serverManager.incrementRequestCount()
            let ocrRequest = try req.content.decode(OCRRequest.self)
            let result = try await OCRService.shared.recognize(request: ocrRequest)

            // Save to history
            await HistoryStore.shared.add(
                type: .ocr,
                inputFileName: nil,
                language: ocrRequest.language ?? "auto",
                result: result.text,
                confidence: result.confidence,
                processingTimeMs: result.processingTimeMs
            )

            return try await result.encodeResponse(for: req)
        }

        // OpenAPI spec
        app.get("openapi.yaml") { req -> Response in
            serverManager.incrementRequestCount()
            var headers = HTTPHeaders()
            headers.add(name: .contentType, value: "text/yaml")
            return Response(status: .ok, headers: headers, body: .init(string: OpenAPISpec.yaml))
        }
    }
}
