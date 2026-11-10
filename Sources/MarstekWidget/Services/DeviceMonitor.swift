import Foundation
import SwiftUI
import UserNotifications

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

    var notifyGridReturn: Bool {
        UserDefaults.standard.object(forKey: "notifyGridReturn") as? Bool ?? true
    }

    func start() {
        if notifyGridReturn {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
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

    // Venus firmware stalls and reboots under bursts of Local API requests, so each tick
    // sends only ES.GetStatus and the rest go out every few ticks, spaced apart, never overlapping.
    private static let fullPollEvery = 5
    private static let requestGap: Duration = .seconds(3)
    private var isPolling = false
    private var pollCount = 0
    private var wasGridOn: Bool?

    func poll(full: Bool = false) {
        guard let client, !isPolling else { return }
        isPolling = true
        let fetchAll = full || pollCount % Self.fullPollEvery == 0
        pollCount += 1
        connectionState = .connecting

        Task {
            do {
                let esResult = try await client.getESStatus()
                await MainActor.run {
                    self.status.esStatus = esResult
                    self.status.lastUpdated = Date()
                    self.connectionState = .connected
                    self.checkGridReturn()
                }
                if fetchAll {
                    try await Task.sleep(for: Self.requestGap)
                    let bat = try await client.getBatStatus()
                    await MainActor.run { self.status.batStatus = bat }
                    try await Task.sleep(for: Self.requestGap)
                    let em = try await client.getEMStatus()
                    await MainActor.run { self.status.emStatus = em }
                    try await Task.sleep(for: Self.requestGap)
                    let mode = try await client.getESMode()
                    await MainActor.run { self.status.esMode = mode }
                }
                await MainActor.run { self.isPolling = false }
            } catch {
                await MainActor.run {
                    self.connectionState = .error(error.localizedDescription)
                    self.isPolling = false
                }
            }
        }
    }

    private func checkGridReturn() {
        let gridOn = status.hasGridPower
        if gridCameBack(was: wasGridOn, now: gridOn), notifyGridReturn {
            let content = UNMutableNotificationContent()
            content.title = "Grid is back"
            content.body = status.gridPower.map { "Grid power: \(formatPower(abs($0)))" } ?? ""
            content.sound = .default
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
        if let gridOn { wasGridOn = gridOn }
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
                await MainActor.run { self.poll(full: true) }
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
