//
//  TrackerViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/24/23.
//

import UIKit
import SafariServices

class TrackerViewController: UITableViewController {
    var observers: [NSObjectProtocol] = []

    let tracker: Tracker
    let authUrl: URL?

    init(tracker: Tracker) {
        self.tracker = tracker
        self.authUrl = tracker.getAuthUrl()
        super.init(style: .insetGrouped)
        self.title = tracker.name
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TrackerViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 2 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        switch indexPath.row {
        case 0:
            var content = cell.defaultContentConfiguration()
            content.text = "Login"
            content.textProperties.color = .tintColor
            cell.contentConfiguration = content
            return cell
        case 1:
            let switchView = UISwitch()
            switchView.isOn = UserDefaults.standard.bool(forKey: "settings.tracker.\(tracker.id).automaticallyTrack")
            switchView.addTarget(self, action: #selector(updateAutoTrackStatus(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            var content = cell.defaultContentConfiguration()
            content.text = "Automatically Track"
            cell.contentConfiguration = content
            return cell
        default: break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0, let authUrl {
            let safariViewController = SFSafariViewController(url: authUrl)
            TrackerManager.shared.currentLoginInformation = (
                tracker: tracker,
                viewController: safariViewController
            )
            self.present(safariViewController, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc func updateAutoTrackStatus(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "settings.tracker.\(tracker.id).automaticallyTrack")
        NotificationCenter.default.post(name: .init("settings.tracker.\(tracker.id).automaticallyTrack"), object: nil)
    }
}
