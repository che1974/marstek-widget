import SwiftUI

@main
struct MarstekWidgetApp: App {
    @State private var monitor = DeviceMonitor()

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView()
                .environment(monitor)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: menuBarIcon)
            if let soc = monitor.status.soc {
                Text("\(soc)%")
            }
        }
        .onAppear {
            monitor.start()
        }
    }

    private var menuBarIcon: String {
        guard let soc = monitor.status.soc else { return "battery.0" }
        if monitor.status.isCharging { return "battery.100.bolt" }
        switch soc {
        case 75...100: return "battery.100"
        case 50..<75: return "battery.75"
        case 25..<50: return "battery.50"
        case 10..<25: return "battery.25"
        default: return "battery.0"
        }
    }
}
