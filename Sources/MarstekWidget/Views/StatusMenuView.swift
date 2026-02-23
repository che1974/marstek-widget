import SwiftUI

struct StatusMenuView: View {
    @Environment(DeviceMonitor.self) private var monitor

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            batteryHeader

            Divider()

            if monitor.status.esStatus != nil || monitor.status.batStatus != nil {
                statusRows
            } else if case .error(let msg) = monitor.connectionState {
                Label(msg, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            } else if monitor.deviceIP.isEmpty {
                Text("Set device IP in Settings")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                Text("Waiting for data...")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Divider()

            if let pv = monitor.status.pvPower {
                StatusRow(icon: "sun.max", label: "PV Power", value: formatPower(pv))
            }

            if let em = monitor.status.emStatus, let total = em.totalPower {
                StatusRow(icon: "bolt.fill", label: "Grid Meter", value: formatPower(total))
            }

            if let es = monitor.status.esStatus {
                Divider()
                energyRows(es)
            }

            // Mode switcher
            if monitor.status.esMode != nil {
                Divider()
                modePicker
            }

            Divider()

            if let date = monitor.status.lastUpdated {
                StatusRow(icon: "clock", label: "Last updated", value: date.formatted(.dateTime.hour().minute().second()))
            }

            HStack {
                Circle()
                    .fill(connectionColor)
                    .frame(width: 6, height: 6)
                Text(monitor.connectionState.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)

            Divider()

            Button("Settings...") {
                SettingsWindowManager.shared.open(monitor: monitor)
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Refresh Now") {
                monitor.poll()
            }
            .keyboardShortcut("r", modifiers: .command)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(8)
        .frame(width: 260)
    }

    private var batteryHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: batteryIcon)
                .font(.title2)
                .foregroundStyle(batteryColor)

            VStack(alignment: .leading, spacing: 2) {
                if let soc = monitor.status.soc {
                    Text("\(soc)%")
                        .font(.title2.bold())
                } else {
                    Text("--%")
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Text(monitor.status.batteryStateText)
                    if let mode = monitor.status.esMode?.mode {
                        Text("·")
                        Text(mode)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var statusRows: some View {
        let s = monitor.status

        if let grid = s.gridPower {
            let direction = grid > 0 ? "importing" : grid < 0 ? "exporting" : ""
            StatusRow(icon: "powerplug", label: "Grid Power",
                      value: formatPower(abs(grid)) + (direction.isEmpty ? "" : " (\(direction))"))
        }

        if let offgrid = s.offgridPower {
            StatusRow(icon: "house", label: "Load Power", value: formatPower(offgrid))
        }

        if let temp = s.batteryTemp {
            StatusRow(icon: "thermometer.medium", label: "Temperature", value: String(format: "%.1f°C", temp))
        }

        if let bat = s.batStatus, let cap = bat.batCapacity, let rated = bat.ratedCapacity {
            StatusRow(icon: "battery.100", label: "Capacity",
                      value: String(format: "%.0f / %.0f Wh", cap, rated))
        }
    }

    private var modePicker: some View {
        let current = monitor.status.esMode?.mode ?? ""
        let modes = [("Auto", "Auto"), ("Manual", "UPS")]
        return HStack {
            Image(systemName: "gearshape.2")
                .frame(width: 16)
                .foregroundStyle(.secondary)
            Text("Mode")
                .foregroundStyle(.secondary)
            Spacer()
            ForEach(modes, id: \.0) { (apiName, label) in
                Button(label) {
                    monitor.setMode(apiName)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(current == apiName ? .accentColor : nil)
                .disabled(current == apiName)
            }
        }
        .font(.callout)
        .padding(.vertical, 1)
    }

    private var batteryIcon: String {
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

    private var batteryColor: Color {
        guard let soc = monitor.status.soc else { return .secondary }
        if soc <= 10 { return .red }
        if soc <= 25 { return .orange }
        return .green
    }

    private var connectionColor: Color {
        switch monitor.connectionState {
        case .connected: return .green
        case .connecting: return .yellow
        case .error: return .red
        case .disconnected: return .gray
        }
    }

    @ViewBuilder
    private func energyRows(_ es: ESStatus) -> some View {
        if let gridIn = es.totalGridInputEnergy {
            StatusRow(icon: "arrow.down.circle", label: "Grid Import", value: formatEnergy(gridIn))
        }
        if let gridOut = es.totalGridOutputEnergy {
            StatusRow(icon: "arrow.up.circle", label: "Grid Export", value: formatEnergy(gridOut))
        }
        if let pv = es.totalPvEnergy {
            StatusRow(icon: "sun.max.fill", label: "PV Total", value: formatEnergy(pv))
        }
    }

    private func formatEnergy(_ wh: Int) -> String {
        if wh >= 1000 {
            return String(format: "%.1f kWh", Double(wh) / 1000)
        }
        return "\(wh) Wh"
    }

    private func formatPower(_ watts: Int) -> String {
        if abs(watts) >= 1000 {
            return String(format: "%.1f kW", Double(watts) / 1000)
        }
        return "\(watts) W"
    }
}

struct StatusRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 16)
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.callout)
        .padding(.vertical, 1)
    }
}
