//
//  AnyCoder.swift
//  Soshiki
//
//  Created by Jim Phieffer on 6/17/23.
//
//  Adapted from https://stackoverflow.com/a/52308446
//

import Foundation

class AnyEncoder {
    private let encoder = JSONEncoder()

    var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy {
        get { encoder.dateEncodingStrategy }
        set { encoder.dateEncodingStrategy = newValue }
    }

    var dataEncodingStrategy: JSONEncoder.DataEncodingStrategy {
        get { encoder.dataEncodingStrategy }
        set { encoder.dataEncodingStrategy = newValue }
    }

    var nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy {
        get { encoder.nonConformingFloatEncodingStrategy }
        set { encoder.nonConformingFloatEncodingStrategy = newValue }
    }

    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        get { encoder.keyEncodingStrategy }
        set { encoder.keyEncodingStrategy = newValue }
    }

    func encode<T>(_ value: T) throws -> Any where T: Encodable {
        let data = try encoder.encode(value)
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }
}

class AnyDecoder {
    class UndecodableError: Error {}

    private let decoder = JSONDecoder()

    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        get { decoder.dateDecodingStrategy }
        set { decoder.dateDecodingStrategy = newValue }
    }

    var dataDecodingStrategy: JSONDecoder.DataDecodingStrategy {
        get { decoder.dataDecodingStrategy }
        set { decoder.dataDecodingStrategy = newValue }
    }

    var nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy {
        get { decoder.nonConformingFloatDecodingStrategy }
        set { decoder.nonConformingFloatDecodingStrategy = newValue }
    }

    var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        get { decoder.keyDecodingStrategy }
        set { decoder.keyDecodingStrategy = newValue }
    }

    func decode<T>(_ type: T.Type, from value: Any) throws -> T where T: Decodable {
        if let value = value as? T {
            return value
        } else if JSONSerialization.isValidJSONObject(value) {
            let data = try JSONSerialization.data(withJSONObject: value, options: [])
            return try decoder.decode(type, from: data)
        } else {
            throw UndecodableError()
        }
    }
}
