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
    let context: JSContext

    static func load(directory: URL) -> Tracker? {
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
            return UserDefaults.standard.value(forKey: "settings.tracker.\(manifest.id).\(key)")
        } as @convention(block) (JSValue) -> Any?, forKeyedSubscript: "getSettingsValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key in
            guard let key = key.toString() else { return nil }
            return UserDefaults.standard.value(forKey: "storage.tracker.\(manifest.id).\(key)")
        } as @convention(block) (JSValue) -> Any?, forKeyedSubscript: "getStorageValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key, value in
            guard let key = key.toString() else { return }
            UserDefaults.standard.set(value.toObject(), forKey: "storage.tracker.\(manifest.id).\(key)")
        } as @convention(block) (JSValue, JSValue) -> Void, forKeyedSubscript: "setStorageValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key in
            guard let key = key.toString() else { return nil }
            return KeychainManager.shared.get("keychain.tracker.\(manifest.id).\(key)")
        } as @convention(block) (JSValue) -> String?, forKeyedSubscript: "getKeychainValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key, value in
            guard let key = key.toString(), let value = value.toString() else { return }
            KeychainManager.shared.set(value, forKey: "keychain.tracker.\(manifest.id).\(key)")
        } as @convention(block) (JSValue, JSValue) -> Void, forKeyedSubscript: "setKeychainValue")

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
        return Tracker(
            id: manifest.id,
            name: manifest.name,
            author: manifest.author,
            version: manifest.version,
            image: image,
            context: context
        )
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

    var authUrl: URL? {
        self.context.objectForKeyedSubscript(self.id)?.objectForKeyedSubscript("authUrl")?.toString().flatMap({ URL(string: $0) })
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
                print(error.toString() ?? "JSContext Error")
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

    func getSearchResults(
        mediaType: MediaType,
        query: String,
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
            object.invokeMethod("_getSearchResults", withArguments: [callbackValue, errorValue, metadata, mediaType.rawValue.uppercased(), query])
        }
    }
}
