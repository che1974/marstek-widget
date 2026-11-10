import Foundation

enum MenuBarMetric: String, CaseIterable, Identifiable {
    case none, soc, load, grid, pv

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "Nothing"
        case .soc: return "Battery %"
        case .load: return "Load Power"
        case .grid: return "Grid Power"
        case .pv: return "PV Power"
        }
    }

    func text(for status: CombinedStatus) -> String? {
        switch self {
        case .none: return nil
        case .soc: return status.soc.map { "\($0)%" }
        case .load: return status.offgridPower.map(formatPower)
        case .grid: return status.gridPower.map(formatPower)
        case .pv: return status.pvPower.map(formatPower)
        }
    }
}

func menuBarLines(_ status: CombinedStatus, _ metrics: [MenuBarMetric]) -> [String] {
    metrics.compactMap { $0.text(for: status) }
}

func formatPower(_ watts: Int) -> String {
    if abs(watts) >= 1000 {
        return String(format: "%.1f kW", Double(watts) / 1000)
    }
    return "\(watts) W"
}
