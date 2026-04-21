import SwiftUI
import SwiftData
@preconcurrency import Speech

@main
struct AppleMLApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    let container: ModelContainer

    init() {
        // Setup SwiftData
        let schema = Schema([HistoryItem.self])
        let config = ModelConfiguration(schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Initialize history store with container
        let c = container
        Task {
            await HistoryStore.shared.setup(container: c)
        }

        // Start server
        ServerManager.shared.start()
    }

    var body: some Scene {
        WindowGroup("AppleML", id: "main") {
            MainView()
                .modelContainer(container)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .defaultSize(width: 700, height: 500)

        MenuBarExtra("AppleML", systemImage: "waveform.circle.fill") {
            MenuBarView()
        }

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request speech recognition permission upfront
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                print("Speech recognition authorized")
            case .denied, .restricted:
                print("Speech recognition denied")
            case .notDetermined:
                print("Speech recognition not determined")
            @unknown default:
                break
            }
        }

        if !CommandLine.arguments.contains("--serve") {
            // In GUI mode, ensure the main window is shown
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.activate(ignoringOtherApps: true)
                // Open a new window if none exist
                if NSApp.windows.filter({ $0.isVisible }).isEmpty {
                    NSApp.sendAction(Selector(("newWindowForTab:")), to: nil, from: nil)
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Re-open window when clicking dock icon
            NSApp.sendAction(Selector(("newWindowForTab:")), to: nil, from: nil)
        }
        return true
    }
}
