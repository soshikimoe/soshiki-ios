//
//  VideoSourceEpisode.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/1/23.
//

import Foundation

enum VideoSourceEpisodeType: String, Codable {
    case sub = "SUB"
    case dub = "DUB"
    case unknown = "UNKNOWN"
}

struct VideoSourceEpisode: Codable {
    let id: String
    let entryId: String
    let sourceId: String
    let name: String?
    let episode: Double
    let season: Double?
    let type: VideoSourceEpisodeType
    let thumbnail: String?
    let timestamp: Double?

    func toListString() -> String {
        let seasonString = season.flatMap({ !$0.isNaN ? "Season \($0.toTruncatedString()) " : nil }) ?? ""
        let episodeString = "Episode \(episode.toTruncatedString())"
        let nameString: String = name.flatMap({ $0.isEmpty ? "" : ": \($0)" }) ?? ""
        return seasonString + episodeString + nameString
    }

    func toSourceItem() -> SourceItem {
        SourceItem(
            id: self.id,
            group: self.season,
            number: self.episode,
            name: self.name,
            info: self.type.rawValue.capitalized,
            thumbnail: self.thumbnail,
            timestamp: self.timestamp,
            mediaType: .video
        )
    }
}

struct VideoSourceEpisodeDetails: Codable {
    let id: String
    let entryId: String
    let providers: [VideoSourceEpisodeProvider]
}

struct VideoSourceEpisodeProvider: Codable {
    let name: String
    let urls: [VideoSourceEpisodeUrl]
}

struct VideoSourceEpisodeUrl: Codable {
    let url: String
    let subtitles: [VideoSourceEpisodeUrlSubtitle]?
    let quality: VideoSourceEpisodeUrlQuality
}

struct VideoSourceEpisodeUrlSubtitle: Codable {
    let name: String
    let url: String
    let language: String
}

enum VideoSourceEpisodeUrlQuality: Codable, Comparable {
    case quality(Double)
    case auto
    case unknown

    var quality: Double? {
        if case .quality(let quality) = self {
            return quality
        } else {
            return nil
        }
    }

    var qualityString: String {
        if case .quality(let quality) = self {
            return "\(quality.toTruncatedString())p"
        } else {
            return self == .auto ? "Auto" : "Unknown"
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if case .quality(let quality) = self {
            try container.encode(quality)
        } else if case .auto = self {
            try container.encode("AUTO")
        } else {
            try container.encode("UNKNOWN")
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let quality = try? container.decode(Double.self) {
            self = .quality(quality)
        } else {
            self = try container.decode(String.self) == "AUTO" ? .auto : .unknown
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if case .quality(let quality1) = lhs {
            if case .quality(let quality2) = rhs {
                return quality1 < quality2
            }
            return false
        }
        return true
    }
}
