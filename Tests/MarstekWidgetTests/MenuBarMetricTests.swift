import Testing
@testable import MarstekWidget

@Test func linesSkipNoneAndMissingValues() {
    var s = CombinedStatus()
    s.esStatus = ESStatus(id: 0, batSoc: 80, batCap: nil, pvPower: nil, ongridPower: -1250, offgridPower: 351,
                          totalPvEnergy: nil, totalGridOutputEnergy: nil, totalGridInputEnergy: nil, totalLoadEnergy: nil)
    #expect(menuBarLines(s, [.soc, .load]) == ["80%", "351 W"])
    #expect(menuBarLines(s, [.grid, .none]) == ["-1.2 kW"])
    #expect(menuBarLines(s, [.pv, .soc]) == ["80%"])
    #expect(menuBarLines(CombinedStatus(), [.soc, .load]) == [])
}

@Test func boltOnlyWhenChargingWithoutDischarging() {
    func status(charging: Bool, discharging: Bool) -> CombinedStatus {
        var s = CombinedStatus()
        s.batStatus = BatStatus(id: 0, soc: 78, chargFlag: charging, dischrgFlag: discharging,
                                batTemp: nil, batCapacity: nil, ratedCapacity: nil)
        return s
    }
    #expect(status(charging: true, discharging: false).showsChargingBolt)
    #expect(!status(charging: true, discharging: true).showsChargingBolt)
    #expect(!status(charging: false, discharging: true).showsChargingBolt)
    #expect(!CombinedStatus().showsChargingBolt)
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
