//
//  Library.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/18/22.
//

struct Library: Codable, Equatable, Sendable {
    static func == (lhs: Library, rhs: Library) -> Bool {
        lhs.mediaType == rhs.mediaType && lhs.categories?.allSatisfy({ category in rhs.categories?.contains(where: {
            $0.name == category.name
        }) ?? false }) ?? (rhs.categories == nil)
    }

    let mediaType: MediaType?
    let categories: [Category]?
}

struct Category: Codable, Sendable {
    let name: String?
    let entries: [EntryConnection]?
}

enum LibraryOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case mediaType
    case categories([CategoryOutput])

    var rawValue: String {
        switch self {
        case .mediaType: return "mediaType"
        case .categories(let value): return value.graphql("categories")
        }
    }
}

enum CategoryOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case name
    case entries([EntryConnectionOutput])

    var rawValue: String {
        switch self {
        case .name: return "name"
        case .entries(let value): return value.graphql("entries")
        }
    }
}
