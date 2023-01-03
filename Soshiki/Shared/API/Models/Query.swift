//
//  Query.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/18/22.
//

protocol QueryLike {
    associatedtype ReturnType: Codable
    associatedtype QueryType: StringRepresentable
}

struct QueryUser: QueryLike {
    typealias ReturnType = User
    typealias QueryType = UserOutput
    let id: String?
}

struct QueryUsers: QueryLike {
    typealias ReturnType = [User]
    typealias QueryType = UserOutput
    let ids: [String]
}

struct QueryLibrary: QueryLike {
    typealias ReturnType = Library
    typealias QueryType = LibraryOutput
    let mediaType: MediaType
}

struct QueryLibraries: QueryLike {
    typealias ReturnType = [Library]
    typealias QueryType = LibraryOutput
}

struct QueryEntry: QueryLike {
    typealias ReturnType = Entry
    typealias QueryType = EntryOutput
    let mediaType: MediaType
    let id: String
}

struct QueryEntries: QueryLike {
    typealias ReturnType = [Entry]
    typealias QueryType = EntryOutput
    let mediaType: MediaType
    let ids: [String]
}

struct QueryHistory: QueryLike {
    typealias ReturnType = History
    typealias QueryType = HistoryOutput
    let mediaType: MediaType
}

struct QueryHistories: QueryLike {
    typealias ReturnType = [History]
    typealias QueryType = HistoryOutput
}

struct QueryHistoryEntry: QueryLike {
    typealias ReturnType = HistoryEntry
    typealias QueryType = HistoryEntryOutput
    let mediaType: MediaType
    let id: String
}

struct QueryHistoryEntries: QueryLike {
    typealias ReturnType = [HistoryEntry]
    typealias QueryType = HistoryEntryOutput
    let mediaType: MediaType
    let ids: [String]
}

struct QueryLink: QueryLike {
    typealias ReturnType = EntryConnection
    typealias QueryType = EntryConnectionOutput
    let mediaType: MediaType
    let platform: String
    let source: String
    let sourceId: String
}

struct QuerySearch: QueryLike {
    typealias ReturnType = [Entry]
    typealias QueryType = EntryOutput
    let mediaType: MediaType
    let query: String
}
