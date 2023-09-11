//
//  SourceListing.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/28/22.
//

import Foundation

enum SourceListingType: String, Codable {
    case featured = "FEATURED"
    case trending = "TRENDING"
    case topRated = "TOP_RATED"
    case basic = "BASIC"
}

struct SourceListing: Codable, Hashable {
    let id: String
    let name: String
    let type: SourceListingType

    static func == (lhs: SourceListing, rhs: SourceListing) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}
