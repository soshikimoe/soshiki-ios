//
//  TrackerViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/24/23.
//

import UIKit
import SafariServices

class TrackerViewController: SettingTableViewController {
    var observers: [NSObjectProtocol] = []

    let tracker: Tracker
    let authUrl: URL?

    var loggedIn: Bool {
        UserDefaults.standard.bool(forKey: "tracker.\(tracker.id).loggedIn")
    }

    var settingGroups: [SettingGroup] {
        [
            SettingGroup(id: "general", header: "General", items: [
                ButtonSettingItem(id: "loginout", title: loggedIn ? "Logout" : "Login") { [weak self] _ in
                    guard let self, let authUrl = self.authUrl else { return }
                    if self.loggedIn {
                        self.tracker.logout()
                    } else {
                        let safariViewController = SFSafariViewController(url: authUrl)
                        TrackerManager.shared.currentLoginInformation = (
                            tracker: self.tracker,
                            viewController: safariViewController
                        )
                        self.present(safariViewController, animated: true)
                    }
                },
                ToggleSettingItem(
                    id: "automaticallyTrack",
                    title: "Automatically Track",
                    value: UserDefaults.standard.bool(forKey: "settings.tracker.\(self.tracker.id).automaticallyTrack")
                ) { [weak self] newValue in
                    guard let self else { return }
                    UserDefaults.standard.set(newValue, forKey: "settings.tracker.\(self.tracker.id).automaticallyTrack")
                    NotificationCenter.default.post(name: .init("settings.tracker.\(self.tracker.id).automaticallyTrack"), object: nil)
                }
            ])
        ]
    }

    init(tracker: Tracker) {
        self.tracker = tracker
        self.authUrl = tracker.getAuthUrl()
        super.init(title: tracker.name)

        self.groups = self.settingGroups

        observers.append(
            NotificationCenter.default.addObserver(forName: .init("tracker.\(tracker.id).loggedIn"), object: nil, queue: nil) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.groups = self.settingGroups
                    self.tableView.reloadData()
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
}
