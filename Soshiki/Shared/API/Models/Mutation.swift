//
//  Mutation.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/18/22.
//

protocol MutationLike {
    associatedtype ReturnType: Codable
    associatedtype QueryType: StringRepresentable
}

struct MutationSetLink: MutationLike {
    typealias ReturnType = EntryConnection
    typealias QueryType = EntryConnectionOutput
    let mediaType: MediaType
    let platform: String
    let source: String
    let sourceId: String
    let id: String
}

struct MutationRemoveLink: MutationLike {
    typealias ReturnType = EntryConnection
    typealias QueryType = EntryConnectionOutput
    let mediaType: MediaType
    let platform: String
    let source: String
    let id: String
}

struct MutationAddLibraryItem: MutationLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
    let id: String
    let category: String?
}

struct MutationAddLibraryItems: MutationLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
    let ids: [String]
    let category: String?
}

struct MutationRemoveLibraryItem: MutationLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
    let id: String
}

struct MutationRemoveLibraryItems: MutationLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
    let ids: [String]
}

struct MutationAddLibraryItemToCategory: MutationLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
    let id: String
    let category: String
}

struct MutationAddLibraryItemsToCategory: MutationLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
    let ids: [String]
    let category: String
}

struct MutationRemoveLibraryItemFromCategory: MutationLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
    let id: String
    let category: String
}

struct MutationRemoveLibraryItemsFromCategory: MutationLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
    let ids: [String]
    let category: String
}

struct MutationAddLibraryCategory: MutationLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
    let name: String
}

struct MutationAddLibraryCategories: MutationLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
    let names: [String]
}

struct MutationRemoveLibraryCategory: MutationLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
    let name: String
}

struct MutationRemoveLibraryCategories: MutationLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
    let names: [String]
}

struct MutationAddHistoryEntry: MutationLike {
    typealias ReturnType = History
    typealias QueryType = HistoryOutput
    let mediaType: MediaType
    let page: Int?
    let chapter: Float?
    let volume: Float?
    let timestamp: Int?
    let episode: Float?
    let rating: Float?
    let status: TrackerStatus?
    let startTime: Int?
    let lastTime: Int?
    let trackers: [UserTrackerInput]?
}

struct MutationSetHistoryEntry: MutationLike {
    typealias ReturnType = HistoryEntry
    typealias QueryType = HistoryEntryOutput
    let mediaType: MediaType
    let id: String
    let page: Int?
    let chapter: Float?
    let volume: Float?
    let timestamp: Int?
    let episode: Float?
    let rating: Float?
    let status: TrackerStatus?
    let startTime: Float64?
    let lastTime: Float64?
    let trackers: [UserTrackerInput]?
}

struct MutationRemoveHistoryEntry: MutationLike {
    typealias ReturnType = History
    typealias QueryType = HistoryOutput
    let mediaType: MediaType
    let id: String
}

struct UserTrackerInput: StringRepresentable {
    init?(rawValue: String) { nil }

    let name: String
    let id: String

    var rawValue: String {
        "{ name: \"\(name)\", id: \"\(id)\" }"
    }
}
