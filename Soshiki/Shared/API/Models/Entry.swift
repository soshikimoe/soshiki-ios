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

struct Entry: Codable {
    let _id: String
    let mediaType: MediaType
    let title: String
    let alternativeTitles: [Entry.AlternativeTitle]
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

    enum ImageQuality: String, Codable {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
        case full = "FULL"
        case unknown = "UNKNOWN"
    }

    enum ContentRating: String, Codable {
        case safe = "SAFE"
        case suggestive = "SUGGESTIVE"
        case nsfw = "NSFW"
        case unknown = "UNKNOWN"
    }

    enum Status: String, Codable {
        case completed = "COMPLETED"
        case releasing = "RELEASING"
        case unreleased = "UNRELEASED"
        case hiatus = "HIATUS"
        case cancelled = "CANCELLED"
        case unknown = "UNKNOWN"
    }

    struct Tag: Codable {
        let name: String
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

    struct Source: Codable {
        let id: String
        let name: String
        let entryId: String
        let user: String?
    }

    struct Tracker: Codable {
        let id: String
        let name: String
        let entryId: String
    }

    func toUnifiedEntry() -> UnifiedEntry {
        UnifiedEntry(
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
            description: nil
        )
    }
}
