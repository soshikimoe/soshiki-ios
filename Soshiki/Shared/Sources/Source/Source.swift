//
//  Source.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/21/22.
//

import Foundation
import JavaScriptCore

class Source: Identifiable, Equatable {
    let id: String
    let name: String
    let author: String
    let version: String
    let image: URL
    let context: JSContext

    static func load(directory: URL) -> Source? {
        let manifestFile = directory.appendingPathComponent("manifest.json", conformingTo: .json)
        guard let manifestData = try? Data(contentsOf: manifestFile),
              let manifest = try? JSONDecoder().decode(SourceManifest.self, from: manifestData) else { return nil }

        let sourceFile = directory.appendingPathComponent("source.js", conformingTo: .javaScript)
        guard let sourceData = try? Data(contentsOf: sourceFile),
              let script = String(data: sourceData, encoding: .utf8) else { return nil }

        guard let context = JSContext() else { return nil }
        context.objectForKeyedSubscript("console").setObject({ value in
            print("JSContext LOG - \(manifest.name) - \(value.toString() ?? "")")
        } as @convention(block) (JSValue) -> Void, forKeyedSubscript: "log")
        context.objectForKeyedSubscript("console").setObject({ value in
            print("JSContext WARN - \(manifest.name) - \(value.toString() ?? "")")
        } as @convention(block) (JSValue) -> Void, forKeyedSubscript: "warn")
        context.objectForKeyedSubscript("console").setObject({ value in
            print("JSContext ERROR - \(manifest.name) - \(value.toString() ?? "")")
        } as @convention(block) (JSValue) -> Void, forKeyedSubscript: "error")
        JSFetch.inject(into: context)
        JSDom.inject(into: context)

        context.objectForKeyedSubscript("globalThis").setObject({ key in
            guard let key = key.toString() else { return nil }
            return UserDefaults.standard.value(forKey: "settings.source.\(manifest.id).\(key)")
        } as @convention(block) (JSValue) -> Any?, forKeyedSubscript: "getSettingsValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key in
            guard let key = key.toString() else { return nil }
            return UserDefaults.standard.value(forKey: "storage.source.\(manifest.id).\(key)")
        } as @convention(block) (JSValue) -> Any?, forKeyedSubscript: "getStorageValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key, value in
            guard let key = key.toString() else { return }
            UserDefaults.standard.set(value.toObject(), forKey: key)
        } as @convention(block) (JSValue, JSValue) -> Void, forKeyedSubscript: "setStorageValue")

        context.evaluateScript(script)
        context.objectForKeyedSubscript("globalThis").setObject(
            context.objectForKeyedSubscript("globalThis")
                .objectForKeyedSubscript("__\(manifest.id)__")
                .objectForKeyedSubscript("default")
                .construct(withArguments: []),
            forKeyedSubscript: manifest.id
        )
        context.objectForKeyedSubscript("globalThis").setObject([:], forKeyedSubscript: "__callbacks__")

        let image = directory.appending(component: manifest.icon, directoryHint: .notDirectory)
        guard FileManager.default.fileExists(atPath: image.path) else { return nil }

        switch manifest.type.lowercased() {
        case "text": return TextSource(
            id: manifest.id,
            name: manifest.name,
            author: manifest.author,
            version: manifest.version,
            image: image,
            context: context
        )
        case "image": return ImageSource(
            id: manifest.id,
            name: manifest.name,
            author: manifest.author,
            version: manifest.version,
            image: image,
            context: context
        )
        case "video": return VideoSource(
            id: manifest.id,
            name: manifest.name,
            author: manifest.author,
            version: manifest.version,
            image: image,
            context: context
        )
        default: return nil
        }
    }

    static func manifest(directory: URL) -> SourceManifest? {
        let manifestFile = directory.appendingPathComponent("manifest.json", conformingTo: .json)
        guard let manifestData = try? Data(contentsOf: manifestFile),
              let manifest = try? JSONDecoder().decode(SourceManifest.self, from: manifestData) else { return nil }
        return manifest
    }

    init(id: String, name: String, author: String, version: String, image: URL, context: JSContext) {
        self.id = id
        self.name = name
        self.author = author
        self.version = version
        self.image = image
        self.context = context
    }

    func getListing(listing: SourceListing, previousResultsInfo: SourceEntryResultsInfo? = nil) async -> SourceEntryResults? {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: nil) }
            let callbackId = "getListingCallback_\(String.random())"
            let errorId = "getListingError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ [weak self] entryResults in
                guard let self = self else { return callback.resume(returning: nil) }
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let dict = entryResults.toDictionary() as? [String: Any],
                   let page = dict["page"] as? Int,
                   let hasMore = dict["hasMore"] as? Bool,
                   let entries = dict["entries"] as? [[String: String]] {
                    return callback.resume(returning: SourceEntryResults(
                        page: page,
                        hasMore: hasMore,
                        entries: entries.compactMap({ entry in
                            if let id = entry["id"],
                               let title = entry["title"],
                               let subtitle = entry["subtitle"],
                               let cover = entry["cover"] {
                                return SourceShortEntry(
                                    id: id,
                                    title: title,
                                    subtitle: subtitle,
                                    cover: cover
                                )
                            } else {
                                return nil
                            }
                        })
                    ))
                }
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                print(error.toString() ?? "JSContext Error")
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId),
                  let metadata = previousResultsInfo.flatMap({ JSValue(object: ["page": $0.page], in: context) }) ?? JSValue(nullIn: context)
            else {
                return callback.resume(returning: nil)
            }
            object.invokeMethod("_getListing", withArguments: [callbackValue, errorValue, metadata, listing.object])
        }
    }

    func getSearchResults(
        query: String,
        filters: [any SourceFilter],
        previousResultsInfo: SourceEntryResultsInfo? = nil
    ) async -> SourceEntryResults? {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: nil) }
            let callbackId = "getSearchResultsCallback_\(String.random())"
            let errorId = "getSearchResultsError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ [weak self] entryResults in
                guard let self = self else { return callback.resume(returning: nil) }
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let dict = entryResults.toDictionary() as? [String: Any],
                   let page = dict["page"] as? Int,
                   let hasMore = dict["hasMore"] as? Bool,
                   let entries = dict["entries"] as? [[String: String]] {
                    return callback.resume(returning: SourceEntryResults(
                        page: page,
                        hasMore: hasMore,
                        entries: entries.compactMap({ entry in
                            if let id = entry["id"],
                               let title = entry["title"],
                               let subtitle = entry["subtitle"],
                               let cover = entry["cover"] {
                                return SourceShortEntry(
                                    id: id,
                                    title: title,
                                    subtitle: subtitle,
                                    cover: cover
                                )
                            } else {
                                return nil
                            }
                        })
                    ))
                }
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                print(error.toString() ?? "JSContext Error")
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId),
                  let metadata = previousResultsInfo.flatMap({ JSValue(object: ["page": $0.page], in: context) }) ?? JSValue(nullIn: context)
            else {
                return callback.resume(returning: nil)
            }
            object.invokeMethod("_getSearchResults", withArguments: [callbackValue, errorValue, metadata, query, filters.map({ $0.object })])
        }
    }

    func getEntry(id: String) async -> SourceEntry? {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: nil) }
            let callbackId = "getEntryCallback_\(String.random())"
            let errorId = "getEntryError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ entry in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let dict = entry.toDictionary() as? [String: Any],
                   let id = dict["id"] as? String,
                   let title = dict["title"] as? String,
                   let staff = dict["staff"] as? [String],
                   let tags = dict["tags"] as? [String],
                   let cover = dict["cover"] as? String,
                   let nsfw = SourceEntryContentRating(rawValue: dict["nsfw"] as? String ?? ""),
                   let status = SourceEntryStatus(rawValue: dict["status"] as? String ?? ""),
                   let url = dict["url"] as? String,
                   let description = dict["description"] as? String {
                    return callback.resume(returning: SourceEntry(
                        id: id,
                        title: title,
                        staff: staff,
                        tags: tags,
                        cover: cover,
                        nsfw: nsfw,
                        status: status,
                        url: url,
                        description: description
                    ))
                }
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                print(error.toString() ?? "JSContext Error")
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: nil)
            }
            object.invokeMethod("_getEntry", withArguments: [callbackValue, errorValue, id])
        }
    }

    func getFilters() async -> [any SourceFilter] {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: []) }
            let callbackId = "getFiltersCallback_\(String.random())"
            let errorId = "getFiltersError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ filters in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let array = filters.toArray() as? [[String: Any]] {
                    return callback.resume(returning: array.compactMap({ filter in
                        if let type = filter["type"] as? String {
                            switch type {
                            case "text": return SourceTextFilter(from: filter)
                            case "toggle": return SourceToggleFilter(from: filter)
                            case "segment": return SourceSegmentFilter(from: filter)
                            case "select": return SourceSelectFilter(from: filter)
                            case "excludableSelect": return SourceExcludableSelectFilter(from: filter)
                            case "multiSelect": return SourceMultiSelectFilter(from: filter)
                            case "excludableMultiSelect": return SourceExcludableMultiSelectFilter(from: filter)
                            case "sort": return SourceSortFilter(from: filter)
                            case "ascendableSort": return SourceAscendableSortFilter(from: filter)
                            case "number": return SourceNumberFilter(from: filter)
                            case "range": return SourceRangeFilter(from: filter)
                            default: return nil
                            }
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
                print(error.toString() ?? "JSContext Error")
                return callback.resume(returning: [])
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: [])
            }
            object.invokeMethod("_getFilters", withArguments: [callbackValue, errorValue])
        }
    }

    func getListings() async -> [SourceListing] {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: []) }
            let callbackId = "getListingsCallback_\(String.random())"
            let errorId = "getListingsError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ filters in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let array = filters.toArray() as? [[String: Any]] {
                    return callback.resume(returning: array.compactMap({ SourceListing(from: $0) }))
                }
                return callback.resume(returning: [])
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                print(error.toString() ?? "JSContext Error")
                return callback.resume(returning: [])
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: [])
            }
            object.invokeMethod("_getListings", withArguments: [callbackValue, errorValue])
        }
    }

    func getSettings() async -> [any SourceFilter] {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: []) }
            let callbackId = "getSettingsCallback_\(String.random())"
            let errorId = "getSettingsError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ settings in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let array = settings.toArray() as? [[String: Any]] {
                    return callback.resume(returning: array.compactMap({ setting in
                        if let type = setting["type"] as? String {
                            switch type {
                            case "text": return SourceTextFilter(from: setting)
                            case "toggle": return SourceToggleFilter(from: setting)
                            case "segment": return SourceSegmentFilter(from: setting)
                            case "select": return SourceSelectFilter(from: setting)
                            case "excludableSelect": return SourceExcludableSelectFilter(from: setting)
                            case "multiSelect": return SourceMultiSelectFilter(from: setting)
                            case "excludableMultiSelect": return SourceExcludableMultiSelectFilter(from: setting)
                            case "sort": return SourceSortFilter(from: setting)
                            case "ascendableSort": return SourceAscendableSortFilter(from: setting)
                            case "number": return SourceNumberFilter(from: setting)
                            case "range": return SourceRangeFilter(from: setting)
                            default: return nil
                            }
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
                print(error.toString() ?? "JSContext Error")
                return callback.resume(returning: [])
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: [])
            }
            object.invokeMethod("_getSettings", withArguments: [callbackValue, errorValue])
        }
    }

    static func == (lhs: Source, rhs: Source) -> Bool {
        lhs.id == rhs.id && type(of: lhs) == type(of: rhs)
    }
}

struct SourceManifest: Codable {
    let id: String
    let name: String
    let author: String
    let icon: String
    let version: String
    let type: String
}
