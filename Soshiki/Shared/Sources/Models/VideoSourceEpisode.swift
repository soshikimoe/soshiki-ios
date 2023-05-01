//
//  VideoSourceEpisode.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/1/23.
//

import Foundation

enum VideoSourceEpisodeType: String {
    case sub = "SUB"
    case dub = "DUB"
    case unknown = "UNKNOWN"
}

struct VideoSourceEpisode: Sendable {
    let id: String
    let entryId: String
    let name: String?
    let episode: Double
    let type: VideoSourceEpisodeType
    let thumbnail: String?
    let timestamp: Double?

    func toListString() -> String {
        let episodeString = "Episode \(episode.toTruncatedString())"
        let nameString: String = name.flatMap({ $0.isEmpty ? "" : ": \($0)" }) ?? ""
        return episodeString + nameString
    }

    func toSourceItem() -> SourceItem {
        SourceItem(
            id: self.id,
            number: self.episode,
            name: self.name,
            info: self.type.rawValue.capitalized,
            thumbnail: self.thumbnail,
            timestamp: self.timestamp,
            mediaType: .video
        )
    }
}

struct VideoSourceEpisodeDetails: Sendable {
    let id: String
    let entryId: String
    let providers: [VideoSourceEpisodeProvider]
}

struct VideoSourceEpisodeProvider: Sendable {
    let name: String
    let urls: [VideoSourceEpisodeUrl]
}

struct VideoSourceEpisodeUrl: Sendable {
    let type: VideoSourceEpisodeUrlType
    let url: String
    let quality: Double?
}

enum VideoSourceEpisodeUrlType: String {
    case hls = "HLS"
    case video = "VIDEO"
}
