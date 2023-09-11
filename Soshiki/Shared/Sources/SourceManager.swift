//
//  SourceManager.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/23/22.
//

import Foundation
import ZIPFoundation
import JavaScriptCore

class SourceManager {
    static let shared = SourceManager()

    let context = JSContext()!

    @MainActor var sourceLists: [String] {
        var lists: [String] = []
        for source in DataManager.shared.getSources() as [TextSourceManifest] {
            if let baseUrl = source.baseUrl, !lists.contains(baseUrl) {
                lists.append(baseUrl)
            }
        }
        for source in DataManager.shared.getSources() as [ImageSourceManifest] {
            if let baseUrl = source.baseUrl, !lists.contains(baseUrl) {
                lists.append(baseUrl)
            }
        }
        for source in DataManager.shared.getSources() as [VideoSourceManifest] {
            if let baseUrl = source.baseUrl, !lists.contains(baseUrl) {
                lists.append(baseUrl)
            }
        }
        return lists
    }

    var sources: [any Source] = []

    var textSources: [any TextSource] {
        sources.compactMap({ $0 as? any TextSource })
    }
    var imageSources: [any ImageSource] {
        sources.compactMap({ $0 as? any ImageSource })
    }
    var videoSources: [any VideoSource] {
        sources.compactMap({ $0 as? any VideoSource })
    }

    @MainActor var uninstalledTextSources: [TextSourceManifest] {
        let existingTextSources = self.textSources
        return DataManager.shared.realm.objects(TextSourceManifest.self).filter({ manifest in
            !existingTextSources.contains(where: { $0.id == manifest.id })
        })
    }
    @MainActor var uninstalledImageSources: [ImageSourceManifest] {
        let existingImageSources = self.imageSources
        return DataManager.shared.realm.objects(ImageSourceManifest.self).filter({ manifest in
            !existingImageSources.contains(where: { $0.id == manifest.id })
        })
    }
    @MainActor var uninstalledVideoSources: [VideoSourceManifest] {
        let existingVideoSources = self.videoSources
        return DataManager.shared.getSources().filter({ manifest in
            !existingVideoSources.contains(where: { $0.id == manifest.id })
        })
    }

    func sources(ofType mediaType: MediaType) -> [any Source] {
        mediaType == .text
            ? self.sources.filter({ $0 is any TextSource })
            : mediaType == .image ? self.sources.filter({ $0 is any ImageSource }) : self.sources.filter({ $0 is any VideoSource })
    }

    func startup() {
        injectDependencies()

        let sourcesDirectory = FileManager.default.documentDirectory.appendingPathComponent("Sources")
        if !FileManager.default.fileExists(atPath: sourcesDirectory.path) {
            guard (try? FileManager.default.createDirectory(at: sourcesDirectory, withIntermediateDirectories: true)) != nil else { return }
        }
        guard let sources = try? FileManager.default.contentsOfDirectory(at: sourcesDirectory, includingPropertiesForKeys: nil) else { return }
        for source in sources {
            if let source = SourceManager.load(directory: source, context: context) {
                self.sources.append(source)
            }
        }
    }

    func installSource(_ url: URL) async {
        guard let temporaryDirectory = try? FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: FileManager.default.documentDirectory,
            create: true
        ) else { return }
        var url = url
        var shouldRemoveFile = false
        if url.isFileURL {
            guard url.startAccessingSecurityScopedResource() else { return }
        } else {
            guard let newUrl = try? await URLSession.shared.download(from: url).0 else { return }
            url = newUrl
            shouldRemoveFile = true
        }
        defer {
            _ = try? FileManager.default.removeItem(at: temporaryDirectory)
            url.stopAccessingSecurityScopedResource()
            if shouldRemoveFile {
                _ = try? FileManager.default.removeItem(at: url)
            }
        }
        guard (try? FileManager.default.unzipItem(at: url, to: temporaryDirectory)) != nil else { return }
        if let manifest = SourceManager.manifest(directory: temporaryDirectory), (manifest.schema ?? 0) >= 2 {
            let sourcesDirectory = FileManager.default.documentDirectory.appendingPathComponent("Sources", conformingTo: .folder)
            if !FileManager.default.fileExists(atPath: sourcesDirectory.path) {
                guard (try? FileManager.default.createDirectory(at: sourcesDirectory, withIntermediateDirectories: true)) != nil else { return }
            }
            let sourceDirectory = sourcesDirectory.appendingPathComponent(manifest.id, conformingTo: .folder)
            guard let items = try? FileManager.default.contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: nil) else { return }
            if FileManager.default.fileExists(atPath: sourceDirectory.path) {
                guard (try? FileManager.default.removeItem(at: sourceDirectory)) != nil else { return }
                sources.removeAll(where: { $0.id == manifest.id })
            }
            guard (try? FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)) != nil else { return }
            for item in items {
                _ = try? FileManager.default.moveItem(at: item, to: sourceDirectory.appendingPathComponent(item.lastPathComponent))
            }
            if let source = SourceManager.load(directory: sourceDirectory, context: context) {
                self.sources.append(source)
                NotificationCenter.default.post(name: .init(SourceManager.Keys.update), object: nil)
            }
        }
    }

    func removeSource(id: String) {
        let sourcesDirectory = FileManager.default.documentDirectory.appendingPathComponent("Sources", conformingTo: .folder)
        if !FileManager.default.fileExists(atPath: sourcesDirectory.path) { return }
        let sourceDirectory = sourcesDirectory.appendingPathComponent(id, conformingTo: .folder)
        guard (try? FileManager.default.removeItem(at: sourceDirectory)) != nil else { return }
        self.sources.removeAll(where: { $0.id == id })
        NotificationCenter.default.post(name: .init(SourceManager.Keys.update), object: nil)
    }

    func installSources(_ url: URL) async {
        guard let (sourceListData, _) = try? await URLSession.shared.data(from: url),
              let sourceList = try? JSONDecoder().decode(SourceListManifest.self, from: sourceListData) else { return }

        let baseUrl = url.deletingLastPathComponent()

        Task { @MainActor in
            let existingTextSources: [TextSourceManifest] = DataManager.shared.getSources()
            let existingImageSources: [ImageSourceManifest] = DataManager.shared.getSources()
            let existingVideoSources: [VideoSourceManifest] = DataManager.shared.getSources()
            for source in sourceList.text {
                source.baseUrl = baseUrl.absoluteString
                if let existingSource = existingTextSources.first(where: { $0.id == source.id }) {
                    if existingSource.version.versionCompare(source.version) != .orderedDescending {
                        DataManager.shared.removeSource(existingSource)
                        DataManager.shared.addSource(source)
                    }
                } else {
                    DataManager.shared.addSource(source)
                }
            }
            for source in sourceList.image {
                source.baseUrl = baseUrl.absoluteString
                if let existingSource = existingImageSources.first(where: { $0.id == source.id }) {
                    if existingSource.version.versionCompare(source.version) != .orderedDescending {
                        DataManager.shared.removeSource(existingSource)
                        DataManager.shared.addSource(source)
                    }
                } else {
                    DataManager.shared.addSource(source)
                }
            }
            for source in sourceList.video {
                source.baseUrl = baseUrl.absoluteString
                if let existingSource = existingVideoSources.first(where: { $0.id == source.id }) {
                    if existingSource.version.versionCompare(source.version) != .orderedDescending {
                        DataManager.shared.removeSource(existingSource)
                        DataManager.shared.addSource(source)
                    }
                } else {
                    DataManager.shared.addSource(source)
                }
            }
        }
        NotificationCenter.default.post(name: .init(SourceManager.Keys.update), object: nil)
    }

    func injectDependencies() {
        context.exceptionHandler = { _, value in
            let stacktrace = value?.objectForKeyedSubscript("stack").toString() ?? ""
            let lineNumber = value?.objectForKeyedSubscript("line").toNumber() ?? -1
            let column = value?.objectForKeyedSubscript("column").toNumber() ?? -1
            let info = "in method \(stacktrace)Line number in file: \(lineNumber), column: \(column)"
            LogManager.shared.log("JSContext ERROR: \(String(describing: value)) \(info)", at: .error)
        }

        context.objectForKeyedSubscript("console").setObject({ value in
            LogManager.shared.log("JSContext LOG: \(value.toString() ?? "")", at: .info)
        } as @convention(block) (JSValue) -> Void, forKeyedSubscript: "log")
        context.objectForKeyedSubscript("console").setObject({ value in
            LogManager.shared.log("JSContext WARN: \(value.toString() ?? "")", at: .warn)
        } as @convention(block) (JSValue) -> Void, forKeyedSubscript: "warn")
        context.objectForKeyedSubscript("console").setObject({ value in
            LogManager.shared.log("JSContext ERROR: \(value.toString() ?? "")", at: .error)
        } as @convention(block) (JSValue) -> Void, forKeyedSubscript: "error")
        JSFetch.inject(into: context)
        JSDom.inject(into: context)

        context.objectForKeyedSubscript("globalThis").setObject({ key, id in
            guard let key = key.toString(), let id = id.toString() else { return nil }
            return UserDefaults.standard.value(forKey: "settings.source.\(id).\(key)")
        } as @convention(block) (JSValue, JSValue) -> Any?, forKeyedSubscript: "getSettingsValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key, id in
            guard let key = key.toString(), let id = id.toString() else { return nil }
            return UserDefaults.standard.value(forKey: "storage.source.\(id).\(key)")
        } as @convention(block) (JSValue, JSValue) -> Any?, forKeyedSubscript: "getStorageValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key, value, id in
            guard let key = key.toString(), let id = id.toString() else { return }
            UserDefaults.standard.set(value.toObject(), forKey: "storage.source.\(id).\(key)")
        } as @convention(block) (JSValue, JSValue, JSValue) -> Void, forKeyedSubscript: "setStorageValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key, id in
            guard let key = key.toString(), let id = id.toString() else { return nil }
            return KeychainManager.shared.get("keychain.source.\(id).\(key)")
        } as @convention(block) (JSValue, JSValue) -> String?, forKeyedSubscript: "getKeychainValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key, value, id in
            guard let key = key.toString(), let value = value.toString(), let id = id.toString() else { return }
            KeychainManager.shared.set(value, forKey: "keychain.source.\(id).\(key)")
        } as @convention(block) (JSValue, JSValue, JSValue) -> Void, forKeyedSubscript: "setKeychainValue")
    }

    static func load(directory: URL, context: JSContext? = nil) -> (any JSSource)? {
        let manifestFile = directory.appendingPathComponent("manifest.json", conformingTo: .json)
        guard let manifestData = try? Data(contentsOf: manifestFile),
              let manifest = try? JSONDecoder().decode(_SourceManifest.self, from: manifestData) else { return nil }

        let sourceFile = directory.appendingPathComponent("source.js", conformingTo: .javaScript)
        guard let sourceData = try? Data(contentsOf: sourceFile),
              let script = String(data: sourceData, encoding: .utf8) else { return nil }

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

        switch manifest.type.lowercased() {
        case "text": return JSTextSource(
            id: manifest.id,
            name: manifest.name,
            author: manifest.author,
            version: manifest.version,
            image: image,
            context: context
        )
        case "image": return JSImageSource(
            id: manifest.id,
            name: manifest.name,
            author: manifest.author,
            version: manifest.version,
            image: image,
            context: context
        )
        case "video": return JSVideoSource(
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

    static func manifest(directory: URL) -> _SourceManifest? {
        let manifestFile = directory.appendingPathComponent("manifest.json", conformingTo: .json)
        guard let manifestData = try? Data(contentsOf: manifestFile),
              let manifest = try? JSONDecoder().decode(_SourceManifest.self, from: manifestData) else { return nil }
        return manifest
    }
}

extension SourceManager {
    class Keys {
        static let update = "app.sources.update"
    }
}

struct _SourceManifest: Codable {
    let id: String
    let name: String
    let author: String
    let icon: String
    let version: String
    let type: String
    let schema: Int?
}

struct SourceListManifest: Codable {
    let text: [TextSourceManifest]
    let image: [ImageSourceManifest]
    let video: [VideoSourceManifest]
}

struct SourceListSourceManifest: Codable {
    let path: String
    let id: String
    let name: String
    let author: String
    let icon: String
    let version: String
    let type: String
    let schema: Int?
}
