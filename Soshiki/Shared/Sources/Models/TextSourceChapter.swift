//
//  TextSourceChapter.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/15/23.
//

import Foundation

struct TextSourceChapter: Codable {
    let id: String
    let entryId: String
    let sourceId: String
    let name: String?
    let chapter: Double
    let volume: Double?
    let translator: String?
    let thumbnail: String?
    let timestamp: Double?

    func toListString() -> String {
        let volumeString = volume.flatMap({ !$0.isNaN ? "Volume \($0.toTruncatedString()) " : nil }) ?? ""
        let chapterString = "Chapter \(chapter.toTruncatedString())"
        let nameString: String = name.flatMap({ $0.isEmpty ? "" : ": \($0)" }) ?? ""
        return volumeString + chapterString + nameString
    }

    func toSourceItem() -> SourceItem {
        SourceItem(
            id: self.id,
            group: self.volume,
            number: self.chapter,
            name: self.name,
            info: self.translator,
            thumbnail: self.thumbnail,
            timestamp: self.timestamp,
            mediaType: .text
        )
    }
}

struct TextSourceChapterDetails: Codable {
    let id: String
    let entryId: String
    let html: String
    let baseUrl: String?
}
