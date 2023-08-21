//
//  Library.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/4/23.
//

import Foundation
import RealmSwift
import Unrealm

final class LibraryItem: Realmable, Codable, Hashable {
    init() {}

    internal init(uuid: String = UUID().uuidString, mediaType: MediaType, id: String, sourceId: String, categories: [String]) {
        self.uuid = uuid
        self.mediaType = mediaType
        self.id = id
        self.sourceId = sourceId
        self.categories = categories
    }

    var uuid: String = UUID().uuidString
    var mediaType: MediaType = .text
    var id: String = ""
    var sourceId: String = ""
    var categories: [String] = []

    private enum CodingKeys: String, CodingKey {
        case mediaType, id, sourceId, categories
    }

    static func primaryKey() -> String? { "uuid" }

    static func == (lhs: LibraryItem, rhs: LibraryItem) -> Bool {
        lhs.mediaType == rhs.mediaType && lhs.id == rhs.id && lhs.sourceId == rhs.sourceId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.mediaType)
        hasher.combine(self.id)
        hasher.combine(self.sourceId)
        hasher.combine(self.uuid)
    }

    func copy() -> LibraryItem {
        LibraryItem(mediaType: self.mediaType, id: self.id, sourceId: self.sourceId, categories: self.categories)
    }
}

final class LibraryCategory: Realmable, Codable, Hashable {
    init() {}

    internal init(uuid: String = UUID().uuidString, mediaType: MediaType, id: String, name: String) {
        self.uuid = uuid
        self.mediaType = mediaType
        self.id = id
        self.name = name
    }

    var uuid: String = UUID().uuidString
    var mediaType: MediaType = .text
    var id: String = ""
    var name: String = ""

    private enum CodingKeys: String, CodingKey {
        case mediaType, id, name
    }

    static func primaryKey() -> String? { "uuid" }

    static func == (lhs: LibraryCategory, rhs: LibraryCategory) -> Bool {
        lhs.mediaType == rhs.mediaType && lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.mediaType)
        hasher.combine(self.id)
    }
}
