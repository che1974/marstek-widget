import SwiftUI

@main
struct MarstekWidgetApp: App {
    @State private var monitor = DeviceMonitor()

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView()
                .environment(monitor)
        } label: {
            MenuBarLabel()
                .environment(monitor)
        }
        .menuBarExtraStyle(.window)
    }
}
