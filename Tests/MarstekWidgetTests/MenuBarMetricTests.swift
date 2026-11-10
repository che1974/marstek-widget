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
