import AppKit
import SwiftUI

private class SettingsWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    var onClose: (() -> Void)?

    override func close() {
        super.close()
        onClose?()
    }
}

@MainActor
final class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    private var window: SettingsWindow?

    func open(monitor: DeviceMonitor) {
        if let window, window.isVisible {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let settingsView = SettingsView(monitor: monitor)
        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 350, height: 280)

        let window = SettingsWindow(
            contentRect: hostingView.frame,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Marstek Settings"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false

        // Position near menu bar, top-right
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - hostingView.frame.width - 20
            let y = screenFrame.maxY - hostingView.frame.height
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.onClose = {
            // Return to accessory mode (no dock icon) when settings closed
            NSApp.setActivationPolicy(.accessory)
        }

        self.window = window

        // Become regular app so window gets full keyboard/mouse focus
        NSApp.setActivationPolicy(.regular)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }
}
