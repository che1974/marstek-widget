import Foundation

struct JSONRPCRequest: Encodable {
    let jsonrpc: String
    let id: Int
    let method: String
    let params: AnyCodable

    init(id: Int = 1, method: String) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = AnyCodable(["id": 0])
    }

    init(id: Int = 1, method: String, params: [String: Any]) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = AnyCodable(params)
    }
}

struct JSONRPCResponse<T: Decodable>: Decodable {
    let id: Int
    let src: String?
    let result: T
}

// Wrapper to encode arbitrary dictionaries as JSON
struct AnyCodable: Encodable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try Self.encode(value, into: &container)
    }

    private static func encode(_ value: Any, into container: inout SingleValueEncodingContainer) throws {
        switch value {
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as Bool: try container.encode(v)
        case let v as [String: Any]: try container.encode(v.mapValues { AnyCodable($0) })
        case let v as [Any]: try container.encode(v.map { AnyCodable($0) })
        default: try container.encodeNil()
        }
    }
}
