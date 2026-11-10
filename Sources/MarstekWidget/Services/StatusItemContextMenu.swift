import AppKit

// MenuBarExtra has no right-click hook, so catch right clicks on our status bar window.
@MainActor
final class StatusItemContextMenu: NSObject {
    private static var shared: StatusItemContextMenu?
    private let monitor: DeviceMonitor
    private let menu = NSMenu()

    static func install(monitor: DeviceMonitor) {
        guard shared == nil else { return }
        let instance = StatusItemContextMenu(monitor: monitor)
        shared = instance
        NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
            guard let view = event.window?.contentView,
                  event.window?.className.contains("StatusBar") == true else { return event }
            instance.menu.popUp(positioning: nil, at: NSPoint(x: 0, y: -4), in: view)
            return nil
        }
    }

    private init(monitor: DeviceMonitor) {
        self.monitor = monitor
        super.init()
        add("Refresh Now", #selector(refresh))
        add("Settings...", #selector(openSettings))
        menu.addItem(.separator())
        add("Quit", #selector(quit))
    }

    private func add(_ title: String, _ action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    @objc private func refresh() { monitor.poll(full: true) }
    @objc private func openSettings() { SettingsWindowManager.shared.open(monitor: monitor) }
    @objc private func quit() { NSApp.terminate(nil) }
}
