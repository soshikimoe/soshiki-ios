//
//  TrackersViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/24/23.
//

import UIKit

class TrackersViewController: UITableViewController {
    var observers: [NSObjectProtocol] = []

    var addTrackerText = ""

    init() {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(alertAddTracker))
        self.navigationItem.rightBarButtonItem = addButton
    }

    @objc func alertAddTracker() {
        let alert = UIAlertController(title: "Install a Tracker", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Tracker URL"
            textField.delegate = self
        })
        let doneAction = UIAlertAction(title: "Install", style: .default, handler: { [weak self] _ in
            if let self, let url = URL(string: self.addTrackerText) {
                if url.pathExtension == "soshikitracker" {
                    Task {
                        await TrackerManager.shared.installTracker(url)
                    }
                } else if url.pathExtension == "soshikitrackers" {
                    Task {
                        await TrackerManager.shared.installTrackers(url)
                    }
                }
            }
            self?.addTrackerText = ""
        })
        alert.addAction(doneAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.addTrackerText = ""
        }
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
}

extension TrackersViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        TrackerManager.shared.trackers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let tracker = TrackerManager.shared.trackers[safe: indexPath.row] {
            let cell = TrackerTableViewCell(tracker: tracker, reuseIdentifier: "TrackerTableViewCell")
            cell.accessoryType = .disclosureIndicator
            return cell
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let tracker = TrackerManager.shared.trackers[safe: indexPath.row] {
            self.navigationController?.pushViewController(TrackerViewController(tracker: tracker), animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 72 }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete, let tracker = TrackerManager.shared.trackers[safe: indexPath.row] {
            TrackerManager.shared.removeTracker(id: tracker.id)
        }
    }
}

extension TrackersViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        addTrackerText = textField.text ?? ""
    }
}
