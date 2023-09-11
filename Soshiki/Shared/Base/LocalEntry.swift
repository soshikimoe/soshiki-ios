//
//  LocalEntry.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/5/23.
//

import Foundation

struct LocalEntry: Codable, Hashable {
    let id: String
    let title: String
    let cover: String
    let staff: [String]
    let tags: [String]
    let banner: String?
    let color: String?
    let description: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
