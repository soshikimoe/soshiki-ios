//
//  Entry.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/4/23.
//

import Foundation

enum MediaType: String, Codable, StringRepresentable, Sendable, CaseIterable, Equatable {
    case text = "TEXT"
    case image = "IMAGE"
    case video = "VIDEO"
}

struct Entry: Codable, Hashable {
    let _id: String
    let mediaType: MediaType
    let title: String
    let alternativeTitles: [Entry.AlternativeTitle]
    let description: String?
    let staff: [Entry.Staff]
    let covers: [Entry.Image]
    let color: String?
    let banners: [Entry.Image]
    let score: Double?
    let contentRating: Entry.ContentRating
    let status: Entry.Status
    let tags: [Entry.Tag]
    let links: [Entry.Link]
    let platforms: [Entry.Platform]
    let trackers: [Entry.Tracker]
    let skipTimes: [Entry.SkipTime]?

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
        let quality: Entry.ImageQuality
    }

    enum ImageQuality: String, Codable, Comparable {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
        case full = "FULL"
        case unknown = "UNKNOWN"

        static func < (lhs: Entry.ImageQuality, rhs: Entry.ImageQuality) -> Bool {
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

        static func == (lhs: Entry.Tag, rhs: Entry.Tag) -> Bool {
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
        let sources: [Entry.Source]
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

    static func == (lhs: Entry, rhs: Entry) -> Bool {
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
