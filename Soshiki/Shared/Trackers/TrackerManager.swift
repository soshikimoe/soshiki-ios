//
//  TrackerManager.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/8/23.
//

import Foundation
import ZIPFoundation
import SafariServices
import JavaScriptCore

class TrackerManager {
    static let shared = TrackerManager()

    let context = JSContext()!

    var trackers: [Tracker] = []

    var currentLoginInformation: (tracker: Tracker, viewController: SFSafariViewController)?

    func startup() {
        injectDependencies()

        let trackersDirectory = FileManager.default.documentDirectory.appendingPathComponent("Trackers")
        if !FileManager.default.fileExists(atPath: trackersDirectory.path) {
            guard (try? FileManager.default.createDirectory(at: trackersDirectory, withIntermediateDirectories: true)) != nil else { return }
        }
        guard let trackers = try? FileManager.default.contentsOfDirectory(at: trackersDirectory, includingPropertiesForKeys: nil) else { return }
        for tracker in trackers {
            if let tracker = Tracker.load(directory: tracker, context: context) {
                self.trackers.append(tracker)
            }
        }
    }

    func installTracker(_ url: URL) async {
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
        if let manifest = Tracker.manifest(directory: temporaryDirectory) {
            let trackersDirectory = FileManager.default.documentDirectory.appendingPathComponent("Trackers", conformingTo: .folder)
            if !FileManager.default.fileExists(atPath: trackersDirectory.path) {
                guard (try? FileManager.default.createDirectory(at: trackersDirectory, withIntermediateDirectories: true)) != nil else { return }
            }
            let trackerDirectory = trackersDirectory.appendingPathComponent(manifest.id, conformingTo: .folder)
            guard let items = try? FileManager.default.contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: nil) else { return }
            if FileManager.default.fileExists(atPath: trackerDirectory.path) {
                guard (try? FileManager.default.removeItem(at: trackerDirectory)) != nil else { return }
                trackers.removeAll(where: { $0.id == manifest.id })
            }
            guard (try? FileManager.default.createDirectory(at: trackerDirectory, withIntermediateDirectories: true)) != nil else { return }
            for item in items {
                _ = try? FileManager.default.moveItem(at: item, to: trackerDirectory.appendingPathComponent(item.lastPathComponent))
            }
            if let tracker = Tracker.load(directory: trackerDirectory, context: context) {
                self.trackers.append(tracker)
                NotificationCenter.default.post(name: .init(TrackerManager.Keys.update), object: nil)
            }
        }
    }

    func removeTracker(id: String) {
        let trackersDirectory = FileManager.default.documentDirectory.appendingPathComponent("Trackers", conformingTo: .folder)
        if !FileManager.default.fileExists(atPath: trackersDirectory.path) { return }
        let trackerDirectory = trackersDirectory.appendingPathComponent(id, conformingTo: .folder)
        guard (try? FileManager.default.removeItem(at: trackerDirectory)) != nil else { return }
        self.trackers.removeAll(where: { $0.id == id })
        NotificationCenter.default.post(name: .init(TrackerManager.Keys.update), object: nil)
    }

    func installTrackers(_ url: URL) async {
        guard let (trackerListData, _) = try? await URLSession.shared.data(from: url),
              let trackerList = try? JSONDecoder().decode(TrackerListManifest.self, from: trackerListData) else { return }
        for tracker in trackerList {
            await installTracker(url.deletingLastPathComponent().appendingPathComponent(tracker.path))
        }
    }

    func loginCallback(_ url: URL) {
        if let currentLoginInformation {
            Task {
                await currentLoginInformation.tracker.handleResponse(url: url)
            }
            currentLoginInformation.viewController.dismiss(animated: true)
            self.currentLoginInformation = nil
        }
    }

    func setHistory(entry: Entry, history: History) async {
        for tracker in trackers {
            if UserDefaults.standard.object(forKey: "user.trackers.\(tracker.id).\(entry._id).isTracking") as? Bool ??
                UserDefaults.standard.bool(forKey: "settings.tracker.\(tracker.id).automaticallyTrack") == true,
               let id = entry.trackers.first(where: { $0.id == tracker.id })?.entryId {
                await tracker.setHistory(mediaType: entry.mediaType, id: id, history: history)
            }
        }
    }

    func injectDependencies() {
        context.objectForKeyedSubscript("console").setObject({ value in
            print("JSContext LOG: \(value.toString() ?? "")")
        } as @convention(block) (JSValue) -> Void, forKeyedSubscript: "log")
        context.objectForKeyedSubscript("console").setObject({ value in
            print("JSContext WARN: \(value.toString() ?? "")")
        } as @convention(block) (JSValue) -> Void, forKeyedSubscript: "warn")
        context.objectForKeyedSubscript("console").setObject({ value in
            print("JSContext ERROR: \(value.toString() ?? "")")
        } as @convention(block) (JSValue) -> Void, forKeyedSubscript: "error")
        JSFetch.inject(into: context)
        JSDom.inject(into: context)

        context.objectForKeyedSubscript("globalThis").setObject({ key, id in
            guard let key = key.toString(), let id = id.toString() else { return nil }
            return UserDefaults.standard.value(forKey: "settings.tracker.\(id).\(key)")
        } as @convention(block) (JSValue, JSValue) -> Any?, forKeyedSubscript: "getSettingsValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key, id in
            guard let key = key.toString(), let id = id.toString() else { return nil }
            return UserDefaults.standard.value(forKey: "storage.tracker.\(id).\(key)")
        } as @convention(block) (JSValue, JSValue) -> Any?, forKeyedSubscript: "getStorageValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key, value, id in
            guard let key = key.toString(), let id = id.toString() else { return }
            UserDefaults.standard.set(value.toObject(), forKey: "storage.tracker.\(id).\(key)")
        } as @convention(block) (JSValue, JSValue, JSValue) -> Void, forKeyedSubscript: "setStorageValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key, id in
            guard let key = key.toString(), let id = id.toString() else { return nil }
            return KeychainManager.shared.get("keychain.tracker.\(id).\(key)")
        } as @convention(block) (JSValue, JSValue) -> String?, forKeyedSubscript: "getKeychainValue")
        context.objectForKeyedSubscript("globalThis").setObject({ key, value, id in
            guard let key = key.toString(), let value = value.toString(), let id = id.toString() else { return }
            KeychainManager.shared.set(value, forKey: "keychain.tracker.\(id).\(key)")
        } as @convention(block) (JSValue, JSValue, JSValue) -> Void, forKeyedSubscript: "setKeychainValue")

        context.objectForKeyedSubscript("globalThis").setObject({ status, id in
            guard let id = id.toString() else { return }
            UserDefaults.standard.set(status.toBool(), forKey: "tracker.\(id).loggedIn")
            NotificationCenter.default.post(name: .init("tracker.\(id).loggedIn"), object: nil)
        } as @convention(block) (JSValue, JSValue) -> Void, forKeyedSubscript: "setLoginStatus")
    }
}

extension TrackerManager {
    class Keys {
        static let update = "app.trackers.update"
    }
}

struct TrackerManifest: Codable {
    let id: String
    let name: String
    let author: String
    let icon: String
    let version: String
    let schema: Int?
}

typealias TrackerListManifest = [TrackerListTrackerManifest]

struct TrackerListTrackerManifest: Codable {
    let path: String
    let id: String
    let name: String
    let author: String
    let icon: String
    let version: String
    let schema: Int?
}
