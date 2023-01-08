//
//  ImageSourceChapter.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/2/22.
//

import Foundation

struct ImageSourceChapter: Sendable {
    let id: String
    let entryId: String
    let name: String?
    let chapter: Double
    let volume: Double?
    let translator: String?

    func toListString() -> String {
        let volumeString = volume.flatMap({ !$0.isNaN ? "Volume \($0.toTruncatedString()) " : nil }) ?? ""
        let chapterString = "Chapter \(chapter.toTruncatedString())"
        let nameString = name.flatMap({ ": \($0)" }) ?? ""
        return volumeString + chapterString + nameString
    }
}

struct ImageSourceChapterDetails: Sendable {
    let id: String
    let entryId: String
    let pages: [ImageSourceChapterPage]
}

struct ImageSourceChapterPage: Sendable {
    let index: Int
    let url: String?
    let base64: String?
}
