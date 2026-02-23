import Foundation

// MARK: - ES Status (Energy Storage)
// Response from ES.GetStatus

struct ESStatus: Decodable {
    let id: Int?
    let batSoc: Int?
    let batCap: Int?
    let pvPower: Int?
    let ongridPower: Int?
    let offgridPower: Int?
    let totalPvEnergy: Int?
    let totalGridOutputEnergy: Int?
    let totalGridInputEnergy: Int?
    let totalLoadEnergy: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case batSoc = "bat_soc"
        case batCap = "bat_cap"
        case pvPower = "pv_power"
        case ongridPower = "ongrid_power"
        case offgridPower = "offgrid_power"
        case totalPvEnergy = "total_pv_energy"
        case totalGridOutputEnergy = "total_grid_output_energy"
        case totalGridInputEnergy = "total_grid_input_energy"
        case totalLoadEnergy = "total_load_energy"
    }
}

// MARK: - Battery Status
// Response from Bat.GetStatus

struct BatStatus: Decodable {
    let id: Int?
    let soc: Int?
    let chargFlag: Bool?
    let dischrgFlag: Bool?
    let batTemp: Double?
    let batCapacity: Double?
    let ratedCapacity: Double?

    enum CodingKeys: String, CodingKey {
        case id, soc
        case chargFlag = "charg_flag"
        case dischrgFlag = "dischrg_flag"
        case batTemp = "bat_temp"
        case batCapacity = "bat_capacity"
        case ratedCapacity = "rated_capacity"
    }
}

// MARK: - Energy Meter Status
// Response from EM.GetStatus

struct EMStatus: Decodable {
    let id: Int?
    let ctState: Int?
    let aPower: Int?
    let bPower: Int?
    let cPower: Int?
    let totalPower: Int?
    let inputEnergy: Int?
    let outputEnergy: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case ctState = "ct_state"
        case aPower = "a_power"
        case bPower = "b_power"
        case cPower = "c_power"
        case totalPower = "total_power"
        case inputEnergy = "input_energy"
        case outputEnergy = "output_energy"
    }
}

// MARK: - ES Mode
// Response from ES.GetMode

struct ESMode: Decodable {
    let id: Int?
    let mode: String?
    let ongridPower: Int?
    let offgridPower: Int?
    let batSoc: Int?

    enum CodingKeys: String, CodingKey {
        case id, mode
        case ongridPower = "ongrid_power"
        case offgridPower = "offgrid_power"
        case batSoc = "bat_soc"
    }
}

// MARK: - Combined Status

struct CombinedStatus {
    var esStatus: ESStatus?
    var batStatus: BatStatus?
    var emStatus: EMStatus?
    var esMode: ESMode?
    var lastUpdated: Date?

    var soc: Int? {
        esStatus?.batSoc ?? batStatus?.soc
    }

    var batteryCapacity: Int? {
        esStatus?.batCap
    }

    var pvPower: Int? {
        esStatus?.pvPower
    }

    var gridPower: Int? {
        esStatus?.ongridPower
    }

    var offgridPower: Int? {
        esStatus?.offgridPower
    }

    var batteryTemp: Double? {
        batStatus?.batTemp
    }

    var isCharging: Bool {
        batStatus?.chargFlag ?? false
    }

    var isDischarging: Bool {
        batStatus?.dischrgFlag ?? false
    }

    var batteryStateText: String {
        if isCharging && isDischarging { return "Standby" }
        if isCharging { return "Charging" }
        if isDischarging { return "Discharging" }
        return "Idle"
    }
}
