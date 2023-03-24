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

    func startup() {
        let sourcesDirectory = FileManager.default.documentDirectory.appendingPathComponent("Sources")
        if !FileManager.default.fileExists(atPath: sourcesDirectory.path) {
            guard (try? FileManager.default.createDirectory(at: sourcesDirectory, withIntermediateDirectories: true)) != nil else { return }
        }
        guard let sources = try? FileManager.default.contentsOfDirectory(at: sourcesDirectory, includingPropertiesForKeys: nil) else { return }
        for source in sources {
            if let source = JSSource.load(directory: source) {
                self.sources.append(source)
            }
        }
    }

    func installSource(_ url: URL) async {
        guard let temporaryDirectory = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                                    in: .userDomainMask,
                                                                    appropriateFor: FileManager.default.documentDirectory,
                                                                    create: true) else { return }
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
        if let manifest = JSSource.manifest(directory: temporaryDirectory) {
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
            if let source = JSSource.load(directory: sourceDirectory) {
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
        for source in sourceList.text {
            await installSource(url.deletingLastPathComponent().appendingPathComponent(source.path))
        }
        for source in sourceList.image {
            await installSource(url.deletingLastPathComponent().appendingPathComponent(source.path))
        }
        for source in sourceList.video {
            await installSource(url.deletingLastPathComponent().appendingPathComponent(source.path))
        }
    }
}

extension SourceManager {
    class Keys {
        static let update = "app.sources.update"
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

struct SourceListManifest: Codable {
    let text: [SourceListSourceManifest]
    let image: [SourceListSourceManifest]
    let video: [SourceListSourceManifest]
}

struct SourceListSourceManifest: Codable {
    let path: String
    let id: String
    let name: String
    let author: String
    let icon: String
    let version: String
    let type: String
    let schema: Int
}
