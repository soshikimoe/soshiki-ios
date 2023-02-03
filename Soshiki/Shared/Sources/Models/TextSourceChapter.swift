//
//  TextSourceChapter.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/15/23.
//

import Foundation

struct TextSourceChapter: Sendable {
    let id: String
    let entryId: String
    let name: String?
    let chapter: Double
    let volume: Double?
    let translator: String?

    func toListString() -> String {
        let volumeString = volume.flatMap({ !$0.isNaN ? "Volume \($0.toTruncatedString()) " : nil }) ?? ""
        let chapterString = "Chapter \(chapter.toTruncatedString())"
        let nameString: String = name.flatMap({ $0.isEmpty ? "" : ": \($0)" }) ?? ""
        return volumeString + chapterString + nameString
    }
}

struct TextSourceChapterDetails: Sendable {
    let id: String
    let entryId: String
    let html: String
    let baseUrl: String?
}
