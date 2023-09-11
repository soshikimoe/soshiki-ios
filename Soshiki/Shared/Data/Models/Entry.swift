//
//  Entry.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/4/23.
//

import Foundation
import RealmSwift
import Unrealm

enum MediaType: String, RealmableEnumString, Codable, StringRepresentable, Sendable, CaseIterable, Equatable {
    case text = "TEXT"
    case image = "IMAGE"
    case video = "VIDEO"
}

protocol Entry: Realmable, Codable, Hashable {
    associatedtype HistoryType: History

    var id: String { get }
    var sourceId: String { get }
    var title: String { get }
    var alternativeTitles: [String] { get }
    var cover: String? { get }
    var alternativeCovers: [String] { get }
    var banner: String? { get }
    var alternativeBanners: [String] { get }
    var tags: [String] { get }
    var synopsis: String? { get }
    var contentRating: ContentRating { get }
    var status: Status { get }
    var score: Double? { get }
    var year: Int? { get }
    var links: [String] { get }
}

enum ContentRating: String, RealmableEnumString, Codable {
    case safe = "SAFE"
    case suggestive = "SUGGESTIVE"
    case nsfw = "NSFW"
    case unknown = "UNKNOWN"
}

enum Status: String, RealmableEnumString, Codable {
    case completed = "COMPLETED"
    case releasing = "RELEASING"
    case unreleased = "UNRELEASED"
    case hiatus = "HIATUS"
    case cancelled = "CANCELLED"
    case unknown = "UNKNOWN"
}

enum EntrySeason: String, RealmableEnumString, Codable {
    case winter = "WINTER"
    case spring = "SPRING"
    case summer = "SUMMER"
    case fall = "FALL"
    case unknown = "UNKNOWN"
}

final class TextEntry: Realmable, Entry, Codable, Hashable {
    typealias HistoryType = TextHistory

    init() {}

    internal init(
        uuid: String,
        id: String,
        sourceId: String,
        title: String,
        alternativeTitles: [String],
        author: String?,
        cover: String?,
        alternativeCovers: [String],
        banner: String?,
        alternativeBanners: [String],
        tags: [String],
        synopsis: String?,
        contentRating: ContentRating,
        status: Status,
        score: Double?,
        year: Int?,
        chapters: Double?,
        links: [String]
    ) {
        self.uuid = uuid
        self.id = id
        self.sourceId = sourceId
        self.title = title
        self.alternativeTitles = alternativeTitles
        self.author = author
        self.cover = cover
        self.alternativeCovers = alternativeCovers
        self.banner = banner
        self.alternativeBanners = alternativeBanners
        self.tags = tags
        self.synopsis = synopsis
        self.contentRating = contentRating
        self.status = status
        self.score = score
        self.year = year
        self.chapters = chapters
        self.links = links
    }

    var uuid: String = UUID().uuidString
    var id: String = ""
    var sourceId: String = ""
    var title: String = ""
    var alternativeTitles: [String] = []
    var author: String?
    var cover: String?
    var alternativeCovers: [String] = []
    var banner: String?
    var alternativeBanners: [String] = []
    var tags: [String] = []
    var synopsis: String?
    var contentRating: ContentRating = .unknown
    var status: Status = .unknown
    var score: Double?
    var year: Int?
    var chapters: Double?
    var links: [String] = []

    private enum CodingKeys: String, CodingKey {
        case id, sourceId, title, alternativeTitles, author, cover, alternativeCovers, banner, alternativeBanners, tags, synopsis,
             contentRating, status, score, year, chapters, links
    }

    static func primaryKey() -> String? { "uuid" }

    static func == (lhs: TextEntry, rhs: TextEntry) -> Bool {
        lhs.id == rhs.id && lhs.sourceId == rhs.sourceId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.sourceId)
    }
}

final class ImageEntry: Realmable, Entry, Codable {
    typealias HistoryType = ImageHistory

    init() {}

    internal init(
        uuid: String,
        id: String,
        sourceId: String,
        title: String,
        alternativeTitles: [String],
        author: String?,
        artist: String?,
        cover: String?,
        alternativeCovers: [String],
        banner: String?,
        alternativeBanners: [String],
        tags: [String],
        synopsis: String?,
        contentRating: ContentRating,
        status: Status,
        score: Double?,
        year: Int?,
        chapters: Double?,
        links: [String]
    ) {
        self.uuid = uuid
        self.id = id
        self.sourceId = sourceId
        self.title = title
        self.alternativeTitles = alternativeTitles
        self.author = author
        self.artist = artist
        self.cover = cover
        self.alternativeCovers = alternativeCovers
        self.banner = banner
        self.alternativeBanners = alternativeBanners
        self.tags = tags
        self.synopsis = synopsis
        self.contentRating = contentRating
        self.status = status
        self.score = score
        self.year = year
        self.chapters = chapters
        self.links = links
    }

    var uuid: String = UUID().uuidString
    var id: String = ""
    var sourceId: String = ""
    var title: String = ""
    var alternativeTitles: [String] = []
    var author: String?
    var artist: String?
    var cover: String?
    var alternativeCovers: [String] = []
    var banner: String?
    var alternativeBanners: [String] = []
    var tags: [String] = []
    var synopsis: String?
    var contentRating: ContentRating = .unknown
    var status: Status = .unknown
    var score: Double?
    var year: Int?
    var chapters: Double?
    var links: [String] = []

    private enum CodingKeys: String, CodingKey {
        case id, sourceId, title, alternativeTitles, author, artist, cover, alternativeCovers, banner, alternativeBanners, tags, synopsis,
             contentRating, status, score, year, chapters, links
    }

    static func primaryKey() -> String? { "uuid" }

    static func == (lhs: ImageEntry, rhs: ImageEntry) -> Bool {
        lhs.id == rhs.id && lhs.sourceId == rhs.sourceId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.sourceId)
    }
}

final class VideoEntry: Realmable, Entry, Codable {
    typealias HistoryType = VideoHistory

    init() {}

    internal init(
        uuid: String,
        id: String,
        sourceId: String,
        title: String,
        alternativeTitles: [String],
        cover: String?,
        alternativeCovers: [String],
        banner: String?,
        alternativeBanners: [String],
        tags: [String],
        synopsis: String?,
        contentRating: ContentRating,
        status: Status,
        score: Double?,
        season: EntrySeason,
        year: Int?,
        episodes: Double?,
        links: [String]
    ) {
        self.uuid = uuid
        self.id = id
        self.sourceId = sourceId
        self.title = title
        self.alternativeTitles = alternativeTitles
        self.cover = cover
        self.alternativeCovers = alternativeCovers
        self.banner = banner
        self.alternativeBanners = alternativeBanners
        self.tags = tags
        self.synopsis = synopsis
        self.contentRating = contentRating
        self.status = status
        self.score = score
        self.season = season
        self.year = year
        self.episodes = episodes
        self.links = links
    }

    var uuid: String = UUID().uuidString
    var id: String = ""
    var sourceId: String = ""
    var title: String = ""
    var alternativeTitles: [String] = []
    var cover: String?
    var alternativeCovers: [String] = []
    var banner: String?
    var alternativeBanners: [String] = []
    var tags: [String] = []
    var synopsis: String?
    var contentRating: ContentRating = .unknown
    var status: Status = .unknown
    var score: Double?
    var season: EntrySeason = .unknown
    var year: Int?
    var episodes: Double?
    var links: [String] = []

    private enum CodingKeys: String, CodingKey {
        case id, sourceId, title, alternativeTitles, cover, alternativeCovers, banner, alternativeBanners, tags, synopsis,
             contentRating, status, score, season, year, episodes, links
    }

    static func primaryKey() -> String? { "uuid" }

    static func == (lhs: VideoEntry, rhs: VideoEntry) -> Bool {
        lhs.id == rhs.id && lhs.sourceId == rhs.sourceId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.sourceId)
    }
}

struct Entry_Old: Codable, Hashable {
    let _id: String
    let mediaType: MediaType
    let title: String
    let alternativeTitles: [Entry_Old.AlternativeTitle]
    let description: String?
    let staff: [Entry_Old.Staff]
    let covers: [Entry_Old.Image]
    let color: String?
    let banners: [Entry_Old.Image]
    let score: Double?
    let contentRating: Entry_Old.ContentRating
    let status: Entry_Old.Status
    let tags: [Entry_Old.Tag]
    let links: [Entry_Old.Link]
    let platforms: [Entry_Old.Platform]
    let trackers: [Entry_Old.Tracker]
    let skipTimes: [Entry_Old.SkipTime]?

    struct AlternativeTitle: Codable {
        let title: String
        let type: String?
    }

    struct Staff: Codable {
        let name: String
        let role: String
        let image: String?
    }

    struct Image: Codable {
        let image: String
        let quality: Entry_Old.ImageQuality
    }

    enum ImageQuality: String, Codable, Comparable {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
        case full = "FULL"
        case unknown = "UNKNOWN"

        static func < (lhs: Entry_Old.ImageQuality, rhs: Entry_Old.ImageQuality) -> Bool {
            switch lhs {
            case .unknown: return rhs == .low || rhs == .medium || rhs == .high || rhs == .full
            case .low: return rhs == .medium || rhs == .high || rhs == .full
            case .medium: return rhs == .high || rhs == .full
            case .high: return rhs == .full
            case .full: return false
            }
        }
    }

    enum ContentRating: String, Codable {
        case safe = "SAFE"
        case suggestive = "SUGGESTIVE"
        case nsfw = "NSFW"
        case unknown = "UNKNOWN"

        func toSourceContentRating() -> SourceEntryContentRating {
            switch self {
            case .safe: return .safe
            case .suggestive: return .suggestive
            case .nsfw: return .nsfw
            case .unknown: return .safe
            }
        }
    }

    enum Status: String, Codable {
        case completed = "COMPLETED"
        case releasing = "RELEASING"
        case unreleased = "UNRELEASED"
        case hiatus = "HIATUS"
        case cancelled = "CANCELLED"
        case unknown = "UNKNOWN"

        func toSourceStatus() -> SourceEntryStatus {
            switch self {
            case .completed: return .completed
            case .releasing: return .ongoing
            case .unreleased: return .unknown
            case .hiatus: return .hiatus
            case .cancelled: return .dropped
            case .unknown: return .unknown
            }
        }
    }

    struct Tag: Codable, Hashable {
        let name: String

        static func == (lhs: Entry_Old.Tag, rhs: Entry_Old.Tag) -> Bool {
            lhs.name == rhs.name
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
    }

    struct Link: Codable {
        let site: String
        let url: String
    }

    struct Platform: Codable {
        let id: String
        let name: String
        let sources: [Entry_Old.Source]
    }

    struct Source: Codable, Equatable {
        let id: String
        let name: String
        let entryId: String
        let user: String?

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id && lhs.entryId == rhs.entryId
        }
    }

    struct Tracker: Codable {
        let id: String
        let name: String
        let entryId: String
    }

    struct SkipTime: Codable {
        let episode: Double
        let times: [SkipTimeItem]
    }

    struct SkipTimeItem: Codable {
        let type: SkipTimeItemType
        let start: Double
        let end: Double?
    }

    enum SkipTimeItemType: String, Codable {
        case intro = "Intro"
        case mixedIntro = "Mixed Intro"
        case newIntro = "New Intro"
        case canon = "Canon"
        case mustWatch = "Must Watch"
        case branding = "Branding"
        case recap = "Recap"
        case filler = "Filler"
        case transition = "Transition"
        case credits = "Credits"
        case mixedCredits = "Mixed Credits"
        case newCredits = "New Credits"
        case preview = "Preview"
        case titleCard = "Title Card"
        case unknown = "Unknown"

        func shouldSkip() -> Bool {
            [.intro, .mixedIntro, .newIntro, .recap, .filler, .credits, .mixedCredits, .newCredits, .preview].contains(self)
        }
    }

    func toLocalEntry() -> LocalEntry {
        LocalEntry(
            id: self._id,
            title: self.title,
            cover: self.covers.min(by: { cover1, cover2 in
                let priority = ["FULL", "HIGH", "UNKNOWN", "MEDIUM", "LOW"]
                return (priority.firstIndex(of: cover1.quality.rawValue) ?? 5) < (priority.firstIndex(of: cover2.quality.rawValue) ?? 5)
            })?.image ?? "",
            staff: staff.map({ $0.name }),
            tags: tags.map({ $0.name }),
            banner: self.banners.min(by: { banner1, banner2 in
                let priority = ["FULL", "HIGH", "UNKNOWN", "MEDIUM", "LOW"]
                return (priority.firstIndex(of: banner1.quality.rawValue) ?? 5) < (priority.firstIndex(of: banner2.quality.rawValue) ?? 5)
            })?.image,
            color: self.color,
            description: self.description
        )
    }

    static func == (lhs: Entry_Old, rhs: Entry_Old) -> Bool {
        lhs._id == rhs._id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self._id)
    }

    func toSourceEntry() -> SourceEntry {
        SourceEntry(
            id: self._id,
            title: self.title,
            staff: self.staff.map({ $0.name }),
            tags: self.tags.map({ $0.name }),
            cover: self.covers.max(by: { $0.quality < $1.quality })?.image ?? "",
            banner: self.banners.max(by: { $0.quality < $1.quality })?.image,
            nsfw: self.contentRating.toSourceContentRating(),
            status: self.status.toSourceStatus(),
            score: self.score,
            items: nil,
            season: nil,
            year: nil,
            url: self.links.first?.url ?? "",
            description: self.description ?? ""
        )
    }
}
