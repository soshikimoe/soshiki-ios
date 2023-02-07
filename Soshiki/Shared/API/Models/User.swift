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
    let devices: [User.Device]?
    let trackers: User.Trackers?

    struct Connection: Codable {
        let id: String
        let name: String
        let userId: String
        let userName: String
        let access: String
        let refresh: String
        let expiresIn: Double
    }

    struct Device: Codable {
        let id: String
        let badge: Int
        let notifications: User.Notifications
    }

    struct Notifications: Codable {
        let text: [User.Notification]
        let image: [User.Notification]
        let video: [User.Notification]
    }

    struct Notification: Codable {
        let id: String
        let source: String
    }

    struct Trackers: Codable {
        let text: [User.Tracker]
        let image: [User.Tracker]
        let video: [User.Tracker]
    }

    struct Tracker: Codable {
        let id: String
        let entryId: String
    }
}
