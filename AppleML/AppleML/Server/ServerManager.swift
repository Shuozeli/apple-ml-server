import Foundation
import Vapor
import Observation

@Observable
final class ServerManager: @unchecked Sendable {
    static let shared = ServerManager()

    private(set) var isRunning = false
    private(set) var requestCount = 0
    var port: Int = 8080
    var bindAddress: String = "0.0.0.0"

    private var app: Application?

    private init() {
        // Read from environment if available (for --serve mode)
        if let envPort = ProcessInfo.processInfo.environment["PORT"], let p = Int(envPort) {
            port = p
        }
        if let envHost = ProcessInfo.processInfo.environment["HOST"] {
            bindAddress = envHost
        }
    }

    func start() {
        guard !isRunning else { return }
        Task.detached { [self] in
            do {
                let app = try await Application.make(.detect())
                app.http.server.configuration.hostname = self.bindAddress
                app.http.server.configuration.port = self.port
                app.routes.defaultMaxBodySize = "50mb"

                // CORS
                let corsConfig = CORSMiddleware.Configuration(
                    allowedOrigin: .all,
                    allowedMethods: [.GET, .POST, .OPTIONS],
                    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
                )
                app.middleware.use(CORSMiddleware(configuration: corsConfig))

                // Register routes
                Routes.register(on: app, serverManager: self)

                self.app = app
                await MainActor.run { self.isRunning = true }

                print("AppleML Server v\(AppConstants.version)")
                print("  API:     http://\(self.bindAddress):\(self.port)")
                print("  OpenAPI: http://\(self.bindAddress):\(self.port)/openapi.yaml")

                try await app.execute()
            } catch {
                print("Server error: \(error)")
                await MainActor.run { self.isRunning = false }
            }
        }
    }

    func stop() {
        app?.shutdown()
        app = nil
        isRunning = false
    }

    func incrementRequestCount() {
        requestCount += 1
    }
}

enum AppConstants {
    static let version = "2.0.0"
    static let name = "AppleML"
}
