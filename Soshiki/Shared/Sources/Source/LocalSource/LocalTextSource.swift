//
//  LocalTextSource.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/15/23.
//

import Foundation
import SwiftSoup

class LocalTextSource: TextSource, LocalSource {
    static let shared = LocalTextSource()

    let baseUrl = FileManager.default.documentDirectory.appendingPathComponent("Local/Text", conformingTo: .folder)
    let manifestUrl = FileManager.default.documentDirectory.appendingPathComponent("Local/Text/manifest.json")

    init() {
        if !FileManager.default.fileExists(atPath: baseUrl.path) {
            _ = try? FileManager.default.createDirectory(at: baseUrl, withIntermediateDirectories: true)
        }
        if !FileManager.default.fileExists(atPath: manifestUrl.path) {
            let manifest = Manifest()
            if let data = try? JSONEncoder().encode(manifest) {
                _ = try? data.write(to: manifestUrl)
            }
        }
    }

    let id = "local"

    let name = "Local"

    func getListing(listing: SourceListing, previousResultsInfo: SourceEntryResultsInfo?) async -> SourceEntryResults? {
        if let data = try? Data(contentsOf: manifestUrl), let manifest = try? JSONDecoder().decode(Manifest.self, from: data) {
            return SourceEntryResults(
                page: 1,
                hasMore: false,
                entries: manifest.map({
                    SourceShortEntry(
                        id: $0.id,
                        title: $0.entry.title,
                        subtitle: $0.entry.staff.first ?? "",
                        cover: $0.entry.cover
                    )
                })
            )
        } else {
            return nil
        }
    }

    func getSearchResults(query: String, filters: [any SourceFilter], previousResultsInfo: SourceEntryResultsInfo?) async -> SourceEntryResults? {
        if let data = try? Data(contentsOf: manifestUrl), let manifest = try? JSONDecoder().decode(Manifest.self, from: data) {
            return SourceEntryResults(
                page: 1,
                hasMore: false,
                entries: manifest.map({
                    SourceShortEntry(
                        id: $0.id,
                        title: $0.entry.title,
                        subtitle: $0.entry.staff.first ?? "",
                        cover: $0.entry.cover
                    )
                })
            )
        } else {
            return nil
        }
    }

    func getEntry(id: String) async -> SourceEntry? {
        guard let manifestData = try? Data(contentsOf: manifestUrl),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData),
              let entry = manifest.first(where: { $0.id == id })?.entry else { return nil }
        return nil
//        return SourceEntry(
//            id: id,
//            title: entry.title,
//            staff: entry.staff,
//            tags: [],
//            cover: entry.cover,
//            nsfw: .safe,
//            status: .unknown,
//            url: "",
//            description: ""
//        )
    }

    func getFilters() async -> [any SourceFilter] {
        []
    }

    func getListings() async -> [SourceListing] {
        []
    }

    func getSettings() async -> [any SourceFilter] {
        []
    }

    func getChapters(id: String) async -> [TextSourceChapter] {
        guard let manifestData = try? Data(contentsOf: manifestUrl),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData),
              let parts = manifest.first(where: { $0.id == id })?.parts else { return [] }
        return parts.sorted(by: { $0.number > $1.number }).map({ part in
            getEpubChapters(
                baseUrl.appendingPathComponent(id).appendingPathComponent(part.id),
                id: id,
                volume: part.number == -1 ? nil : part.number
            )
        }).flatMap({ $0 })
    }

    func getChapterDetails(id: String, entryId: String) async -> TextSourceChapterDetails? {
        guard let fileUrl = URL(string: id),
              let html = try? String(contentsOf: fileUrl) else { return nil }
        return TextSourceChapterDetails(
            id: id,
            entryId: entryId,
            html: html,
            baseUrl: fileUrl.deletingLastPathComponent().absoluteString
        )
    }

    static func == (lhs: LocalTextSource, rhs: LocalTextSource) -> Bool {
        lhs.id == rhs.id
    }

    func getEpubEntry(_ fileUrl: URL) -> SourceEntry? {
        let containerUrl = fileUrl.appendingPathComponent("META-INF/container.xml")

        guard let containerData = try? Data(contentsOf: containerUrl),
              let containerString = String(data: containerData, encoding: .utf8),
              let container = try? XmlTreeBuilder().parse(containerString, "") else { return nil }

        guard let rootFilePath = try? container.select("container > rootfiles > rootfile").first()?.attr("full-path") else { return nil }
        let rootFileUrl = fileUrl.appendingPathComponent(rootFilePath)
        guard let rootFileData = try? Data(contentsOf: rootFileUrl),
              let rootFileString = String(data: rootFileData, encoding: .utf8),
              let rootFile = try? XmlTreeBuilder().parse(rootFileString, "") else { return nil }
        let rootPathUrl = rootFileUrl.deletingLastPathComponent()
        let authors = (try? rootFile.select("package > metadata > dc|creator").first()?.text()).flatMap({ [$0] }) ?? []
        let contributors = (try? rootFile.select("package > metadata > dc|contributor").compactMap({ try? $0.text() })) ?? []
        return nil
//        return SourceEntry(
//            id: fileUrl.lastPathComponent,
//            title: (try? rootFile.select("package > metadata > dc|title").first()?.text()) ?? "",
//            staff: authors + contributors,
//            tags: [],
//            cover: (try? rootFile.select("package > metadata > meta[name=cover]").first()?.attr("content")).flatMap({ id in
//                        try? rootFile.select("package > manifest > item#\(id)").first()?.attr("href")
//                     }).flatMap({ rootPathUrl.appendingPathComponent($0).absoluteString }) ?? "",
//            nsfw: .safe,
//            status: .unknown,
//            url: "",
//            description: ""
//        )
    }

    func getEpubChapters(_ fileUrl: URL, id: String, volume: Double? = nil) -> [TextSourceChapter] {
        let containerUrl = fileUrl.appendingPathComponent("META-INF/container.xml")

        guard let containerData = try? Data(contentsOf: containerUrl),
              let containerString = String(data: containerData, encoding: .utf8),
              let container = try? XmlTreeBuilder().parse(containerString, "") else { return [] }

        guard let rootFilePath = try? container.select("container > rootfiles > rootfile").first()?.attr("full-path") else { return [] }
        let rootFileUrl = fileUrl.appendingPathComponent(rootFilePath)
        guard let rootFileData = try? Data(contentsOf: rootFileUrl),
              let rootFileString = String(data: rootFileData, encoding: .utf8),
              let rootFile = try? XmlTreeBuilder().parse(rootFileString, "") else { return [] }
        let rootPathUrl = rootFileUrl.deletingLastPathComponent()

        if let tocHtmlPath = try? rootFile.select("package > manifest > item[properties=nav]").attr("href") {
            let tocHtmlUrl = rootPathUrl.appendingPathComponent(tocHtmlPath)
            guard let tocHtmlData = try? Data(contentsOf: tocHtmlUrl),
                  let tocHtmlString = String(data: tocHtmlData, encoding: .utf8),
                  let tocHtml = try? SwiftSoup.parse(tocHtmlString) else { return [] }
            return (try? tocHtml.select("nav#toc > ol > li > a"))?.enumerated().compactMap({ offset, element in
                guard let id = try? element.attr("href") else { return nil }
                return TextSourceChapter(
                    id: tocHtmlUrl.deletingLastPathComponent().appendingPathComponent(id).absoluteString,
                    entryId: fileUrl.lastPathComponent,
                    name: try? element.text(),
                    chapter: Double(offset + 1),
                    volume: volume,
                    translator: nil,
                    thumbnail: nil,
                    timestamp: nil
                )
            }).reversed() ?? []
        }
        return []
    }

    func importPart(_ url: URL, number partNumber: Double, addingTo entryId: String) {
        guard let temporaryDirectory = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                                    in: .userDomainMask,
                                                                    appropriateFor: FileManager.default.documentDirectory,
                                                                    create: true) else { return }
        var shouldRemoveFile = false
        guard url.startAccessingSecurityScopedResource() else { return }
        defer {
            _ = try? FileManager.default.removeItem(at: temporaryDirectory)
            url.stopAccessingSecurityScopedResource()
            if shouldRemoveFile {
                _ = try? FileManager.default.removeItem(at: url)
            }
        }
        guard (try? FileManager.default.unzipItem(at: url, to: temporaryDirectory)) != nil else { return }
        let textsDirectory = FileManager.default.documentDirectory.appendingPathComponent("Local/Text", conformingTo: .folder)
        if !FileManager.default.fileExists(atPath: textsDirectory.path) {
            guard (try? FileManager.default.createDirectory(at: textsDirectory, withIntermediateDirectories: true)) != nil else { return }
        }
        let textDirectory = textsDirectory.appendingPathComponent(entryId, conformingTo: .folder)
        guard let items = try? FileManager.default.contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: nil) else { return }
        if !FileManager.default.fileExists(atPath: textDirectory.path) {
            guard (try? FileManager.default.createDirectory(at: textDirectory, withIntermediateDirectories: true)) != nil else { return }
        }
        let uuid = UUID().uuidString
        let partDirectory = textDirectory.appendingPathComponent(uuid)
        guard (try? FileManager.default.createDirectory(at: partDirectory, withIntermediateDirectories: true)) != nil else { return }
        for item in items {
            _ = try? FileManager.default.moveItem(at: item, to: partDirectory.appendingPathComponent(item.lastPathComponent))
        }
        guard let manifestData = try? Data(contentsOf: manifestUrl),
              var manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData) else { return }
        if let existingIndex = manifest.firstIndex(where: { $0.id == entryId }) {
            manifest[existingIndex].parts.append(ManifestEntryPart(id: uuid, number: partNumber))
        }
        if let newManifestData = try? JSONEncoder().encode(manifest) {
            _ = try? newManifestData.write(to: manifestUrl)
        }
    }

    func importPart(_ url: URL, number partNumber: Double, withTitle title: String) {
        guard let temporaryDirectory = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                                    in: .userDomainMask,
                                                                    appropriateFor: FileManager.default.documentDirectory,
                                                                    create: true) else { return }
        var shouldRemoveFile = false
        guard url.startAccessingSecurityScopedResource() else { return }
        defer {
            _ = try? FileManager.default.removeItem(at: temporaryDirectory)
            url.stopAccessingSecurityScopedResource()
            if shouldRemoveFile {
                _ = try? FileManager.default.removeItem(at: url)
            }
        }
        guard (try? FileManager.default.unzipItem(at: url, to: temporaryDirectory)) != nil else { return }
        let textsDirectory = FileManager.default.documentDirectory.appendingPathComponent("Local/Text", conformingTo: .folder)
        if !FileManager.default.fileExists(atPath: textsDirectory.path) {
            guard (try? FileManager.default.createDirectory(at: textsDirectory, withIntermediateDirectories: true)) != nil else { return }
        }
        let entryId = UUID().uuidString
        let textDirectory = textsDirectory.appendingPathComponent(entryId, conformingTo: .folder)
        guard let items = try? FileManager.default.contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: nil) else { return }
        if !FileManager.default.fileExists(atPath: textDirectory.path) {
            guard (try? FileManager.default.createDirectory(at: textDirectory, withIntermediateDirectories: true)) != nil else { return }
        }
        let uuid = UUID().uuidString
        let partDirectory = textDirectory.appendingPathComponent(uuid)
        guard (try? FileManager.default.createDirectory(at: partDirectory, withIntermediateDirectories: true)) != nil else { return }
        for item in items {
            _ = try? FileManager.default.moveItem(at: item, to: partDirectory.appendingPathComponent(item.lastPathComponent))
        }
        guard let manifestData = try? Data(contentsOf: manifestUrl),
              var manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData) else { return }
        guard let entry = getEpubEntry(partDirectory)?.toLocalEntry() else { return }
        manifest.append(ManifestEntry(
            id: entryId,
            entry: LocalEntry(
                id: entryId,
                title: title,
                cover: entry.cover,
                staff: entry.staff,
                tags: entry.tags,
                banner: entry.banner,
                color: entry.color,
                description: entry.description
            ),
            parts: [ManifestEntryPart(id: uuid, number: partNumber)]
        ))
        if let newManifestData = try? JSONEncoder().encode(manifest) {
            _ = try? newManifestData.write(to: manifestUrl)
        }
    }

    func importFull(_ url: URL) {
        guard let temporaryDirectory = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                                    in: .userDomainMask,
                                                                    appropriateFor: FileManager.default.documentDirectory,
                                                                    create: true) else { return }
        var shouldRemoveFile = false
        guard url.startAccessingSecurityScopedResource() else { return }
        defer {
            _ = try? FileManager.default.removeItem(at: temporaryDirectory)
            url.stopAccessingSecurityScopedResource()
            if shouldRemoveFile {
                _ = try? FileManager.default.removeItem(at: url)
            }
        }
        guard (try? FileManager.default.unzipItem(at: url, to: temporaryDirectory)) != nil else { return }
        let textsDirectory = FileManager.default.documentDirectory.appendingPathComponent("Local/Text", conformingTo: .folder)
        if !FileManager.default.fileExists(atPath: textsDirectory.path) {
            guard (try? FileManager.default.createDirectory(at: textsDirectory, withIntermediateDirectories: true)) != nil else { return }
        }
        let uuid = UUID().uuidString
        let textDirectory = textsDirectory.appendingPathComponent(uuid, conformingTo: .folder)
        guard let items = try? FileManager.default.contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: nil) else { return }
        if FileManager.default.fileExists(atPath: textDirectory.path) {
            guard (try? FileManager.default.removeItem(at: textDirectory)) != nil else { return }
        }
        guard (try? FileManager.default.createDirectory(at: textDirectory, withIntermediateDirectories: true)) != nil else { return }
        let partDirectory = textDirectory.appendingPathComponent(uuid)
        guard (try? FileManager.default.createDirectory(at: partDirectory, withIntermediateDirectories: true)) != nil else { return }
        for item in items {
            _ = try? FileManager.default.moveItem(at: item, to: partDirectory.appendingPathComponent(item.lastPathComponent))
        }
        guard let manifestData = try? Data(contentsOf: manifestUrl),
              var manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData) else { return }
        guard let entry = getEpubEntry(partDirectory)?.toLocalEntry() else { return }
        manifest.append(ManifestEntry(id: uuid, entry: entry, parts: [ManifestEntryPart(id: uuid, number: -1)]))
        if let newManifestData = try? JSONEncoder().encode(manifest) {
            _ = try? newManifestData.write(to: manifestUrl)
        }
    }

    func delete(id: String) {
        _ = try? FileManager.default.removeItem(at: baseUrl.appendingPathComponent(id))
        guard let manifestData = try? Data(contentsOf: manifestUrl),
              var manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData) else { return }
        manifest.removeAll(where: { $0.id == id })
        if let newManifestData = try? JSONEncoder().encode(manifest) {
            _ = try? newManifestData.write(to: manifestUrl)
        }
    }

    typealias Manifest = [ManifestEntry]

    struct ManifestEntry: Codable {
        let id: String
        let entry: LocalEntry
        var parts: [ManifestEntryPart]
    }

    struct ManifestEntryPart: Codable {
        let id: String
        let number: Double
    }
}
