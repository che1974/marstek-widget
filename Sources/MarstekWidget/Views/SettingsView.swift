import SwiftUI

struct SettingsView: View {
    @Bindable var monitor: DeviceMonitor
    @State private var ipAddress: String = ""
    @State private var selectedInterval: TimeInterval = 60
    @State private var testResult: TestResult?
    @State private var isTesting = false

    enum TestResult {
        case success
        case failure
    }

    private let intervalOptions: [(String, TimeInterval)] = [
        ("30 seconds", 30),
        ("1 minute", 60),
        ("2 minutes", 120),
        ("5 minutes", 300),
    ]

    var body: some View {
        Form {
            Section("Device") {
                TextField("Device IP Address", text: $ipAddress)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { applyIP() }

                HStack {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(ipAddress.isEmpty || isTesting)

                    if isTesting {
                        ProgressView()
                            .controlSize(.small)
                    }

                    if let result = testResult {
                        Image(systemName: result == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result == .success ? .green : .red)
                    }
                }
            }

            Section("Polling") {
                Picker("Update interval", selection: $selectedInterval) {
                    ForEach(intervalOptions, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
                .onChange(of: selectedInterval) { _, newValue in
                    monitor.pollingInterval = newValue
                }
            }

            Section("General") {
                Toggle("Launch at login", isOn: Binding(
                    get: { monitor.launchAtLogin },
                    set: { monitor.launchAtLogin = $0 }
                ))
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 280)
        .onAppear {
            ipAddress = monitor.deviceIP
            selectedInterval = monitor.pollingInterval
        }
    }

    private func applyIP() {
        monitor.deviceIP = ipAddress
        monitor.restartPolling()
    }

    private func testConnection() {
        applyIP()
        isTesting = true
        testResult = nil

        Task {
            let success = await monitor.testConnection()
            await MainActor.run {
                testResult = success ? .success : .failure
                isTesting = false
            }
        }
    }
}
