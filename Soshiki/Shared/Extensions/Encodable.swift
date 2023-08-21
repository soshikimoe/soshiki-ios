//
//  Encodable.swift
//  Soshiki
//
//  Created by Jim Phieffer on 6/17/23.
//

import Foundation

extension Encodable {
    func toObject() throws -> Any {
        try AnyEncoder().encode(self)
    }
}
