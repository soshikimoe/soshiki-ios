//
//  JSONAny.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/15/22.
//

enum JSONAny: Codable {
    case string(String)
    case double(Double)
    case int(Int)
    case boolean(Bool)
    case object([String: JSONAny])
    case array([JSONAny])
    case null

    public func stringValue() -> String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }
    public func doubleValue() -> Double? {
        if case .double(let value) = self {
            return value
        }
        return nil
    }
    public func intValue() -> Int? {
        if case .int(let value) = self {
            return value
        }
        return nil
    }
    public func booleanValue() -> Bool? {
        if case .boolean(let value) = self {
            return value
        }
        return nil
    }
    public func objectValue() -> [String: JSONAny]? {
        if case .object(let value) = self {
            return value
        }
        return nil
    }
    public func arrayValue() -> [JSONAny]? {
        if case .array(let value) = self {
            return value
        }
        return nil
    }
    public func isNull() -> Bool {
        if case .null = self {
            return true
        }
        return false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .string(value): try container.encode(value)
        case let .double(value): try container.encode(value)
        case let .int(value): try container.encode(value)
        case let .boolean(value): try container.encode(value)
        case let .object(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode([String: JSONAny].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONAny].self) {
            self = .array(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid value"))
        }
    }
}
