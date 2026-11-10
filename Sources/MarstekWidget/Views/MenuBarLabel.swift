import SwiftUI

struct MenuBarLabel: View {
    @Environment(DeviceMonitor.self) private var monitor
    @AppStorage("menuBarTopLine") private var topLine = MenuBarMetric.soc
    @AppStorage("menuBarBottomLine") private var bottomLine = MenuBarMetric.none
    @AppStorage("menuBarShowIcon") private var showIcon = true

    var body: some View {
        Image(nsImage: render())
            .onAppear {
                monitor.start()
                StatusItemContextMenu.install(monitor: monitor)
            }
    }

    // MenuBarExtra labels ignore stacks and custom shapes, so the whole label is drawn into a template image.
    @MainActor
    private func render() -> NSImage {
        let lines = menuBarLines(monitor.status, [topLine, bottomLine])
        let renderer = ImageRenderer(content:
            HStack(spacing: 4) {
                if showIcon || lines.isEmpty {
                    BatteryGlyph(soc: monitor.status.soc, isCharging: monitor.status.isCharging)
                }
                VStack(alignment: .trailing, spacing: -2) {
                    ForEach(lines.indices, id: \.self) { Text(lines[$0]) }
                }
                .font(.system(size: lines.count == 2 ? 10 : 13, weight: .medium).monospacedDigit())
            }
            .frame(height: 22)
        )
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = true
        return image
    }
}

// Same look as the macOS battery: filled level, percentage cut out of the fill.
struct BatteryGlyph: View {
    let soc: Int?
    let isCharging: Bool

    var body: some View {
        HStack(spacing: 1) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3.5).opacity(0.35)
                RoundedRectangle(cornerRadius: 3.5)
                    .frame(width: 23 * Double(min(max(soc ?? 0, 0), 100)) / 100)
                HStack(spacing: 0) {
                    if let soc { Text("\(soc)") }
                    if isCharging { Image(systemName: "bolt.fill").font(.system(size: 7, weight: .bold)) }
                }
                .font(.system(size: 9, weight: .bold).monospacedDigit())
                .frame(maxWidth: .infinity)
                .blendMode(.destinationOut)
            }
            .compositingGroup()
            .frame(width: 23, height: 11)
            RoundedRectangle(cornerRadius: 1)
                .frame(width: 1.5, height: 3.5)
                .opacity(0.35)
        }
    }
}
