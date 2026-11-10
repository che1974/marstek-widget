import Foundation

enum MenuBarMetric: String, CaseIterable, Identifiable {
    case none, batteryIcon, soc, load, grid, pv

    var id: String { rawValue }

    // The glyph only fits the single-line leading slot.
    static let lineChoices = allCases.filter { $0 != .batteryIcon }

    var title: String {
        switch self {
        case .none: return "Nothing"
        case .batteryIcon: return "Battery Icon"
        case .soc: return "Battery %"
        case .load: return "Load Power"
        case .grid: return "Grid Power"
        case .pv: return "PV Power"
        }
    }

    func text(for status: CombinedStatus) -> String? {
        switch self {
        case .none, .batteryIcon: return nil
        case .soc: return status.soc.map { "\($0)%" }
        case .load: return status.offgridPower.map { formatFlow($0, positive: "↑", negative: "↓") }
        // Positive grid power is import, into the station.
        case .grid: return status.gridPower.map { formatFlow($0, positive: "↓", negative: "↑") }
        case .pv: return status.pvPower.map(formatPower)
        }
    }
}

func menuBarLines(_ status: CombinedStatus, _ metrics: [MenuBarMetric]) -> [String] {
    metrics.compactMap { $0.text(for: status) }
}

func showsBatteryGlyph(leading: MenuBarMetric, leadingText: String?, lines: [String]) -> Bool {
    leading == .batteryIcon || (leadingText == nil && lines.isEmpty)
}

func formatFlow(_ watts: Int, positive: String, negative: String) -> String {
    watts == 0 ? formatPower(0) : "\(formatPower(abs(watts))) \(watts > 0 ? positive : negative)"
}

func formatPower(_ watts: Int) -> String {
    if abs(watts) >= 1000 {
        return String(format: "%.1f kW", Double(watts) / 1000)
    }
    return "\(watts) W"
}
