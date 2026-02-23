import Foundation
import Network

enum APIError: LocalizedError {
    case connectionFailed(String)
    case timeout
    case decodingError(String)
    case sendFailed(String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .timeout: return "Request timed out"
        case .decodingError(let msg): return "Decoding error: \(msg)"
        case .sendFailed(let msg): return "Send failed: \(msg)"
        }
    }
}

actor MarstekAPIClient {
    private let host: String
    private let port: UInt16
    private let timeout: TimeInterval
    private let maxRetries: Int

    init(host: String, port: UInt16 = 30000, timeout: TimeInterval = 5, maxRetries: Int = 2) {
        self.host = host
        self.port = port
        self.timeout = timeout
        self.maxRetries = maxRetries
    }

    func getESStatus() async throws -> ESStatus {
        let request = JSONRPCRequest(method: "ES.GetStatus")
        return try await sendRequest(request)
    }

    func getBatStatus() async throws -> BatStatus {
        let request = JSONRPCRequest(method: "Bat.GetStatus")
        return try await sendRequest(request)
    }

    func getEMStatus() async throws -> EMStatus {
        let request = JSONRPCRequest(method: "EM.GetStatus")
        return try await sendRequest(request)
    }

    func getESMode() async throws -> ESMode {
        let request = JSONRPCRequest(method: "ES.GetMode")
        return try await sendRequest(request)
    }

    func setAutoMode() async throws -> ESMode {
        let request = JSONRPCRequest(method: "ES.SetMode", params: [
            "id": 0,
            "config": ["mode": "Auto", "auto_cfg": ["enable": 1]]
        ])
        return try await sendRequest(request)
    }

    func setManualMode() async throws -> ESMode {
        let request = JSONRPCRequest(method: "ES.SetMode", params: [
            "id": 0,
            "config": [
                "mode": "Manual",
                "manual_cfg": [
                    "time_num": 0,
                    "start_time": "00:00",
                    "end_time": "23:59",
                    "week_set": 127,
                    "power": 0,
                    "enable": 1
                ]
            ]
        ])
        return try await sendRequest(request)
    }

    private func sendRequest<T: Decodable>(_ request: JSONRPCRequest) async throws -> T {
        var lastError: Error = APIError.timeout
        for attempt in 0...maxRetries {
            do {
                return try await performRequest(request)
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(for: .milliseconds(500))
                }
            }
        }
        throw lastError
    }

    private func performRequest<T: Decodable>(_ request: JSONRPCRequest) async throws -> T {
        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: port),
            using: .udp
        )

        return try await withCheckedThrowingContinuation { continuation in
            var resumed = false
            let lock = NSLock()

            func resume(with result: Result<T, Error>) {
                lock.lock()
                defer { lock.unlock() }
                guard !resumed else { return }
                resumed = true
                connection.cancel()
                continuation.resume(with: result)
            }

            // Timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                resume(with: .failure(APIError.timeout))
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    // Encode and send
                    guard let data = try? JSONEncoder().encode(request) else {
                        resume(with: .failure(APIError.sendFailed("Failed to encode request")))
                        return
                    }

                    connection.send(content: data, completion: .contentProcessed { error in
                        if let error {
                            resume(with: .failure(APIError.sendFailed(error.localizedDescription)))
                            return
                        }

                        // Receive response
                        connection.receiveMessage { data, _, _, error in
                            if let error {
                                resume(with: .failure(APIError.connectionFailed(error.localizedDescription)))
                                return
                            }

                            guard let data else {
                                resume(with: .failure(APIError.decodingError("No data received")))
                                return
                            }

                            do {
                                let decoder = JSONDecoder()
                                let response = try decoder.decode(JSONRPCResponse<T>.self, from: data)
                                resume(with: .success(response.result))
                            } catch {
                                resume(with: .failure(APIError.decodingError(error.localizedDescription)))
                            }
                        }
                    })

                case .failed(let error):
                    resume(with: .failure(APIError.connectionFailed(error.localizedDescription)))

                case .cancelled:
                    break

                default:
                    break
                }
            }

            connection.start(queue: .global())
        }
    }
}
