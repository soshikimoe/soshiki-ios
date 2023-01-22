//
//  TextImportManager.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/10/23.
//

import Foundation
import SwiftSoup
import ZIPFoundation

class TextImportManager: ObservableObject {
    static let shared = TextImportManager()

    var url: URL?
    var baseUrl: URL?

    func importEPUBFile(_ url: URL) {
        guard let fileUrl = extractToFiles(url) else { return }
        let containerUrl = fileUrl.appending(components: "META-INF", "container.xml")

        guard let containerData = try? Data(contentsOf: containerUrl),
              let containerString = String(data: containerData, encoding: .utf8),
              let container = try? XmlTreeBuilder().parse(containerString, "") else { return }

        guard let rootFilePath = try? container.select("container > rootfiles > rootfile").first()?.attr("full-path") else { return }
        let rootFileUrl = fileUrl.appending(component: rootFilePath)
        guard let rootFileData = try? Data(contentsOf: rootFileUrl),
              let rootFileString = String(data: rootFileData, encoding: .utf8),
              let rootFile = try? XmlTreeBuilder().parse(rootFileString, "") else { return }
        let entry = LocalEntry(
            title: (try? rootFile.select("package > metadata > dc|title").first()?.text()) ?? "",
            cover: (try? rootFile.select("package > metadata > meta[name=cover]").first()?.attr("content")).flatMap({ id in
                        try? rootFile.select("package > manifest > item#\(id)").first()?.attr("href")
                     }).flatMap({ fileUrl.appending(component: $0).absoluteString }) ?? "",
            staff: (try? rootFile.select("package > metadata > dc|creator").first()?.text()).flatMap({ [$0] }) ?? [],
            tags: [],
            banner: nil,
            color: nil,
            description: nil
        )

        print(entry)
        self.url = fileUrl.appending(component: "OEBPS/Text/appendix001.xhtml")
        self.baseUrl = fileUrl.appending(component: "OEBPS/Text/")
    }

    func extractToFiles(_ url: URL) -> URL? {
        guard let temporaryDirectory = try? FileManager.default.url(for: .itemReplacementDirectory,
                                                                    in: .userDomainMask,
                                                                    appropriateFor: FileManager.default.documentDirectory,
                                                                    create: true) else { return nil }
        var shouldRemoveFile = false
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer {
            _ = try? FileManager.default.removeItem(at: temporaryDirectory)
            url.stopAccessingSecurityScopedResource()
            if shouldRemoveFile {
                _ = try? FileManager.default.removeItem(at: url)
            }
        }
        guard (try? FileManager.default.unzipItem(at: url, to: temporaryDirectory)) != nil else { return nil }
        let textsDirectory = FileManager.default.documentDirectory.appendingPathComponent("Texts", conformingTo: .folder)
        if !FileManager.default.fileExists(atPath: textsDirectory.path) {
            guard (try? FileManager.default.createDirectory(at: textsDirectory, withIntermediateDirectories: true)) != nil else { return nil }
        }
        let textDirectory = textsDirectory.appendingPathComponent("foo", conformingTo: .folder)
        guard let items = try? FileManager.default.contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: nil) else { return nil }
        if FileManager.default.fileExists(atPath: textDirectory.path) {
            guard (try? FileManager.default.removeItem(at: textDirectory)) != nil else { return nil }
        }
        guard (try? FileManager.default.createDirectory(at: textDirectory, withIntermediateDirectories: true)) != nil else { return nil }
        for item in items {
            _ = try? FileManager.default.moveItem(at: item, to: textDirectory.appending(component: item.lastPathComponent))
        }
        return textDirectory
    }
}
