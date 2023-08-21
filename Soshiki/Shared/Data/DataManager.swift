//
//  DataManager.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/4/23.
//

import Foundation
import RealmSwift
import Unrealm

@MainActor class DataManager {
    static let shared = DataManager()

    let realm: Realm

    init() {
        var configuration = Realm.Configuration()
        // TODO: REMOVE (and add schema versioning)
        configuration.deleteRealmIfMigrationNeeded = true
        guard let realm = try? Realm(configuration: configuration) else { fatalError("Realm could not be initialized.") }
        self.realm = realm
    }
}

// MARK: - Library

extension DataManager {
    func getLibraryItems(ofType mediaType: MediaType, in category: String? = nil) -> [LibraryItem] {
        if let category {
            return self.realm.objects(LibraryItem.self).filter({ $0.mediaType == mediaType && $0.categories.contains(category) })
        } else {
            return self.realm.objects(LibraryItem.self).filter({ $0.mediaType == mediaType })
        }
    }

    func addLibraryItems(_ entries: [any Entry], ofType mediaType: MediaType) {
        addLibraryItems(entries.map({
            LibraryItem(mediaType: mediaType, id: $0.id, sourceId: $0.sourceId, categories: [])
        }), ofType: mediaType)
    }

    func addLibraryItems(_ items: [LibraryItem], ofType mediaType: MediaType) {
        let existingItems = getLibraryItems(ofType: mediaType)

        try? self.realm.write {
            for item in items {
                if !existingItems.contains(where: { $0.mediaType == item.mediaType && $0.sourceId == item.sourceId && $0.id == item.id }) {
                    self.realm.add(item)
                }
            }
        }
    }

    func addLibraryItems(_ entries: [any Entry], ofType mediaType: MediaType, to category: String) {
        addLibraryItems(entries.map({
            LibraryItem(mediaType: mediaType, id: $0.id, sourceId: $0.sourceId, categories: [])
        }), ofType: mediaType, to: category)
    }

    func addLibraryItems(_ items: [LibraryItem], ofType mediaType: MediaType, to category: String) {
        let existingItems = getLibraryItems(ofType: mediaType)

        try? self.realm.write {
            for item in items {
                if let existingItem = existingItems.first(where: {
                    $0.mediaType == item.mediaType && $0.sourceId == item.sourceId && $0.id == item.id
                }),
                   !existingItem.categories.contains(category) {
                    existingItem.categories.append(category)
                    self.realm.add(existingItem, update: .modified)
                }
            }
        }
    }

    func removeLibraryItems(_ entries: [any Entry], ofType mediaType: MediaType) {
        removeLibraryItems(entries.map({
            LibraryItem(mediaType: mediaType, id: $0.id, sourceId: $0.sourceId, categories: [])
        }), ofType: mediaType)
    }

    func removeLibraryItems(_ items: [LibraryItem], ofType mediaType: MediaType) {
        let existingItems = getLibraryItems(ofType: mediaType)

        try? self.realm.write {
            for item in items {
                if let existingItem = existingItems.first(where: {
                    $0.mediaType == item.mediaType && $0.sourceId == item.sourceId && $0.id == item.id
                }) {
                    self.realm.delete(existingItem)
                }
            }
        }
    }

    func removeLibraryItems(_ entries: [any Entry], ofType mediaType: MediaType, from category: String) {
        removeLibraryItems(entries.map({
            LibraryItem(mediaType: mediaType, id: $0.id, sourceId: $0.sourceId, categories: [])
        }), ofType: mediaType, from: category)
    }

    func removeLibraryItems(_ items: [LibraryItem], ofType mediaType: MediaType, from category: String) {
        let existingItems = getLibraryItems(ofType: mediaType)

        try? self.realm.write {
            for item in items {
                if let existingItem = existingItems.first(where: {
                    $0.mediaType == item.mediaType && $0.sourceId == item.sourceId && $0.id == item.id
                }),
                   existingItem.categories.contains(category) {
                    existingItem.categories.removeAll(where: { $0 == category })
                    self.realm.add(existingItem, update: .modified)
                }
            }
        }
    }

    func getLibraryCategories(ofType mediaType: MediaType) -> [LibraryCategory] {
        self.realm.objects(LibraryCategory.self).filter({ $0.mediaType == mediaType })
    }

    func addLibraryCategories(_ categories: [LibraryCategory], ofType mediaType: MediaType) {
        let existingCategories = getLibraryCategories(ofType: mediaType)

        try? self.realm.write {
            for category in categories {
                if !existingCategories.contains(where: { $0.mediaType == category.mediaType && $0.id == category.id }) {
                    self.realm.add(category)
                }
            }
        }
    }

    func removeLibraryCategories(_ categories: [LibraryCategory], ofType mediaType: MediaType) {
        let existingCategories = getLibraryCategories(ofType: mediaType)

        try? self.realm.write {
            for category in categories {
                if let existingCategory = existingCategories.first(where: { $0.mediaType == category.mediaType && $0.id == category.id }) {
                    self.realm.delete(existingCategory)
                }
            }
        }
    }
}

// MARK: - Entries

extension DataManager {
    func getEntries<T: Entry>(_ items: [LibraryItem]) -> [T] {
        self.realm.objects(T.self).filter({ entry in
            items.contains(where: { entry.sourceId == $0.sourceId && entry.id == $0.id })
        })
    }

    func getEntry<T: Entry>(_ item: LibraryItem) -> T? {
        getEntries([ item ]).first
    }

    func getEntry<T: Entry>(id: String, sourceId: String) -> T? {
        getEntry(
            LibraryItem(
                mediaType: T.self is TextEntry.Type ? .text : T.self is ImageEntry.Type ? .image : .video,
                id: id,
                sourceId: sourceId,
                categories: []
            )
        )
    }

    func addEntries<T: Entry>(_ entries: [T]) {
        let existingEntries = self.realm.objects(T.self)

        try? self.realm.write {
            for entry in entries {
                if !existingEntries.contains(where: { entry.sourceId == $0.sourceId && entry.id == $0.id }) {
                    self.realm.add(entry)
                }
            }
        }
    }

    func removeEntries<T: Entry>(_ entries: [T]) {
        let existingEntries = self.realm.objects(T.self)

        try? self.realm.write {
            for entry in entries {
                if let existingEntry = existingEntries.first(where: { entry.sourceId == $0.sourceId && entry.id == $0.id }) {
                    self.realm.delete(existingEntry)
                }
            }
        }
    }
}

// MARK: - History

extension DataManager {
    func getHistory<T: Entry>(_ entry: T) -> T.HistoryType? {
        self.realm.objects(T.HistoryType.self).first(where: { $0.sourceId == entry.sourceId && $0.id == entry.id })
    }

    func setHistory<T: History>(_ history: T) {
        try? self.realm.write {
            self.realm.add(history, update: .modified)
        }
    }

    func addHistory<T: History>(_ history: T) {
        try? self.realm.write {
            self.realm.add(history)
        }
    }

    func removeHistory<T: History>(_ history: T) {
        try? self.realm.write {
            self.realm.delete(history)
        }
    }

    func removeHistory<T: Entry>(_ entry: T) {
        if let history = getHistory(entry) {
            removeHistory(history)
        }
    }
}

extension DataManager {
    func getSources<T: SourceManifest>() -> [T] {
        self.realm.objects(T.self).map({ $0 })
    }

    func addSource<T: SourceManifest>(_ source: T) {
        try? self.realm.write {
            self.realm.add(source)
        }
    }

    func removeSource<T: SourceManifest>(_ source: T) {
        try? self.realm.write {
            self.realm.delete(source)
        }
    }
}

extension DataManager {
    struct Backup: Codable {
        let sources: TIVCodable<[TextSourceManifest], [ImageSourceManifest], [VideoSourceManifest]>
        let library: [LibraryItem]
        let libraryCategories: [LibraryCategory]
        let history: TIVCodable<[TextHistory], [ImageHistory], [VideoHistory]>
        let entries: TIVCodable<[TextEntry], [ImageEntry], [VideoEntry]>
        let version: String
        let schema: Int
        let time: Date
    }

    struct TIVCodable<T: Codable, I: Codable, V: Codable>: Codable {
        let text: T
        let image: I
        let video: V
    }

    func createBackup() -> Data? {
        try? JSONEncoder().encode(
            Backup(
                sources: TIVCodable(
                    text: getSources(),
                    image: getSources(),
                    video: getSources()
                ),
                library: self.realm.objects(LibraryItem.self).map({ $0 }),
                libraryCategories: self.realm.objects(LibraryCategory.self).map({ $0 }),
                history: TIVCodable(
                    text: self.realm.objects(TextHistory.self).map({ $0 }),
                    image: self.realm.objects(ImageHistory.self).map({ $0 }),
                    video: self.realm.objects(VideoHistory.self).map({ $0 })
                ),
                entries: TIVCodable(
                    text: self.realm.objects(TextEntry.self).map({ $0 }),
                    image: self.realm.objects(ImageEntry.self).map({ $0 }),
                    video: self.realm.objects(VideoEntry.self).map({ $0 })
                ),
                version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
                schema: 1,
                time: Date()
            )
        )
    }

    func importBackup(_ url: URL) {
        guard let data = try? Data(contentsOf: url),
              let backup = try? JSONDecoder().decode(Backup.self, from: data) else { return }
        try? self.realm.write {
            self.realm.deleteAll()
            for source in backup.sources.text {
                self.realm.add(source)
            }
            for source in backup.sources.image {
                self.realm.add(source)
            }
            for source in backup.sources.video {
                self.realm.add(source)
            }

            for item in backup.library {
                self.realm.add(item)
            }

            for category in backup.libraryCategories {
                self.realm.add(category)
            }

            for history in backup.history.text {
                self.realm.add(history)
            }
            for history in backup.history.image {
                self.realm.add(history)
            }
            for history in backup.history.video {
                self.realm.add(history)
            }

            for entry in backup.entries.text {
                self.realm.add(entry)
            }
            for entry in backup.entries.image {
                self.realm.add(entry)
            }
            for entry in backup.entries.video {
                self.realm.add(entry)
            }

            NotificationCenter.default.post(name: .init(LibraryManager.Keys.libraries), object: nil)
            NotificationCenter.default.post(name: .init(SourceManager.Keys.update), object: nil)
            NotificationCenter.default.post(name: .init(TrackerManager.Keys.update), object: nil)
        }
    }
}
