//
//  LibraryManager.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/25/23.
//

import Foundation

class LibraryManager {
    static let shared = LibraryManager()

    var observers: [NSObjectProtocol] = []

    var libraries: Libraries?

    var textEntries: [Entry] = []
    var imageEntries: [Entry] = []
    var videoEntries: [Entry] = []

    var entries: [Entry] {
        mediaType == .text ? textEntries : mediaType == .image ? imageEntries : videoEntries
    }

    var mediaType: MediaType = UserDefaults.standard.string(forKey: "app.session.mediaType").flatMap({ MediaType(rawValue: $0) }) ?? .image {
        didSet {
            UserDefaults.standard.set(mediaType.rawValue, forKey: LibraryManager.Keys.mediaType)
            NotificationCenter.default.post(name: .init(LibraryManager.Keys.mediaType), object: nil)
        }
    }

    var category: LibraryCategory? {
        didSet {
            NotificationCenter.default.post(name: .init(LibraryManager.Keys.category), object: nil)
        }
    }

    init() {
        observers.append(
            NotificationCenter.default.addObserver(forName: .init(SoshikiAPI.Keys.loggedIn), object: nil, queue: nil) { [weak self] _ in
                Task {
                    await self?.refresh()
                }
            }
        )

        Task {
            await refresh()
        }
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func refreshLibraries() async {
        if let libraries = try? await SoshikiAPI.shared.getLibraries().get() {
            self.libraries = libraries
            NotificationCenter.default.post(name: .init(LibraryManager.Keys.libraries), object: nil)
        }
    }

    func refresh() async {
        guard let libraries = try? await SoshikiAPI.shared.getLibraries().get() else { return }
        self.libraries = libraries
        textEntries = []
        for offset in stride(from: 0, to: libraries.text.all.ids.count, by: 100) {
            if let newEntries = try? await SoshikiAPI.shared.getEntries(mediaType: .text, query: [
                .ids(libraries.text.all.ids), .limit(100), .offset(offset)
            ]).get() {
                textEntries.append(contentsOf: newEntries)
            }
        }
        imageEntries = []
        for offset in stride(from: 0, to: libraries.image.all.ids.count, by: 100) {
            if let newEntries = try? await SoshikiAPI.shared.getEntries(mediaType: .image, query: [
                .ids(libraries.image.all.ids), .limit(100), .offset(offset)
            ]).get() {
                imageEntries.append(contentsOf: newEntries)
            }
        }
        videoEntries = []
        for offset in stride(from: 0, to: libraries.video.all.ids.count, by: 100) {
            if let newEntries = try? await SoshikiAPI.shared.getEntries(mediaType: .video, query: [
                .ids(libraries.video.all.ids), .limit(100), .offset(offset)
            ]).get() {
                videoEntries.append(contentsOf: newEntries)
            }
        }
        NotificationCenter.default.post(name: .init(LibraryManager.Keys.libraries), object: nil)
    }

    func library(forMediaType mediaType: MediaType? = nil) -> FullLibrary? {
        let mediaType = mediaType ?? self.mediaType
        return mediaType == .text ? libraries?.text : mediaType == .image ? libraries?.image : libraries?.video
    }

    func add(entry: Entry, toCategory category: String? = nil) async {
        if let category {
            await SoshikiAPI.shared.addEntryToLibraryCategory(mediaType: entry.mediaType, id: category, entryId: entry._id)
        } else {
            await SoshikiAPI.shared.addEntryToLibrary(mediaType: entry.mediaType, entryId: entry._id)
        }
        await self.refreshLibraries()
    }

    func remove(entry: Entry, fromCategory category: String? = nil) async {
        if let category {
            await SoshikiAPI.shared.deleteEntryFromLibraryCategory(mediaType: entry.mediaType, id: category, entryId: entry._id)
        } else {
            await SoshikiAPI.shared.deleteEntryFromLibrary(mediaType: entry.mediaType, entryId: entry._id)
        }
        await self.refreshLibraries()
    }
}

extension LibraryManager {
    class Keys {
        static let libraries = "app.library.library.update"
        static let category = "app.library.category.update"
        static let mediaType = "app.session.mediaType"
    }
}
