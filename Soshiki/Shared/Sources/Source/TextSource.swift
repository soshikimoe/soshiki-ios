//
//  TextSource.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/1/23.
//

import Foundation

protocol TextSource: Source {
    func getChapters(id: String) async -> [TextSourceChapter]
    func getChapterDetails(id: String, entryId: String) async -> TextSourceChapterDetails?
}
