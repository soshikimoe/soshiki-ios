//
//  User.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/18/22.
//

struct User: Codable, Sendable {
    let id: String?
    let discord: String?
    let data: UserData?
}

enum UserOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case discord
    case data([UserDataOutput])

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .discord: return "discord"
        case .data(let value): return value.graphql("data")
        }
    }
}

struct UserData: Codable, Sendable {
    let mal: MALUser?
    let anilist: AnilistUser?
    let history: [History]?
    let library: [Library]?
}

enum UserDataOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case mal([MALUserOutput])
    case anilist([AnilistUserOutput])
    case history([HistoryOutput])
    case library([LibraryOutput])

    var rawValue: String {
        switch self {
        case .mal(let value): return value.graphql("mal")
        case .anilist(let value): return value.graphql("anilist")
        case .history(let value): return value.graphql("history")
        case .library(let value): return value.graphql("library")
        }
    }
}

struct MALUser: Codable, Sendable {
    let id: Int?
    let name: String?
    let picture: String?
}

enum MALUserOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case name
    case picture

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .name: return "name"
        case .picture: return "picture"
        }
    }
}

struct AnilistUser: Codable, Sendable {
    let id: Int?
    let name: String?
    let avatar: AnilistUserAvatar?
}

enum AnilistUserOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case name
    case avatar([AnilistUserAvatarOutput])

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .name: return "name"
        case .avatar(let value): return value.graphql("avatar")
        }
    }
}

struct AnilistUserAvatar: Codable, Sendable {
    let large: String?
    let medium: String?
}

enum AnilistUserAvatarOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case large
    case medium

    var rawValue: String {
        switch self {
        case .large: return "large"
        case .medium: return "medium"
        }
    }
}
