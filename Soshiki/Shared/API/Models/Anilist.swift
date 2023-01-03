//
//  Anilist.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/18/22.
//

struct AnilistEntry: Codable, Sendable {
    let id: Int?
    let idMal: Int?
    let title: AnilistMediaTitle?
    let type: AnilistMediaType?
    let format: AnilistMediaFormat?
    let status: AnilistMediaStatus?
    let description: String?
    let startDate: AnilistFuzzyDate?
    let endDate: AnilistFuzzyDate?
    let season: AnilistMediaSeason?
    let seasonYear: Int?
    let seasonInt: Int?
    let episodes: Int?
    let duration: Int?
    let chapters: Int?
    let volumes: Int?
    let countryOfOrigin: String?
    let isLicensed: Bool?
    let source: AnilistMediaSource?
    let hashtag: String?
    let trailer: AnilistTrailer?
    let updatedAt: Int?
    let coverImage: AnilistMediaCoverImage?
    let bannerImage: String?
    let genres: [String]?
    let synonyms: [String]?
    let averageScore: Int?
    let meanScore: Int?
    let popularity: Int?
    let isLocked: Bool?
    let trending: Int?
    let favourites: Int?
    let tags: [AnilistMediaTag]?
    let relations: [AnilistEntry]?
    let characters: [AnilistCharacter]?
    let staff: [AnilistStaff]?
    let studios: [AnilistStudio]?
    let isFavourite: Bool?
    let isAdult: Bool?
    let nextAiringEpisode: AnilistAiringSchedule?
    let airingSchedule: [AnilistAiringSchedule]?
    let externalLinks: [AnilistMediaExternalLink]?
    let streamingEpisodes: [AnilistMediaStreamingEpisode]?
    let rankings: [AnilistMediaRank]?
    let recommendations: [AnilistRecommendation]?
    let stats: AnilistMediaStats?
    let siteUrl: String?
}

struct AnilistMediaTitle: Codable, Sendable {
    let romaji: String?
    let native: String?
    let english: String?
    let userPreferred: String?
}

enum AnilistMediaType: String, Codable, StringRepresentable, Sendable {
    case manga = "MANGA"
    case anime = "ANIME"
}

enum AnilistMediaFormat: String, Codable, StringRepresentable, Sendable {
    case tv = "TV"
    case tvShort = "TV_SHORT"
    case movie = "MOVIE"
    case special = "SPECIAL"
    case ova = "OVA"
    case ona = "ONA"
    case music = "MUSIC"
    case manga = "MANGA"
    case novel = "NOVEL"
    case oneShot = "ONE_SHOT"
}

enum AnilistMediaStatus: String, Codable, StringRepresentable, Sendable {
    case finished = "FINISHED"
    case releasing = "RELEASING"
    case notYetReleased = "NOT_YET_RELEASED"
    case cancelled = "CANCELLED"
    case hiatus = "HIATUS"
}

struct AnilistFuzzyDate: Codable, Sendable {
    let year: Int?
    let month: Int?
    let day: Int?
}

enum AnilistMediaSeason: String, Codable, StringRepresentable, Sendable {
    case winter = "WINTER"
    case spring = "SPRING"
    case summer = "SUMMER"
    case fall = "FALL"
}

enum AnilistMediaSource: String, Codable, StringRepresentable, Sendable {
    case original = "ORIGINAL"
    case manga = "MANGA"
    case lightNovel = "LIGHT_NOVEL"
    case visualNovel = "VISUAL_NOVEL"
    case videoGame = "VIDEO_GAME"
    case other = "OTHER"
    case novel = "NOVEL"
    case doujinshi = "DOUJINSHI"
    case anime = "ANIME"
    case webNovel = "WEB_NOVEL"
    case liveAction = "LIVE_ACTION"
    case game = "GAME"
    case comic = "COMIC"
    case multimediaProject = "MULTIMEDIA_PROJECT"
    case pictureBook = "PICTURE_BOOK"
}

struct AnilistTrailer: Codable, Sendable {
    let id: String?
    let site: String?
    let thumbnail: String?
}

struct AnilistMediaCoverImage: Codable, Sendable {
    let extraLarge: String?
    let large: String?
    let medium: String?
    let color: String?
}

struct AnilistMediaTag: Codable, Sendable {
    let id: Int?
    let name: String?
    let description: String?
    let category: String?
    let rank: Int?
    let isGeneralSpoiler: Bool?
    let isMediaSpoiler: Bool?
    let isAdult: Bool?
    let userId: Int?
}

struct AnilistCharacter: Codable, Sendable {
    let id: Int?
    let name: AnilistCharacterName?
    let image: AnilistCharacterImage?
}

struct AnilistCharacterName: Codable, Sendable {
    let first: String?
    let middle: String?
    let last: String?
    let full: String?
    let native: String?
    let alternative: [String]?
    let alternativeSpoiler: [String]?
    let userPreferred: String?
}

struct AnilistCharacterImage: Codable, Sendable {
    let large: String?
    let medium: String?
}

struct AnilistStaff: Codable, Sendable {
    let id: Int?
    let name: AnilistStaffName?
    let image: AnilistStaffImage?
}

struct AnilistStaffName: Codable, Sendable {
    let first: String?
    let middle: String?
    let last: String?
    let full: String?
    let native: String?
    let alternative: [String]?
    let alternativeSpoiler: [String]?
    let userPreferred: String?
}

struct AnilistStaffImage: Codable, Sendable {
    let large: String?
    let medium: String?
}

struct AnilistStudio: Codable, Sendable {
    let id: Int?
    let name: String?
    let isAnimationStudio: Bool?
}

struct AnilistAiringSchedule: Codable, Sendable {
    let airingAt: Int?
    let timeUntilAiring: Int?
    let episode: Int?
}

struct AnilistMediaExternalLink: Codable, Sendable {
    let url: String?
}

struct AnilistMediaStreamingEpisode: Codable, Sendable {
    let title: String?
    let thumbnail: String?
    let url: String?
    let site: String?
}

struct AnilistMediaRank: Codable, Sendable {
    let rank: Int?
    let type: AnilistMediaRankType?
    let context: String?
    let year: Int?
    let season: AnilistMediaSeason?
}

enum AnilistMediaRankType: String, Codable, StringRepresentable, Sendable {
    case rated = "RATED"
    case popular = "POPULAR"
}

struct AnilistRecommendation: Codable, Sendable {
    let mediaRecommendation: AnilistEntry
}

struct AnilistMediaStats: Codable, Sendable {
    let scoreDistribution: [AnilistScoreDistribution]?
    let statusDistribution: [AnilistStatusDistribution]?
}

struct AnilistScoreDistribution: Codable, Sendable {
    let score: Int?
    let amount: Int?
}

struct AnilistStatusDistribution: Codable, Sendable {
    let status: AnilistMediaListStatus?
    let amount: Int?
}

enum AnilistMediaListStatus: String, Codable, StringRepresentable, Sendable {
    case current = "CURRENT"
    case planning = "PLANNING"
    case completed = "COMPLETED"
    case dropped = "DROPPED"
    case paused = "PAUSED"
    case repeating = "REPEATING"
}

enum AnilistEntryOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case idMal
    case title([AnilistMediaTitleOutput])
    case type
    case format
    case status
    case description
    case startDate([AnilistFuzzyDateOutput])
    case endDate([AnilistFuzzyDateOutput])
    case season
    case seasonYear
    case seasonInt
    case episodes
    case duration
    case chapters
    case volumes
    case countryOfOrigin
    case isLicensed
    case source
    case hashtag
    case trailer([AnilistTrailerOutput])
    case updatedAt
    case coverImage([AnilistMediaCoverImageOutput])
    case bannerImage
    case genres
    case synonyms
    case averageScore
    case meanScore
    case popularity
    case isLocked
    case trending
    case favourites
    case tags([AnilistMediaTagOutput])
    case relations([AnilistEntryOutput])
    case characters([AnilistCharacterOutput])
    case staff([AnilistStaffOutput])
    case studios([AnilistStudioOutput])
    case isFavourite
    case isAdult
    case nextAiringEpisode([AnilistAiringScheduleOutput])
    case airingSchedule([AnilistAiringScheduleOutput])
    case externalLinks([AnilistMediaExternalLinkOutput])
    case streamingEpisodes([AnilistMediaStreamingEpisodeOutput])
    case rankings([AnilistMediaRankOutput])
    case recommendations([AnilistRecommendationOutput])
    case stats([AnilistMediaStatsOutput])
    case siteUrl

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .idMal: return "idMal"
        case .title(let value): return value.graphql("title")
        case .type: return "type"
        case .format: return "format"
        case .status: return "status"
        case .description: return "description"
        case .startDate(let value): return value.graphql("startDate")
        case .endDate(let value): return value.graphql("endDate")
        case .season: return "season"
        case .seasonYear: return "seasonYear"
        case .seasonInt: return "seasonInt"
        case .episodes: return "episodes"
        case .duration: return "duration"
        case .chapters: return "chapters"
        case .volumes: return "volumes"
        case .countryOfOrigin: return "countryOfOrigin"
        case .isLicensed: return "isLicensed"
        case .source: return "source"
        case .hashtag: return "hashtag"
        case .trailer(let value): return value.graphql("trailer")
        case .updatedAt: return "updatedAt"
        case .coverImage(let value): return value.graphql("coverImage")
        case .bannerImage: return "bannerImage"
        case .genres: return "genres"
        case .synonyms: return "synonyms"
        case .averageScore: return "averageScore"
        case .meanScore: return "meanScore"
        case .popularity: return "popularity"
        case .isLocked: return "isLocked"
        case .trending: return "trending"
        case .favourites: return "favourites"
        case .tags(let value): return value.graphql("tags")
        case .relations(let value): return value.graphql("relations")
        case .characters(let value): return value.graphql("characters")
        case .staff(let value): return value.graphql("staff")
        case .studios(let value): return value.graphql("studios")
        case .isFavourite: return "isFavourite"
        case .isAdult: return "isAdult"
        case .nextAiringEpisode(let value): return value.graphql("nextAiringEpisode")
        case .airingSchedule(let value): return value.graphql("airingSchedule")
        case .externalLinks(let value): return value.graphql("externalLinks")
        case .streamingEpisodes(let value): return value.graphql("streamingEpisodes")
        case .rankings(let value): return value.graphql("rankings")
        case .recommendations(let value): return value.graphql("recommendations")
        case .stats(let value): return value.graphql("stats")
        case .siteUrl: return "siteUrl"
        }
    }
}

enum AnilistMediaTitleOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case romaji
    case native
    case english
    case userPreferred

    var rawValue: String {
        switch self {
        case .romaji: return "romaji"
        case .native: return "native"
        case .english: return "english"
        case .userPreferred: return "userPreferred"
        }
    }
}

enum AnilistFuzzyDateOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case year
    case month
    case day

    var rawValue: String {
        switch self {
        case .year: return "year"
        case .month: return "month"
        case .day: return "day"
        }
    }
}

enum AnilistTrailerOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case site
    case thumbnail

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .site: return "site"
        case .thumbnail: return "thumbnail"
        }
    }
}

enum AnilistMediaCoverImageOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case extraLarge
    case large
    case medium
    case color

    var rawValue: String {
        switch self {
        case .extraLarge: return "extraLarge"
        case .large: return "large"
        case .medium: return "medium"
        case .color: return "color"
        }
    }
}

enum AnilistMediaTagOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case name
    case description
    case category
    case rank
    case isGeneralSpoiler
    case isMediaSpoiler
    case isAdult
    case userId

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .name: return "name"
        case .description: return "description"
        case .category: return "category"
        case .rank: return "rank"
        case .isGeneralSpoiler: return "isGeneralSpoiler"
        case .isMediaSpoiler: return "isMediaSpoiler"
        case .isAdult: return "isAdult"
        case .userId: return "userId"
        }
    }
}

enum AnilistCharacterOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case name([AnilistCharacterNameOutput])
    case image([AnilistCharacterImageOutput])

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .name(let value): return value.graphql("name")
        case .image(let value): return value.graphql("image")
        }
    }
}

enum AnilistCharacterNameOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case first
    case middle
    case last
    case full
    case native
    case alternative
    case alternativeSpoiler
    case userPreferred

    var rawValue: String {
        switch self {
        case .first: return "first"
        case .middle: return "middle"
        case .last: return "last"
        case .full: return "full"
        case .native: return "native"
        case .alternative: return "alternative"
        case .alternativeSpoiler: return "alternativeSpoiler"
        case .userPreferred: return "userPreferred"
        }
    }
}

enum AnilistCharacterImageOutput: StringRepresentable, Sendable {
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

enum AnilistStaffOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case name([AnilistStaffNameOutput])
    case image([AnilistStaffImageOutput])

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .name(let value): return value.graphql("name")
        case .image(let value): return value.graphql("image")
        }
    }
}

enum AnilistStaffNameOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case first
    case middle
    case last
    case full
    case native
    case alternative
    case alternativeSpoiler
    case userPreferred

    var rawValue: String {
        switch self {
        case .first: return "first"
        case .middle: return "middle"
        case .last: return "last"
        case .full: return "full"
        case .native: return "native"
        case .alternative: return "alternative"
        case .alternativeSpoiler: return "alternativeSpoiler"
        case .userPreferred: return "userPreferred"
        }
    }
}

enum AnilistStaffImageOutput: StringRepresentable, Sendable {
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

enum AnilistStudioOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case id
    case name
    case isAnimationStudio

    var rawValue: String {
        switch self {
        case .id: return "id"
        case .name: return "name"
        case .isAnimationStudio: return "isAnimationStudio"
        }
    }
}

enum AnilistAiringScheduleOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case airingAt
    case timeUntilAiring
    case episode

    var rawValue: String {
        switch self {
        case .airingAt: return "airingAt"
        case .timeUntilAiring: return "timeUntilAiring"
        case .episode: return "episode"
        }
    }
}

enum AnilistMediaExternalLinkOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case url

    var rawValue: String {
        switch self {
        case .url: return "url"
        }
    }
}

enum AnilistMediaStreamingEpisodeOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case title
    case thumbnail
    case url
    case site

    var rawValue: String {
        switch self {
        case .title: return "title"
        case .thumbnail: return "thumbnail"
        case .url: return "url"
        case .site: return "site"
        }
    }
}

enum AnilistMediaRankOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case rank
    case type
    case context
    case year
    case season

    var rawValue: String {
        switch self {
        case .rank: return "rank"
        case .type: return "type"
        case .context: return "context"
        case .year: return "year"
        case .season: return "season"
        }
    }
}

enum AnilistRecommendationOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case mediaRecommendation([AnilistEntryOutput])

    var rawValue: String {
        switch self {
        case .mediaRecommendation(let value): return value.graphql("mediaRecommendation")
        }
    }
}

enum AnilistMediaStatsOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case scoreDistribution([AnilistScoreDistributionOutput])
    case statusDistribution([AnilistStatusDistributionOutput])

    var rawValue: String {
        switch self {
        case .scoreDistribution(let value): return value.graphql("scoreDistribution")
        case .statusDistribution(let value): return value.graphql("statusDistribution")
        }
    }
}

enum AnilistScoreDistributionOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case score
    case amount

    var rawValue: String {
        switch self {
        case .score: return "score"
        case .amount: return "amount"
        }
    }
}

enum AnilistStatusDistributionOutput: StringRepresentable, Sendable {
    init?(rawValue: String) { nil }

    case status
    case amount

    var rawValue: String {
        switch self {
        case .status: return "status"
        case .amount: return "amount"
        }
    }
}
