//
//  SourceEntry.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/21/22.
//

enum SourceEntryStatus: String {
    case unknown = "UNKNOWN"
    case ongoing = "ONGOING"
    case completed = "COMPLETED"
    case dropped = "DROPPED"
    case hiatus = "HIATUS"
}

enum SourceEntryContentRating: String {
    case safe = "SAFE"
    case suggestive = "SUGGESTIVE"
    case nsfw = "NSFW"
}

struct SourceEntry: Hashable {
    let id: String
    let title: String
    let staff: [String]
    let tags: [String]
    let cover: String
    let nsfw: SourceEntryContentRating
    let status: SourceEntryStatus
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
