//
//  SourceListing.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/28/22.
//

import Foundation

struct SourceListing: JSObjectCodable, Hashable {
    init?(from object: [String: Any]) {
        guard let id = object["id"] as? String,
              let name = object["name"] as? String else { return nil }
        self.id = id
        self.name = name
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    let id: String
    let name: String

    var object: [String: Any] {
        [
            "id": id,
            "name": name
        ]
    }

    static func == (lhs: SourceListing, rhs: SourceListing) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}
