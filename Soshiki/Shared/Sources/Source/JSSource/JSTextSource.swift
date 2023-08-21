//
//  JSTextSource.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/15/23.
//

import Foundation
import JavaScriptCore

class JSTextSource: JSSource, TextSource {
    let id: String
    let name: String
    let author: String
    let version: String
    let image: URL
    let context: JSContext

    required init(id: String, name: String, author: String, version: String, image: URL, context: JSContext) {
        self.id = id
        self.name = name
        self.author = author
        self.version = version
        self.image = image
        self.context = context
    }

    func getListing(listing: SourceListing, page: Int) async -> SourceResults<TextEntry>? {
        await invokeAsyncMethod("_getListing", on: self.context.objectForKeyedSubscript(self.id), with: [ listing, page ])
    }

    func getSearchResults(query: String, page: Int, filters: [any SourceFilter]) async -> SourceResults<TextEntry>? {
        await invokeAsyncMethod(
            "_getSearchResults",
            on: self.context.objectForKeyedSubscript(self.id),
            with: [ query, page, filters.compactMap({ AnyEncodable(try? $0.toObject()) }) ]
        )
    }

    func getEntry(id: String) async -> TextEntry? {
        await invokeAsyncMethod("_getEntry", on: self.context.objectForKeyedSubscript(self.id), with: [ id ])
    }

    func getChapters(id: String, page: Int) async -> SourceResults<TextSourceChapter>? {
        await invokeAsyncMethod("_getChapters", on: self.context.objectForKeyedSubscript(self.id), with: [ id, page ])
    }

    func getChapterDetails(id: String, entryId: String) async -> TextSourceChapterDetails? {
        await invokeAsyncMethod("_getChapterDetails", on: self.context.objectForKeyedSubscript(self.id), with: [ id, entryId ])
    }

    static func == (lhs: JSTextSource, rhs: JSTextSource) -> Bool {
        lhs.id == rhs.id
    }
}
