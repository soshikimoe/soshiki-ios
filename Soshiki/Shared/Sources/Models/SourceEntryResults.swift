//
//  SourceEntryResults.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/30/22.
//

struct SourceEntryResultsInfo {
    let page: Int
}

struct SourceEntryResults {
    let page: Int
    let hasMore: Bool
    let entries: [SourceShortEntry]
}

struct SourceShortEntry: Hashable {
    let id: String
    let title: String
    let subtitle: String
    let cover: String

    func toLocalEntry() -> LocalEntry {
        LocalEntry(
            id: self.id,
            title: self.title,
            cover: self.cover,
            staff: [],
            tags: [],
            banner: nil,
            color: nil,
            description: nil
        )
    }

    static func == (lhs: SourceShortEntry, rhs: SourceShortEntry) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
