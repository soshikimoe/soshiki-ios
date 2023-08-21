//
//  JSVideoSource.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/15/23.
//

import Foundation
import JavaScriptCore

class JSVideoSource: JSSource, VideoSource {
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

    func getListing(listing: SourceListing, page: Int) async -> SourceResults<VideoEntry>? {
        await invokeAsyncMethod("_getListing", on: self.context.objectForKeyedSubscript(self.id), with: [ listing, page ])
    }

    func getSearchResults(query: String, page: Int, filters: [any SourceFilter]) async -> SourceResults<VideoEntry>? {
        await invokeAsyncMethod(
            "_getSearchResults",
            on: self.context.objectForKeyedSubscript(self.id),
            with: [ query, page, filters.compactMap({ AnyEncodable(try? $0.toObject()) }) ]
        )
    }

    func getEntry(id: String) async -> VideoEntry? {
        await invokeAsyncMethod("_getEntry", on: self.context.objectForKeyedSubscript(self.id), with: [ id ])
    }

    func getEpisodes(id: String, page: Int) async -> SourceResults<VideoSourceEpisode>? {
        await invokeAsyncMethod("_getEpisodes", on: self.context.objectForKeyedSubscript(self.id), with: [ id, page ])
    }

    func getEpisodeDetails(id: String, entryId: String) async -> VideoSourceEpisodeDetails? {
        await invokeAsyncMethod("_getEpisodeDetails", on: self.context.objectForKeyedSubscript(self.id), with: [ id, entryId ])
    }

    struct ModifiedRequest: Codable {
        let url: String
        let options: ModifiedRequestOptions?
    }

    struct ModifiedRequestOptions: Codable {
        let method: String?
        let headers: [String: String]?
        let body: String?
    }

    func modifyVideoRequest(request: URLRequest) async -> URLRequest? {
        guard let url = request.url?.absoluteString else { return nil }

        var options: [String: AnyEncodable] = [:]
        if let method = request.httpMethod {
            options["method"] = AnyEncodable(method)
        }
        if let headers = request.allHTTPHeaderFields {
            options["headers"] = AnyEncodable(headers)
        }
        if let body = request.httpBody.flatMap({ String(data: $0, encoding: .utf8) }) {
            options["body"] = AnyEncodable(body)
        }

        if let object: ModifiedRequest = await invokeAsyncMethod(
            "_modifyVideoRequest",
            on: self.context.objectForKeyedSubscript(self.id),
            with: [ url, options ]
        ) {
            if let url = URL(string: object.url) {
                var request = URLRequest(url: url)
                if let options = object.options {
                    if let method = options.method {
                        request.httpMethod = method
                    }
                    if let headers = options.headers {
                        for header in headers {
                            request.setValue(header.value, forHTTPHeaderField: header.key)
                        }
                    }
                    if let body = options.body {
                        request.httpBody = body.data(using: .utf8)
                    }
                }
                return request
            }
        }

        return nil
    }

    static func == (lhs: JSVideoSource, rhs: JSVideoSource) -> Bool {
        lhs.id == rhs.id
    }
}
