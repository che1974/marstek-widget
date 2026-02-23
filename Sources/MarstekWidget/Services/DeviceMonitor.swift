import Foundation
import SwiftUI

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)

    var label: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

@Observable
final class DeviceMonitor {
    var status = CombinedStatus()
    var connectionState: ConnectionState = .disconnected

    private var timer: Timer?
    private var client: MarstekAPIClient?

    var deviceIP: String {
        get { UserDefaults.standard.string(forKey: "deviceIP") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "deviceIP") }
    }

    var pollingInterval: TimeInterval {
        get { UserDefaults.standard.double(forKey: "pollingInterval").clamped(to: 10...600, default: 60) }
        set {
            UserDefaults.standard.set(newValue, forKey: "pollingInterval")
            restartPolling()
        }
    }

    var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: "launchAtLogin") }
        set { UserDefaults.standard.set(newValue, forKey: "launchAtLogin") }
    }

    func start() {
        guard !deviceIP.isEmpty else { return }
        client = MarstekAPIClient(host: deviceIP)
        restartPolling()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        connectionState = .disconnected
    }

    func restartPolling() {
        timer?.invalidate()
        guard !deviceIP.isEmpty else { return }
        client = MarstekAPIClient(host: deviceIP)

        poll()

        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func poll() {
        guard let client else { return }
        connectionState = .connecting

        Task {
            do {
                let esResult = try await client.getESStatus()
                let batResult = try await client.getBatStatus()
                let emResult = try await client.getEMStatus()
                let modeResult = try await client.getESMode()

                await MainActor.run {
                    self.status.esStatus = esResult
                    self.status.batStatus = batResult
                    self.status.emStatus = emResult
                    self.status.esMode = modeResult
                    self.status.lastUpdated = Date()
                    self.connectionState = .connected
                }
            } catch {
                await MainActor.run {
                    self.connectionState = .error(error.localizedDescription)
                }
            }
        }
    }

    func setMode(_ mode: String) {
        guard let client else { return }
        Task {
            do {
                let result: ESMode
                switch mode {
                case "Auto":
                    result = try await client.setAutoMode()
                case "Manual":
                    result = try await client.setManualMode()
                default:
                    return
                }
                await MainActor.run {
                    self.status.esMode = result
                }
                // Refresh all data after mode change
                poll()
            } catch {
                await MainActor.run {
                    self.connectionState = .error(error.localizedDescription)
                }
            }
        }
    }

    func testConnection() async -> Bool {
        guard !deviceIP.isEmpty else { return false }
        let testClient = MarstekAPIClient(host: deviceIP)
        do {
            _ = try await testClient.getESStatus()
            return true
        } catch {
            return false
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>, default defaultValue: Double) -> Double {
        if self == 0 { return defaultValue }
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
