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
    let chapter: Float
    let volume: Float?
    let translator: String?
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
