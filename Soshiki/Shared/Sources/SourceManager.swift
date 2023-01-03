//
//  SourceManager.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/23/22.
//

import Foundation
import ZIPFoundation

class SourceManager: ObservableObject {
    static let shared = SourceManager()

    @Published var sources: [Source] = []

    func startup() {
        let sourcesDirectory = FileManager.default.documentDirectory.appending(component: "Sources")
        if !FileManager.default.fileExists(atPath: sourcesDirectory.path()) {
            guard (try? FileManager.default.createDirectory(at: sourcesDirectory, withIntermediateDirectories: true)) != nil else { return }
        }
        guard let sources = try? FileManager.default.contentsOfDirectory(at: sourcesDirectory, includingPropertiesForKeys: nil) else { return }
        for source in sources {
            if let source = Source.load(directory: source) {
                self.sources.append(source)
            }
        }
    }

    func installSource(_ url: URL) {
        guard let temporaryDirectory = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                                    in: .userDomainMask,
                                                                    appropriateFor: FileManager.default.documentDirectory,
                                                                    create: true) else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer {
            _ = try? FileManager.default.removeItem(at: temporaryDirectory)
            url.stopAccessingSecurityScopedResource()
        }
        guard (try? FileManager.default.unzipItem(at: url, to: temporaryDirectory)) != nil else { return }
        if let manifest = Source.manifest(directory: temporaryDirectory) {
            let sourcesDirectory = FileManager.default.documentDirectory.appendingPathComponent("Sources", conformingTo: .folder)
            if !FileManager.default.fileExists(atPath: sourcesDirectory.path) {
                guard (try? FileManager.default.createDirectory(at: sourcesDirectory, withIntermediateDirectories: true)) != nil else { return }
            }
            let sourceDirectory = sourcesDirectory.appendingPathComponent(manifest.id, conformingTo: .folder)
            guard let items = try? FileManager.default.contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: nil) else { return }
            if FileManager.default.fileExists(atPath: sourceDirectory.path) {
                guard (try? FileManager.default.removeItem(at: sourceDirectory)) != nil else { return }
            }
            guard (try? FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)) != nil else { return }
            for item in items {
                _ = try? FileManager.default.moveItem(at: item, to: sourceDirectory.appending(component: item.lastPathComponent))
            }
            if let source = Source.load(directory: sourceDirectory) {
                self.sources.append(source)
            }
        }
    }

    func removeSource(id: String) {
        let sourcesDirectory = FileManager.default.documentDirectory.appendingPathComponent("Sources", conformingTo: .folder)
        if !FileManager.default.fileExists(atPath: sourcesDirectory.path) { return }
        let sourceDirectory = sourcesDirectory.appendingPathComponent(id, conformingTo: .folder)
        guard (try? FileManager.default.removeItem(at: sourceDirectory)) != nil else { return }
        self.sources.removeAll(where: { $0.id == id })
    }

    func installSources(_ url: URL) {

    }
}
