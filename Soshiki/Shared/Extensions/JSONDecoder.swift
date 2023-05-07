//
//  JSONDecoder.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/15/22.
//

import Foundation

extension JSONDecoder.KeyDecodingStrategy {
    static var convertFromPascalCase: JSONDecoder.KeyDecodingStrategy {
        .custom { codingKeys -> CodingKey in
            let codingKey = codingKeys.last!
            guard codingKey.intValue == nil else { return codingKey }
            let codingKeyType = type(of: codingKey)
            return codingKeyType.init(stringValue: codingKey.stringValue.prefix(1).lowercased() + codingKey.stringValue.dropFirst())!
        }
    }
}
