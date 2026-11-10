import Testing
@testable import MarstekWidget

@Test func linesSkipNoneAndMissingValues() {
    var s = CombinedStatus()
    s.esStatus = ESStatus(id: 0, batSoc: 80, batCap: nil, pvPower: nil, ongridPower: -1250, offgridPower: 351,
                          totalPvEnergy: nil, totalGridOutputEnergy: nil, totalGridInputEnergy: nil, totalLoadEnergy: nil)
    #expect(menuBarLines(s, [.soc, .load]) == ["80%", "351 W ↑"])
    #expect(menuBarLines(s, [.grid, .none]) == ["1.2 kW ↓"])
    #expect(menuBarLines(s, [.pv, .soc]) == ["80%"])
    #expect(menuBarLines(CombinedStatus(), [.soc, .load]) == [])
}

// Arrows read like a network meter from the station's side: ↓ in from grid, ↑ out to grid or house.
@Test func gridAndLoadShowFlowArrows() {
    func status(grid: Int, load: Int) -> CombinedStatus {
        var s = CombinedStatus()
        s.esStatus = ESStatus(id: 0, batSoc: nil, batCap: nil, pvPower: nil, ongridPower: grid, offgridPower: load,
                              totalPvEnergy: nil, totalGridOutputEnergy: nil, totalGridInputEnergy: nil, totalLoadEnergy: nil)
        return s
    }
    #expect(menuBarLines(status(grid: 350, load: 0), [.grid, .load]) == ["350 W ↑", "0 W"])
    #expect(menuBarLines(status(grid: 0, load: 1500), [.grid, .load]) == ["0 W", "1.5 kW ↑"])
}

@Test func chargingIconWhenFlagsSayChargingOrGridFlowsIn() {
    func status(charging: Bool, discharging: Bool, grid: Int? = nil) -> CombinedStatus {
        var s = CombinedStatus()
        s.batStatus = BatStatus(id: 0, soc: 78, chargFlag: charging, dischrgFlag: discharging,
                                batTemp: nil, batCapacity: nil, ratedCapacity: nil)
        s.esStatus = ESStatus(id: 0, batSoc: nil, batCap: nil, pvPower: nil, ongridPower: grid, offgridPower: nil,
                              totalPvEnergy: nil, totalGridOutputEnergy: nil, totalGridInputEnergy: nil, totalLoadEnergy: nil)
        return s
    }
    #expect(status(charging: true, discharging: false).showsChargingIcon)
    #expect(!status(charging: true, discharging: true).showsChargingIcon)
    #expect(!status(charging: false, discharging: true).showsChargingIcon)
    #expect(!CombinedStatus().showsChargingIcon)
    // UPS mode sets both flags even while charging, so grid flowing in decides.
    #expect(status(charging: true, discharging: true, grid: -995).showsChargingIcon)
    #expect(!status(charging: true, discharging: true, grid: -10).showsChargingIcon)
    #expect(!status(charging: true, discharging: true, grid: 500).showsChargingIcon)
}

@Test func manualModeIsShownAsUPS() {
    var s = CombinedStatus()
    #expect(s.modeLabel == nil)
    s.esMode = ESMode(id: 0, mode: "Manual", ongridPower: nil, offgridPower: nil, batSoc: nil)
    #expect(s.modeLabel == "UPS")
    s.esMode = ESMode(id: 0, mode: "Auto", ongridPower: nil, offgridPower: nil, batSoc: nil)
    #expect(s.modeLabel == "Auto")
}

@Test func batteryIconOnlyInLeadingSlot() {
    #expect(!MenuBarMetric.lineChoices.contains(.batteryIcon))
    #expect(MenuBarMetric.allCases.contains(.batteryIcon))
    var s = CombinedStatus()
    s.esStatus = ESStatus(id: 0, batSoc: 80, batCap: nil, pvPower: nil, ongridPower: nil, offgridPower: nil,
                          totalPvEnergy: nil, totalGridOutputEnergy: nil, totalGridInputEnergy: nil, totalLoadEnergy: nil)
    #expect(MenuBarMetric.batteryIcon.text(for: s) == nil)
}

@Test func batteryGlyphShownWhenPickedOrWhenBarWouldBeEmpty() {
    #expect(showsBatteryGlyph(leading: .batteryIcon, leadingText: nil, lines: ["80%"]))
    #expect(showsBatteryGlyph(leading: .none, leadingText: nil, lines: []))
    #expect(!showsBatteryGlyph(leading: .none, leadingText: nil, lines: ["80%"]))
    #expect(!showsBatteryGlyph(leading: .load, leadingText: "351 W", lines: []))
    // No data yet: never leave the status item blank and unclickable.
    #expect(showsBatteryGlyph(leading: .load, leadingText: nil, lines: []))
}

@Test func gridPresenceIgnoresSensorNoise() {
    func status(grid: Int?) -> CombinedStatus {
        var s = CombinedStatus()
        s.esStatus = ESStatus(id: 0, batSoc: nil, batCap: nil, pvPower: nil, ongridPower: grid, offgridPower: nil,
                              totalPvEnergy: nil, totalGridOutputEnergy: nil, totalGridInputEnergy: nil, totalLoadEnergy: nil)
        return s
    }
    #expect(status(grid: nil).hasGridPower == nil)
    #expect(status(grid: 0).hasGridPower == false)
    #expect(status(grid: 15).hasGridPower == false)
    #expect(status(grid: -15).hasGridPower == false)
    #expect(status(grid: 350).hasGridPower == true)
    #expect(status(grid: -1250).hasGridPower == true)
}

@Test func gridCameBackOnlyOnOffToOn() {
    #expect(gridCameBack(was: false, now: true))
    #expect(!gridCameBack(was: nil, now: true))
    #expect(!gridCameBack(was: true, now: true))
    #expect(!gridCameBack(was: true, now: false))
    #expect(!gridCameBack(was: false, now: false))
    #expect(!gridCameBack(was: false, now: nil))
}
