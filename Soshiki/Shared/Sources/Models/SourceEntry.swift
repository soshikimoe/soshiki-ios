//
//  SourceEntry.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/21/22.
//

enum SourceEntryStatus: String, Codable {
    case unknown = "UNKNOWN"
    case ongoing = "ONGOING"
    case completed = "COMPLETED"
    case dropped = "DROPPED"
    case hiatus = "HIATUS"
}

enum SourceEntryContentRating: String, Codable {
    case safe = "SAFE"
    case suggestive = "SUGGESTIVE"
    case nsfw = "NSFW"
}

enum SourceEntrySeason: String, Codable {
    case winter = "WINTER"
    case spring = "SPRING"
    case summer = "SUMMER"
    case fall = "FALL"
}

struct SourceEntry: Hashable, Codable {
    let id: String
    let title: String
    let staff: [String]
    let tags: [String]
    let cover: String
    let banner: String?
    let nsfw: SourceEntryContentRating
    let status: SourceEntryStatus
    let score: Double?
    let items: Int?
    let season: SourceEntrySeason?
    let year: Int?
    let url: String
    let description: String

    func toLocalEntry() -> LocalEntry {
        LocalEntry(
            id: self.id,
            title: self.title,
            cover: self.cover,
            staff: self.staff,
            tags: self.tags,
            banner: nil,
            color: nil,
            description: self.description
        )
    }

    static func == (lhs: SourceEntry, rhs: SourceEntry) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
