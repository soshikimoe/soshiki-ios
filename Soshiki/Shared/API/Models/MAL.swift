//
//  MAL.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/18/22.
//

struct MALEntry: Codable, Sendable {
    let id: Int?
    let title: String?
    let mainPicture: MALPicture?
    let alternativeTitles: MALAlternativeTitles?
    let startDate: String?
    let endDate: String?
    let synopsis: String?
    let mean: Float?
    let rank: Int?
    let numListUsers: Int?
    let numScoringUsers: Int?
    let nsfw: String?
    let genres: [MALGenre]?
    let createdAt: String?
    let updatedAt: String?
    let mediaType: String?
    let status: String?
    let numVolumes: Int?
    let numChapters: Int?
    let authors: [MALPerson]?
    let pictures: [MALPicture]?
    let background: String?
    let relatedAnime: [MALRelation]?
    let relatedManga: [MALRelation]?
    let recommendations: [MALRecommendation]?
}

struct MALPicture: Codable, Sendable {
    let large: String?
    let medium: String?
}

struct MALAlternativeTitles: Codable, Sendable {
    let synonyms: [String]?
    let en: String?
    let ja: String?
}

struct MALGenre: Codable, Sendable {
    let id: Int?
    let name: String?
}

struct MALPerson: Codable, Sendable {
    let info: MALPersonInfo?
    let role: String?
}

struct MALPersonInfo: Codable, Sendable {
    let id: Int?
    let firstName: String?
    let lastName: String?
}

struct MALRelation: Codable, Sendable {
    let node: MALShortEntry?
    let relationType: String?
    let relationTypeFormatted: String?
}

struct MALShortEntry: Codable, Sendable {
    let id: String?
    let title: String?
    let mainPicture: MALPicture
}

struct MALRecommendation: Codable, Sendable {
    let node: MALShortEntry?
    let numRecommendations: Int?
}

enum MALEntryOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case title
    case mainPicture([MALPictureOutput])
    case alternativeTitles([MALAlternativeTitlesOutput])
    case startDate
    case endDate
    case synopsis
    case mean
    case rank
    case numListUsers
    case numScoringUsers
    case nsfw
    case genres([MALGenreOutput])
    case createdAt
    case updatedAt
    case mediaType
    case status
    case numVolumes
    case numChapters
    case authors([MALPersonOutput])
    case pictures([MALPictureOutput])
    case background
    case relatedAnime([MALRelationOutput])
    case relatedManga([MALRelationOutput])
    case recommendations([MALRecommendationOutput])

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .title: return "title"
        case .mainPicture(let value): return value.graphql("mainPicture")
        case .alternativeTitles(let value): return value.graphql("alternativeTitles")
        case .startDate: return "startDate"
        case .endDate: return "endDate"
        case .synopsis: return "synopsis"
        case .mean: return "mean"
        case .rank: return "rank"
        case .numListUsers: return "numListUsers"
        case .numScoringUsers: return "numScoringUsers"
        case .nsfw: return "nsfw"
        case .genres(let value): return value.graphql("genres")
        case .createdAt: return "createdAt"
        case .updatedAt: return "updatedAt"
        case .mediaType: return "mediaType"
        case .status: return "status"
        case .numVolumes: return "numVolumes"
        case .numChapters: return "numChapters"
        case .authors(let value): return value.graphql("authors")
        case .pictures(let value): return value.graphql("pictures")
        case .background: return "background"
        case .relatedAnime(let value): return value.graphql("relatedAnime")
        case .relatedManga(let value): return value.graphql("relatedManga")
        case .recommendations(let value): return value.graphql("recommendations")
        }
    }
}

enum MALPictureOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case large
    case medium

    var rawValue: String {
        switch self {
        case .large: return "large"
        case .medium: return "medium"
        }
    }
}

enum MALAlternativeTitlesOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case synonyms
    case en
    case ja

    var rawValue: String {
        switch self {
        case .synonyms: return "synonyms"
        case .en: return "en"
        case .ja: return "ja"
        }
    }
}

enum MALGenreOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case name

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .name: return "name"
        }
    }
}

enum MALPersonOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case info([MALPersonInfoOutput])
    case role

    var rawValue: String {
        switch self {
        case .info(let value): return value.graphql("info")
        case .role: return "role"
        }
    }
}

enum MALPersonInfoOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case firstName
    case lastName

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .firstName: return "firstName"
        case .lastName: return "lastName"
        }
    }
}

enum MALRelationOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case node([MALShortEntryOutput])
    case relationType
    case relationTypeFormatted

    var rawValue: String {
        switch self {
        case .node(let value): return value.graphql("node")
        case .relationType: return "relationType"
        case .relationTypeFormatted: return "relationTypeFormatted"
        }
    }
}

enum MALShortEntryOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case title
    case mainPicture([MALPictureOutput])

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .title: return "title"
        case .mainPicture(let value): return value.graphql("mainPicture")
        }
    }
}

enum MALRecommendationOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case node([MALShortEntryOutput])
    case numRecommendations

    var rawValue: String {
        switch self {
        case .node(let value): return value.graphql("node")
        case .numRecommendations: return "numRecommendations"
        }
    }
}
