//
//  Decodable.swift
//  Soshiki
//
//  Created by Jim Phieffer on 6/17/23.
//

import Foundation

extension Decodable {
    static func fromObject(_ object: Any) throws -> Self {
        try AnyDecoder().decode(Self.self, from: object)
    }
}
