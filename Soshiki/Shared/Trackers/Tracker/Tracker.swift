//
//  Tracker.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/6/23.
//

import JavaScriptCore

class Tracker {
    let id: String
    let name: String
    let author: String
    let version: String
    let image: URL
    let schema: Int
    let context: JSContext

    static func load(directory: URL, context: JSContext? = nil) -> Tracker? {
        let manifestFile = directory.appendingPathComponent("manifest.json", conformingTo: .json)
        guard let manifestData = try? Data(contentsOf: manifestFile),
              let manifest = try? JSONDecoder().decode(TrackerManifest.self, from: manifestData) else { return nil }

        let trackerFile = directory.appendingPathComponent("tracker.js", conformingTo: .javaScript)
        guard let trackerData = try? Data(contentsOf: trackerFile),
              let script = String(data: trackerData, encoding: .utf8) else { return nil }

        guard let context = context ?? JSContext() else { return nil }

        context.evaluateScript(script)
        context.objectForKeyedSubscript("globalThis").setObject(
            context.objectForKeyedSubscript("globalThis")
                .objectForKeyedSubscript("__\(manifest.id)__")
                .objectForKeyedSubscript("default")
                .construct(withArguments: []),
            forKeyedSubscript: manifest.id
        )
        context.objectForKeyedSubscript("globalThis").setObject([:], forKeyedSubscript: "__callbacks__")

        let image = directory.appendingPathComponent(manifest.icon)
        guard FileManager.default.fileExists(atPath: image.path) else { return nil }
        return Tracker(
            id: manifest.id,
            name: manifest.name,
            author: manifest.author,
            version: manifest.version,
            image: image,
            schema: manifest.schema ?? 1,
            context: context
        )
    }

    static func manifest(directory: URL) -> TrackerManifest? {
        let manifestFile = directory.appendingPathComponent("manifest.json", conformingTo: .json)
        guard let manifestData = try? Data(contentsOf: manifestFile),
              let manifest = try? JSONDecoder().decode(TrackerManifest.self, from: manifestData) else { return nil }
        return manifest
    }

    init(id: String, name: String, author: String, version: String, image: URL, schema: Int, context: JSContext) {
        self.id = id
        self.name = name
        self.author = author
        self.version = version
        self.image = image
        self.schema = schema
        self.context = context
    }

    func getAuthUrl() -> URL? {
        self.context.objectForKeyedSubscript(self.id)?.invokeMethod("_getAuthUrl", withArguments: []).toString().flatMap({ URL(string: $0) })
    }

    func logout() {
        self.context.objectForKeyedSubscript(self.id)?.invokeMethod("_logout", withArguments: [])
    }

    func handleResponse(url: URL) async {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: ()) }
            let callbackId = "handleResponseCallback_\(String.random())"
            let errorId = "handleResponseError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ [weak self] in
                guard let self = self else { return callback.resume(returning: ()) }
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                return callback.resume(returning: ())
            } as @convention(block) () -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                LogManager.shared.log(error.toString() ?? "JSContext Error", at: .error)
                return callback.resume(returning: ())
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: ())
            }
            object.invokeMethod("_handleResponse", withArguments: [callbackValue, errorValue, url.absoluteString])
        }
    }

//    func getSearchResults(
//        mediaType: MediaType,
//        query: String,
//        previousResultsInfo: SourceEntryResultsInfo? = nil
//    ) async -> SourceEntryResults? {
//        await withCheckedContinuation { [weak self] callback in
//            guard let self = self else { return callback.resume(returning: nil) }
//            let callbackId = "getSearchResultsCallback_\(String.random())"
//            let errorId = "getSearchResultsError_\(String.random())"
//            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ [weak self] entryResults in
//                guard let self = self else { return callback.resume(returning: nil) }
//                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
//                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
//                if let dict = entryResults.toDictionary() as? [String: Any],
//                   let page = dict["page"] as? Int,
//                   let hasMore = dict["hasMore"] as? Bool,
//                   let entries = dict["entries"] as? [[String: String]] {
//                    return callback.resume(returning: SourceEntryResults(
//                        page: page,
//                        hasMore: hasMore,
//                        entries: entries.compactMap({ entry in
//                            if let id = entry["id"],
//                               let title = entry["title"],
//                               let subtitle = entry["subtitle"],
//                               let cover = entry["cover"] {
//                                return SourceShortEntry(
//                                    id: id,
//                                    title: title,
//                                    subtitle: subtitle,
//                                    cover: cover
//                                )
//                            } else {
//                                return nil
//                            }
//                        })
//                    ))
//                }
//                return callback.resume(returning: nil)
//            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
//            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
//                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
//                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
//                LogManager.shared.log(error.toString() ?? "JSContext Error", at: .error)
//                return callback.resume(returning: nil)
//            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
//            guard let object = self.context.objectForKeyedSubscript(self.id),
//                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
//                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId),
//                  let metadata = previousResultsInfo.flatMap({ JSValue(object: ["page": $0.page], in: context) }) ?? JSValue(nullIn: context)
//            else {
//                return callback.resume(returning: nil)
//            }
//            object.invokeMethod("_getSearchResults", withArguments: [callbackValue, errorValue, metadata, mediaType.rawValue.uppercased(), query])
//        }
//    }

    func getHistory(mediaType: MediaType, id: String) async -> History_Old? {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: nil) }
            let callbackId = "getHistoryCallback_\(String.random())"
            let errorId = "getHistoryError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ [weak self] entryResults in
                guard let self = self else { return callback.resume(returning: nil) }
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let dict = entryResults.toDictionary() as? [String: Any],
                   let id = dict["id"] as? String,
                   let status = (dict["status"] as? String).flatMap({ History_Old.Status(rawValue: $0) }) {
                    return callback.resume(returning: History_Old(
                        id: id,
                        page: dict["page"] as? Int,
                        chapter: dict["chapter"] as? Double,
                        volume: dict["volume"] as? Double,
                        timestamp: dict["timestamp"] as? Int,
                        episode: dict["episode"] as? Double,
                        season: dict["season"] as? Double,
                        percent: dict["percent"] as? Double,
                        score: dict["score"] as? Double,
                        status: status
                    ))
                }
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                LogManager.shared.log(error.toString() ?? "JSContext Error", at: .error)
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: nil)
            }
            object.invokeMethod("_getHistory", withArguments: [callbackValue, errorValue, mediaType.rawValue.uppercased(), id])
        }
    }

    func setHistory(mediaType: MediaType, id: String, history: History_Old) async {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: ()) }
            let callbackId = "setHistoryCallback_\(String.random())"
            let errorId = "setHistoryError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ [weak self] in
                guard let self = self else { return callback.resume(returning: ()) }
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                return callback.resume(returning: ())
            } as @convention(block) () -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                LogManager.shared.log(error.toString() ?? "JSContext Error", at: .error)
                return callback.resume(returning: ())
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: ())
            }
            var dict: [String: Any] = ["id": history.id, "status": history.status.rawValue]
            if let page = history.page { dict["page"] = page }
            if let chapter = history.chapter { dict["chapter"] = chapter }
            if let volume = history.volume { dict["volume"] = volume }
            if let timestamp = history.timestamp { dict["timestamp"] = timestamp }
            if let episode = history.episode { dict["episode"] = episode }
            if let score = history.score { dict["score"] = score }
            object.invokeMethod("_setHistory", withArguments: [callbackValue, errorValue, mediaType.rawValue, id, dict])
        }
    }

    func deleteHistory(mediaType: MediaType, id: String) async {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: ()) }
            let callbackId = "deleteHistoryCallback_\(String.random())"
            let errorId = "deleteHistoryError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ [weak self] in
                guard let self = self else { return callback.resume(returning: ()) }
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                return callback.resume(returning: ())
            } as @convention(block) () -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                LogManager.shared.log(error.toString() ?? "JSContext Error", at: .error)
                return callback.resume(returning: ())
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: ())
            }
            object.invokeMethod("_deleteHistory", withArguments: [callbackValue, errorValue, mediaType.rawValue, id])
        }
    }

    func getSupportedMediaTypes() -> [MediaType] {
        (self.context.objectForKeyedSubscript(self.id)?.invokeMethod("getDiscoverSections", withArguments: []).toArray() as? [String])?.compactMap({
            MediaType(rawValue: $0.uppercased())
        }) ?? []
    }

    func getDiscoverEntries(mediaType: MediaType, category: String) async -> [SourceEntry] {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: []) }
            let callbackId = "getDiscoverEntriesCallback_\(String.random())"
            let errorId = "getDiscoverEntriesError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ entry in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let dict = entry.toArray() as? [[String: Any]] {
                    return callback.resume(returning: dict.compactMap({ entry in
                        if let id = entry["id"] as? String,
                           let title = entry["title"] as? String,
                           let staff = entry["staff"] as? [String],
                           let tags = entry["tags"] as? [String],
                           let cover = entry["cover"] as? String,
                           let nsfw = SourceEntryContentRating(rawValue: entry["nsfw"] as? String ?? ""),
                           let status = SourceEntryStatus(rawValue: entry["status"] as? String ?? ""),
                           let url = entry["url"] as? String,
                           let description = entry["description"] as? String {
                            return SourceEntry(
                                id: id,
                                title: title,
                                staff: staff,
                                tags: tags,
                                cover: cover,
                                banner: entry["banner"] as? String,
                                nsfw: nsfw,
                                status: status,
                                score: entry["score"] as? Double,
                                items: entry["items"] as? Int,
                                season: (entry["season"] as? String).flatMap({ SourceEntrySeason(rawValue: $0) }),
                                year: entry["year"] as? Int,
                                url: url,
                                description: description
                            )
                        } else {
                            return nil
                        }
                    }))
                }
                return callback.resume(returning: [])
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                LogManager.shared.log(error.toString() ?? "JSContext Error", at: .error)
                return callback.resume(returning: [])
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard self.schema >= 2,
                  let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: [])
            }
            object.invokeMethod("_getDiscoverEntries", withArguments: [callbackValue, errorValue, mediaType.rawValue, category])
        }
    }

//    func getSeeMoreEntries(
//        mediaType: MediaType,
//        category: String,
//        previousResultsInfo: SourceEntryResultsInfo? = nil
//    ) async -> SourceEntryResults? {
//        await withCheckedContinuation { [weak self] callback in
//            guard let self = self else { return callback.resume(returning: nil) }
//            let callbackId = "getSeeMoreEntriesCallback_\(String.random())"
//            let errorId = "getSeeeMoreEntriesError_\(String.random())"
//            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ [weak self] entryResults in
//                guard let self = self else { return callback.resume(returning: nil) }
//                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
//                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
//                if let dict = entryResults.toDictionary() as? [String: Any],
//                   let page = dict["page"] as? Int,
//                   let hasMore = dict["hasMore"] as? Bool,
//                   let entries = dict["entries"] as? [[String: String]] {
//                    return callback.resume(returning: SourceEntryResults(
//                        page: page,
//                        hasMore: hasMore,
//                        entries: entries.compactMap({ entry in
//                            if let id = entry["id"],
//                               let title = entry["title"],
//                               let subtitle = entry["subtitle"],
//                               let cover = entry["cover"] {
//                                return SourceShortEntry(
//                                    id: id,
//                                    title: title,
//                                    subtitle: subtitle,
//                                    cover: cover
//                                )
//                            } else {
//                                return nil
//                            }
//                        })
//                    ))
//                }
//                return callback.resume(returning: nil)
//            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
//            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
//                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
//                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
//                LogManager.shared.log(error.toString() ?? "JSContext Error", at: .error)
//                return callback.resume(returning: nil)
//            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
//            guard self.schema >= 2,
//                  let object = self.context.objectForKeyedSubscript(self.id),
//                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
//                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId),
//                  let metadata = previousResultsInfo.flatMap({ JSValue(object: ["page": $0.page], in: context) }) ?? JSValue(nullIn: context)
//            else {
//                return callback.resume(returning: nil)
//            }
//            object.invokeMethod("_getSeeMoreEntries", withArguments: [callbackValue, errorValue, metadata, mediaType.rawValue, category])
//        }
//    }

    func getDiscoverSections(mediaType: MediaType) -> [String] {
        self.context.objectForKeyedSubscript(self.id)?.invokeMethod("getDiscoverSections", withArguments: [
            mediaType.rawValue
        ]).toArray() as? [String] ?? []
    }

    func getItems(mediaType: MediaType, id: String) async -> [SourceItem] {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: []) }
            let callbackId = "getItemsCallback_\(String.random())"
            let errorId = "getItemsError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ entry in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let dict = entry.toArray() as? [[String: Any]] {
                    switch mediaType {
                    case .text, .image:
                        return callback.resume(returning: dict.compactMap({ chapter in
                            if let id = chapter["id"] as? String,
                               let chapterNumber = chapter["chapter"] as? Double {
                                return SourceItem(
                                    id: id,
                                    group: chapter["volume"] as? Double,
                                    number: chapterNumber,
                                    name: chapter["name"] as? String,
                                    info: nil,
                                    thumbnail: chapter["thumbnail"] as? String,
                                    timestamp: chapter["timestamp"] as? Double,
                                    mediaType: mediaType
                                )
                            } else {
                                return nil
                            }
                        }))
                    case .video:
                        return callback.resume(returning: dict.compactMap({ episode in
                            if let id = episode["id"] as? String,
                               let episodeNumber = episode["episode"] as? Double,
                               let type = (episode["type"] as? String).flatMap({ VideoSourceEpisodeType(rawValue: $0) }) {
                                return SourceItem(
                                    id: id,
                                    group: nil,
                                    number: episodeNumber,
                                    name: episode["name"] as? String,
                                    info: type.rawValue.capitalized,
                                    thumbnail: episode["thumbnail"] as? String,
                                    timestamp: episode["timestamp"] as? Double,
                                    mediaType: mediaType
                                )
                            } else {
                                return nil
                            }
                        }))
                    }
                }
                return callback.resume(returning: [])
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                LogManager.shared.log(error.toString() ?? "JSContext Error", at: .error)
                return callback.resume(returning: [])
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard self.schema >= 2,
                  let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: [])
            }
            object.invokeMethod("_getItems", withArguments: [callbackValue, errorValue, mediaType.rawValue, id])
        }
    }
}
