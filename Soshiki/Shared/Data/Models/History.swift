//
//  History.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/4/23.
//

import Foundation
import RealmSwift
import Unrealm

enum HistoryStatus: String, RealmableEnumString, Codable, CaseIterable {
    case completed = "COMPLETED"
    case inProgress = "IN_PROGRESS"
    case planned = "PLANNED"
    case dropped = "DROPPED"
    case paused = "PAUSED"
    case unknown = "UNKNOWN"

    var prettyName: String {
        self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

protocol History: Realmable, Codable {
    var id: String { get }
    var sourceId: String { get }
    var score: Double? { get set }
    var status: HistoryStatus { get set }
}

final class TextHistory: Realmable, Codable, History {
    init() {}

    internal init(
        uuid: String = UUID().uuidString,
        id: String,
        sourceId: String,
        chapter: Double,
        volume: Double?,
        percent: Double,
        score: Double?,
        status: HistoryStatus
    ) {
        self.uuid = uuid
        self.id = id
        self.sourceId = sourceId
        self.chapter = chapter
        self.volume = volume
        self.percent = percent
        self.score = score
        self.status = status
    }

    internal init(id: String, sourceId: String) {
        self.id = id
        self.sourceId = sourceId
    }

    var uuid: String = UUID().uuidString
    var id: String = ""
    var sourceId: String = ""
    var chapter: Double = 0
    var volume: Double?
    var percent: Double = 0
    var score: Double?
    var status: HistoryStatus = .unknown

    private enum CodingKeys: String, CodingKey {
        case id, sourceId, chapter, volume, percent, score, status
    }

    static func primaryKey() -> String? { "uuid" }
}

final class ImageHistory: Realmable, Codable, History {
    init() {}

    internal init(
        uuid: String = UUID().uuidString,
        id: String,
        sourceId: String,
        chapter: Double,
        volume: Double?,
        page: Int,
        score: Double?,
        status: HistoryStatus
    ) {
        self.uuid = uuid
        self.id = id
        self.sourceId = sourceId
        self.chapter = chapter
        self.volume = volume
        self.page = page
        self.score = score
        self.status = status
    }

    internal init(id: String, sourceId: String) {
        self.id = id
        self.sourceId = sourceId
    }

    var uuid: String = UUID().uuidString
    var id: String = ""
    var sourceId: String = ""
    var chapter: Double = 0
    var volume: Double?
    var page: Int = 0
    var score: Double?
    var status: HistoryStatus = .unknown

    private enum CodingKeys: String, CodingKey {
        case id, sourceId, chapter, volume, page, score, status
    }

    static func primaryKey() -> String? { "uuid" }
}

final class VideoHistory: Realmable, Codable, History {
    init() {}

    internal init(
        uuid: String = UUID().uuidString,
        id: String,
        sourceId: String,
        episode: Double,
        season: Double?,
        timestamp: Double,
        score: Double?,
        status: HistoryStatus
    ) {
        self.uuid = uuid
        self.id = id
        self.sourceId = sourceId
        self.episode = episode
        self.season = season
        self.timestamp = timestamp
        self.score = score
        self.status = status
    }

    internal init(id: String, sourceId: String) {
        self.id = id
        self.sourceId = sourceId
    }

    var uuid: String = UUID().uuidString
    var id: String = ""
    var sourceId: String = ""
    var episode: Double = 0
    var season: Double?
    var timestamp: Double = 0
    var score: Double?
    var status: HistoryStatus = .unknown

    private enum CodingKeys: String, CodingKey {
        case id, sourceId, episode, season, timestamp, score, status
    }

    static func primaryKey() -> String? { "uuid" }
}

struct History_Old: Codable {
    let id: String
    let page: Int?
    let chapter: Double?
    let volume: Double?
    let timestamp: Int?
    let episode: Double?
    let season: Double?
    let percent: Double?
    let score: Double?
    let status: History_Old.Status

    enum Status: String, Codable, CaseIterable {
        case completed = "COMPLETED"
        case inProgress = "IN_PROGRESS"
        case planned = "PLANNED"
        case dropped = "DROPPED"
        case paused = "PAUSED"
        case unknown = "UNKNOWN"

        var prettyName: String {
            self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    func withId(_ newId: String) -> History_Old {
        History_Old(
            id: newId,
            page: self.page,
            chapter: self.chapter,
            volume: self.volume,
            timestamp: self.timestamp,
            episode: self.episode,
            season: self.season,
            percent: self.percent,
            score: self.score,
            status: self.status
        )
    }
}

struct Histories_Old: Codable {
    let text: [History_Old]
    let image: [History_Old]
    let video: [History_Old]
}
