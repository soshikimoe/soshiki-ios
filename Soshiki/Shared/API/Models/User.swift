//
//  User.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/4/23.
//

import Foundation

struct User: Codable {
    let _id: UUID
    let discord: String
    let histories: Histories?
    let isHistoryPublic: Bool
    let libraries: Libraries?
    let isLibraryPublic: Bool
    let connections: [User.Connection]?

    struct Connection: Codable {
        let id: String
        let name: String
        let userId: String
        let userName: String
        let access: String
        let refresh: String
        let expiresIn: Double
    }
}
