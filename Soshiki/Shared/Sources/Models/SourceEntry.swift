//
//  SourceEntry.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/21/22.
//

enum SourceEntryStatus: String {
    case unknown = "UNKNOWN"
    case ongoing = "ONGOING"
    case completed = "COMPLETED"
    case dropped = "DROPPED"
    case hiatus = "HIATUS"
}

enum SourceEntryContentRating: String {
    case safe = "SAFE"
    case suggestive = "SUGGESTIVE"
    case nsfw = "NSFW"
}

struct SourceEntry: Hashable {
    let id: String
    let title: String
    let staff: [String]
    let tags: [String]
    let cover: String
    let nsfw: SourceEntryContentRating
    let status: SourceEntryStatus
    let url: String
    let description: String

    func toLocalEntry() -> LocalEntry {
        LocalEntry(
            id: self.id,
            title: self.title,
            cover: self.cover,
            staff: self.staff,
            tags: self.tags,
            banner: nil,
            color: nil,
            description: self.description
        )
    }

    static func == (lhs: SourceEntry, rhs: SourceEntry) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/*

 export type TextChapter = {
     id: string,
     entryId: string,
     name: string,
     chapter: number,
     volume: number,
 }

 export type ImageChapter = {
     id: string,
     entryId: string,
     name: string,
     chapter: number,
     volume: number
 }

 export type VideoEpisode = {
     id: string,
     entryId: string,
     name: string,
     episode: number
 }

 export type TextChapterDetails = {
     id: string,
     entryId: string,
     text: string
 }

 export type ImageChapterDetails = {
     id: string,
     entryId: string,
     pages: ImageChapterPage[]
 }

 export type ImageChapterPage = {
     index: number,
     url: string,
     base64: string
 }

 export type VideoEpisodeDetails = {
     urls: VideoEpisodeUrl[]
 }

 export type VideoEpisodeUrl = {
     type: VideoEpisodeUrlType,
     url: string
 }

 export enum VideoEpisodeUrlType {
     hls = "HLS",
     video = "VIDEO"
 }
 */
