//
//  Entry.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/18/22.
//

enum MediaType: String, Codable, StringRepresentable, Sendable, CaseIterable {
    case text = "TEXT"
    case image = "IMAGE"
    case video = "VIDEO"
}

struct EntryConnection: Codable, Sendable {
    let id: String?
    let entry: Entry?
}

struct Entry: Codable, Sendable {
    let id: String?
    let info: EntryInfo?
    let trackers: [Tracker]?
    let platforms: [_Platform]?
    let history: EmbeddedHistoryEntry?
}

struct Tracker: Codable, Sendable {
    let name: String?
    let id: String?
    let user: String?
}

struct _Platform: Codable, Sendable { // swiftlint:disable:this type_name
    let name: String?
    let sources: [_Source]?
}

struct _Source: Codable, Sendable { // swiftlint:disable:this type_name
    let name: String?
    let id: String?
    let user: String?
}

struct EntryInfo: Codable, Sendable {
    let nsfw: Bool?
    let cover: String?
    let title: String?
    let author: String?
    let altTitles: [String]?
    let mal: MALEntry?
    let anilist: AnilistEntry?
}

enum EntryConnectionOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case entry([EntryOutput])

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .entry(let value): return value.graphql("entry")
        }
    }
}

enum EntryOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case info([EntryInfoOutput])
    case trackers([TrackerOutput])
    case platforms([PlatformOutput])
    case history([EmbeddedHistoryEntryOutput])

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .info(let value): return value.graphql("info")
        case .trackers(let value): return value.graphql("trackers")
        case .platforms(let value): return value.graphql("platforms")
        case .history(let value): return value.graphql("history")
        }
    }
}

enum TrackerOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case name
    case id
    case user

    var rawValue: String {
        switch self {
        case .name: return "name"
        case .id: return "id"
        case .user: return "user"
        }
    }
}

enum PlatformOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case name
    case sources([SourceOutput])

    var rawValue: String {
        switch self {
        case .name: return "name"
        case .sources(let value): return value.graphql("sources")
        }
    }
}

enum SourceOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case name
    case id
    case user

    var rawValue: String {
        switch self {
        case .name: return "name"
        case .id: return "id"
        case .user: return "user"
        }
    }
}

enum EntryInfoOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case nsfw
    case cover
    case title
    case author
    case altTitles
    case mal([MALEntryOutput])
    case anilist([AnilistEntryOutput])

    var rawValue: String {
        switch self {
        case .nsfw: return "nsfw"
        case .cover: return "cover"
        case .title: return "title"
        case .author: return "author"
        case .altTitles: return "altTitles"
        case .mal(let value): return value.graphql("mal")
        case .anilist(let value): return value.graphql("anilist")
        }
    }
}
