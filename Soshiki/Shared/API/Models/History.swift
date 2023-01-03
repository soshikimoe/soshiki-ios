//
//  History.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/18/22.
//

struct History: Codable, Sendable {
    let mediaType: MediaType?
    let entries: [HistoryEntry]?
}

struct HistoryEntry: Codable, Sendable {
    let id: String?
    let entry: Entry?
    let page: Int?
    let chapter: Float?
    let timestamp: Int?
    let episode: Float?
    let rating: Float?
    let status: TrackerStatus?
    let startTime: Float64?
    let lastTime: Float64?
    let trackerIds: [UserTracker]?
}

struct UserTracker: Codable, Sendable {
    let name: String?
    let id: String?
}

struct EmbeddedHistoryEntry: Codable, Sendable {
    let id: String?
    let page: Int?
    let chapter: Float?
    let timestamp: Int?
    let episode: Float?
    let rating: Float?
    let status: TrackerStatus?
    let startTime: Float64?
    let lastTime: Float64?
    let trackerIds: [UserTracker]?
}

enum TrackerStatus: String, Codable, StringRepresentable, Sendable {
    case unknown = "UNKNOWN"
    case planned = "PLANNED"
    case ongoing = "ONGOING"
    case completed = "COMPLETED"
    case dropped = "DROPPED"
    case paused = "PAUSED"
}

enum HistoryOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case mediaType
    case entries([HistoryEntryOutput])

    var rawValue: String {
        switch self {
        case .mediaType: return "mediaType"
        case .entries(let value): return value.graphql("entries")
        }
    }
}

enum HistoryEntryOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case entry([EntryOutput])
    case page
    case chapter
    case timestamp
    case episode
    case rating
    case status
    case startTime
    case lastTime
    case trackerIds([UserTrackerOutput])

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .entry(let value): return value.graphql("entry")
        case .page: return "page"
        case .chapter: return "chapter"
        case .timestamp: return "timestamp"
        case .episode: return "episode"
        case .rating: return "rating"
        case .status: return "status"
        case .startTime: return "startTime"
        case .lastTime: return "lastTime"
        case .trackerIds(let value): return value.graphql("trackerIds")
        }
    }
}

enum UserTrackerOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case name
    case id

    var rawValue: String {
        switch self {
        case .name: return "name"
        case .id: return "id"
        }
    }
}

enum EmbeddedHistoryEntryOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case page
    case chapter
    case timestamp
    case episode
    case rating
    case status
    case startTime
    case lastTime
    case trackerIds([UserTrackerOutput])

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .page: return "page"
        case .chapter: return "chapter"
        case .timestamp: return "timestamp"
        case .episode: return "episode"
        case .rating: return "rating"
        case .status: return "status"
        case .startTime: return "startTime"
        case .lastTime: return "lastTime"
        case .trackerIds(let value): return value.graphql("trackerIds")
        }
    }
}
