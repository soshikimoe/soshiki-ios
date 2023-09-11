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

    var mediaType: MediaType = UserDefaults.standard.string(forKey: "app.session.mediaType").flatMap({ MediaType(rawValue: $0) }) ?? .video {
        didSet {
            UserDefaults.standard.set(mediaType.rawValue, forKey: LibraryManager.Keys.mediaType)
            NotificationCenter.default.post(name: .init(LibraryManager.Keys.mediaType), object: nil)
        }
    }

    init() {
//        observers.append(
//            NotificationCenter.default.addObserver(forName: .init(SoshikiAPI.Keys.loggedIn), object: nil, queue: nil) { [weak self] _ in
//                Task {
//                    await self?.refresh()
//                }
//            }
//        )

//        Task {
//            await refresh()
//            await refreshUser()
//        }
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

//    func refreshLibraries() async {
//        if let libraries = try? await SoshikiAPI.shared.getLibraries().get() {
//            self.libraries = libraries
//            NotificationCenter.default.post(name: .init(LibraryManager.Keys.libraries), object: nil)
//        }
//    }

//    func refresh() async {
//        guard let libraries = try? await SoshikiAPI.shared.getLibraries().get() else { return }
//        self.libraries = libraries
//        textEntries = []
//        for offset in stride(from: 0, to: libraries.text.all.ids.count, by: 100) {
//            if let newEntries = try? await SoshikiAPI.shared.getEntries(mediaType: .text, query: [
//                .ids(libraries.text.all.ids), .limit(100), .offset(offset)
//            ]).get() {
//                textEntries.append(contentsOf: newEntries)
//            }
//        }
//        imageEntries = []
//        for offset in stride(from: 0, to: libraries.image.all.ids.count, by: 100) {
//            if let newEntries = try? await SoshikiAPI.shared.getEntries(mediaType: .image, query: [
//                .ids(libraries.image.all.ids), .limit(100), .offset(offset)
//            ]).get() {
//                imageEntries.append(contentsOf: newEntries)
//            }
//        }
//        videoEntries = []
//        for offset in stride(from: 0, to: libraries.video.all.ids.count, by: 100) {
//            if let newEntries = try? await SoshikiAPI.shared.getEntries(mediaType: .video, query: [
//                .ids(libraries.video.all.ids), .limit(100), .offset(offset)
//            ]).get() {
//                videoEntries.append(contentsOf: newEntries)
//            }
//        }
//        NotificationCenter.default.post(name: .init(LibraryManager.Keys.libraries), object: nil)
//    }
//
//    func refreshUser() async {
//        if let user = try? await SoshikiAPI.shared.getUser().get() {
//            self.user = user
//            NotificationCenter.default.post(name: .init(LibraryManager.Keys.user), object: nil)
//        }
//    }

    func library(forMediaType mediaType: MediaType? = nil) -> [LibraryItem] {
        DataManager.shared.realm.objects(LibraryItem.self).filter({ $0.mediaType == mediaType })
    }

    func add(entry: any Entry, sourceId: String) {
        try? DataManager.shared.realm.write {
            switch entry {
            case let entry as TextEntry:
                DataManager.shared.realm.add(entry)
                let libraryItem = LibraryItem(mediaType: .text, id: entry.id, sourceId: sourceId, categories: [])
                DataManager.shared.realm.add(libraryItem)
            case let entry as ImageEntry:
                DataManager.shared.realm.add(entry)
                let libraryItem = LibraryItem(mediaType: .image, id: entry.id, sourceId: sourceId, categories: [])
                DataManager.shared.realm.add(libraryItem)
            case let entry as VideoEntry:
                DataManager.shared.realm.add(entry)
                let libraryItem = LibraryItem(mediaType: .video, id: entry.id, sourceId: sourceId, categories: [])
                DataManager.shared.realm.add(libraryItem)
            default: break
            }
        }
    }

    func remove(entry: any Entry, sourceId: String) {
        switch entry {
        case let entry as TextEntry:
            DataManager.shared.realm.delete(entry)
            if let libraryItem = DataManager.shared.realm.objects(LibraryItem.self).first(where: { $0.id == entry.id && $0.sourceId == sourceId }) {
                DataManager.shared.realm.delete(libraryItem)
            }
        case let entry as ImageEntry:
            DataManager.shared.realm.add(entry)
            if let libraryItem = DataManager.shared.realm.objects(LibraryItem.self).first(where: { $0.id == entry.id && $0.sourceId == sourceId }) {
                DataManager.shared.realm.delete(libraryItem)
            }
        case let entry as VideoEntry:
            DataManager.shared.realm.add(entry)
            if let libraryItem = DataManager.shared.realm.objects(LibraryItem.self).first(where: { $0.id == entry.id && $0.sourceId == sourceId }) {
                DataManager.shared.realm.delete(libraryItem)
            }
        default: break
        }
    }

//    func isTracking(mediaType: MediaType, id: String, trackerId: String) -> Bool {
//        switch mediaType {
//        case .text: return user?.trackers?.text.contains(where: { $0.entryId == id && $0.id == trackerId }) ?? false
//        case .image: return user?.trackers?.image.contains(where: { $0.entryId == id && $0.id == trackerId }) ?? false
//        case .video: return user?.trackers?.video.contains(where: { $0.entryId == id && $0.id == trackerId }) ?? false
//        }
//    }
//
//    func preferredSource(mediaType: MediaType, id: String) -> String? {
//        guard let deviceId = UserDefaults.standard.string(forKey: "app.notification.id") else { return nil }
//        switch mediaType {
//        case .text: return user?.devices?.first(where: { $0.id == deviceId })?.notifications.text.first(where: { $0.id == id })?.source
//        case .image: return user?.devices?.first(where: { $0.id == deviceId })?.notifications.image.first(where: { $0.id == id })?.source
//        case .video: return user?.devices?.first(where: { $0.id == deviceId })?.notifications.video.first(where: { $0.id == id })?.source
//        }
//    }
//
//    func isNotifying(mediaType: MediaType, id: String) -> Bool {
//        guard let deviceId = UserDefaults.standard.string(forKey: "app.notification.id") else { return false }
//        switch mediaType {
//        case .text: return user?.devices?.first(where: { $0.id == deviceId })?.notifications.text.contains(where: { $0.id == id }) ?? false
//        case .image: return user?.devices?.first(where: { $0.id == deviceId })?.notifications.image.contains(where: { $0.id == id }) ?? false
//        case .video: return user?.devices?.first(where: { $0.id == deviceId })?.notifications.video.contains(where: { $0.id == id }) ?? false
//        }
//    }
}

extension LibraryManager {
    class Keys {
        static let libraries = "app.library.library.update"
        static let category = "app.library.category.update"
        static let mediaType = "app.session.mediaType"
        static let user = "app.user.update"
    }
}
