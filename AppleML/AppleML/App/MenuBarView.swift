import SwiftUI

struct MenuBarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(ServerManager.shared.isRunning ? .green : .red)
                    .frame(width: 8, height: 8)
                Text(ServerManager.shared.isRunning ? "Server Running" : "Server Stopped")
            }

            if ServerManager.shared.isRunning {
                Text("Port: \(ServerManager.shared.port)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Requests: \(ServerManager.shared.requestCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Open AppleML") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.title == "AppleML" }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .keyboardShortcut("o")

            Divider()

            if ServerManager.shared.isRunning {
                Button("Stop Server") {
                    ServerManager.shared.stop()
                }
            } else {
                Button("Start Server") {
                    ServerManager.shared.start()
                }
            }

            Divider()

            Button("Quit") {
                ServerManager.shared.stop()
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(4)
    }
}
