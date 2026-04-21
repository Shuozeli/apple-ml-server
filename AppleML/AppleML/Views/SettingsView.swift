import SwiftUI

struct SettingsView: View {
    @AppStorage("serverPort") private var port: Int = 8080
    @AppStorage("bindAddress") private var bindAddress: String = "0.0.0.0"
    @AppStorage("defaultLanguage") private var defaultLanguage: String = ""

    var body: some View {
        Form {
            Section("Server") {
                HStack {
                    Text("Port:")
                    TextField("8080", value: $port, format: .number)
                        .frame(width: 80)
                }
                HStack {
                    Text("Bind Address:")
                    TextField("0.0.0.0", text: $bindAddress)
                        .frame(width: 150)
                }
                Text("Restart the server for changes to take effect.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Transcription") {
                HStack {
                    Text("Default Language:")
                    TextField("Auto-detect", text: $defaultLanguage)
                        .frame(width: 100)
                }
                Text("BCP-47 code (e.g., en-US, zh-CN). Leave empty for auto-detection.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 250)
        .padding()
    }
}
