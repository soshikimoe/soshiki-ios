//
//  EntryTrackersViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/29/23.
//

import UIKit

class EntryTrackersViewController: UITableViewController {
    var observers: [NSObjectProtocol] = []

    let entry: Entry

    var trackers: [Tracker] {
        TrackerManager.shared.trackers.filter({ tracker in
            entry.trackers.contains(where: { $0.id == tracker.id })
        })
    }

    init(entry: Entry) {
        self.entry = entry
        super.init(style: .insetGrouped)
        self.title = "Trackers"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")

        observers.append(
            NotificationCenter.default.addObserver(forName: .init(TrackerManager.Keys.update), object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.tableView.reloadData()
                }
            }
        )
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func trackingStatusDidChange(_ sender: UISwitch) {
        guard let tracker = trackers[safe: sender.tag] else { return }
        Task {
            if sender.isOn {
                _ = await SoshikiAPI.shared.addTracker(mediaType: entry.mediaType, id: entry._id, trackerId: tracker.id)
            } else {
                _ = await SoshikiAPI.shared.removeTracker(mediaType: entry.mediaType, id: entry._id, trackerId: tracker.id)
            }
            await LibraryManager.shared.refreshUser()
        }
        if sender.isOn {
            let alert = UIAlertController(
                title: "Enable Tracker",
                message: "Would you like to try to pull information from the tracker if present, or push local information to it?",
                preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(title: "Push", style: .default) { [weak self] _ in
                    Task {
                        if let entry = self?.entry,
                           let entryId = entry.trackers.first(where: { $0.id == tracker.id })?.entryId,
                           let history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get() {
                            await tracker.setHistory(mediaType: entry.mediaType, id: entryId, history: history)
                        }
                    }
                }
            )
            alert.addAction(
                UIAlertAction(title: "Pull", style: .default) { [weak self] _ in
                    Task {
                        if let entry = self?.entry,
                           let entryId = entry.trackers.first(where: { $0.id == tracker.id })?.entryId,
                           let history = await tracker.getHistory(mediaType: entry.mediaType, id: entryId) {
                            var query: [SoshikiAPI.HistoryQuery] = [.status(history.status)]
                            if let page = history.page { query.append(.page(page)) }
                            if let chapter = history.chapter { query.append(.chapter(chapter)) }
                            if let volume = history.volume { query.append(.volume(volume)) }
                            if let timestamp = history.timestamp { query.append(.timestamp(timestamp)) }
                            if let episode = history.episode { query.append(.episode(episode)) }
                            if let score = history.score { query.append(.score(score)) }
                            await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: query)
                        }
                    }
                }
            )
            self.present(alert, animated: true)
        } else {
            let alert = UIAlertController(
                title: "Disable Tracker",
                message: "Would you like to delete history data for this entry from the tracker?",
                preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
                    Task {
                        if let entry = self?.entry, let entryId = entry.trackers.first(where: { $0.id == tracker.id })?.entryId {
                            await tracker.deleteHistory(mediaType: entry.mediaType, id: entryId)
                        }
                    }
                }
            )
            alert.addAction(
                UIAlertAction(title: "No", style: .cancel)
            )
            self.present(alert, animated: true)
        }
    }
}

extension EntryTrackersViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        trackers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let tracker = trackers[safe: indexPath.row] {
            let cell = TrackerTableViewCell(tracker: tracker, reuseIdentifier: "TrackerTableViewCell")
            let toggleView = UISwitch()
            toggleView.isOn = LibraryManager.shared.isTracking(mediaType: entry.mediaType, id: entry._id, trackerId: tracker.id)
            toggleView.tag = indexPath.row
            toggleView.addTarget(self, action: #selector(trackingStatusDidChange(_:)), for: .valueChanged)
            cell.accessoryView = toggleView
            cell.selectionStyle = .none
            return cell
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 72 }
}
