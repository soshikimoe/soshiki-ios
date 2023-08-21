//
//  SettingsViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/23/23.
//

import UIKit

class SettingsViewController: SettingTableViewController {
    var settingGroups: [SettingGroup] {
        [
            SettingGroup(id: "account", header: "Account", items: [
                ButtonSettingItem(id: "loginout", title: SoshikiAPI.shared.token == nil ? "Login" : "Logout") { [weak self] _ in
                    guard let self else { return }
                    if SoshikiAPI.shared.token == nil {
                        self.present(SoshikiAPI.shared.loginViewController, animated: true)
                    } else {
                        SoshikiAPI.shared.logout()
                    }
                }
            ]),
            SettingGroup(id: "general", header: "General", items: [
                NumberSettingItem(
                    id: "itemsPerRow",
                    title: "Items Per Row",
                    value: Double(UserDefaults.standard.object(forKey: "app.settings.itemsPerRow") as? Int ?? 3),
                    lowerBound: 2,
                    upperBound: 8,
                    step: 1
                ) { item in
                    UserDefaults.standard.set(Int(item.value), forKey: "app.settings.itemsPerRow")
                    NotificationCenter.default.post(name: .init("app.settings.itemsPerRow"), object: nil)
                },
                ColorSettingItem(
                    id: "accentColor",
                    title: "Accent Color",
                    supportsAlpha: false,
                    canReset: true,
                    value: UserDefaults.standard.string(forKey: "app.settings.accentColor").flatMap({ UIColor.from(rawValue: $0) })
                ) { [weak self] item in
                    UserDefaults.standard.set(item.value?.rawValue, forKey: "app.settings.accentColor")
                    NotificationCenter.default.post(name: .init("app.settings.accentColor"), object: nil)
                    self?.tableView.window?.tintColor = item.value ?? UIColor.tintColor
                }
            ]),
            SettingGroup(id: "sources", header: "Sources", items: [
                ButtonSettingItem(id: "sources", title: "Sources", presentsView: true) { [weak self] _ in
                    self?.navigationController?.pushViewController(SourcesViewController(), animated: true)
                }
            ]),
//            SettingGroup(id: "trackers", header: "Trackers", items: [
//                ButtonSettingItem(id: "trackers", title: "Trackers", presentsView: true) { [weak self] _ in
//                    self?.navigationController?.pushViewController(TrackersViewController(), animated: true)
//                }
//            ]),
            SettingGroup(id: "backups", header: "Backups", items: [
                ButtonSettingItem(id: "backups", title: "Export Backup") { [weak self] _ in
                    guard let data = DataManager.shared.createBackup() else { return }
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
                        "soshiki-backup-\(Date().hyphenated()).soshikibackup"
                    )
                    FileManager.default.createFile(atPath: url.path, contents: data)
                    self?.present(
                        UIActivityViewController(activityItems: [ url ], applicationActivities: nil),
                        animated: true
                    )
                }
            ]),
            SettingGroup(id: "notifications", header: "Notifications", items: [
                ButtonSettingItem(id: "forceResetBadge", title: "Force Reset Badge") { _ in
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    Task {
                        // await SoshikiAPI.shared.setNotificationBadge(count: 0)
                    }
                }
            ]),
            SettingGroup(id: "logs", header: "Logs", items: [
                ButtonSettingItem(id: "logs", title: "Logs", presentsView: true) { [weak self] _ in
                    self?.navigationController?.pushViewController(LogViewController(), animated: true)
                }
            ])
        ]
    }

    init() {
        super.init(title: "Settings")

        self.groups = settingGroups

        observers.append(
            NotificationCenter.default.addObserver(forName: .init(SoshikiAPI.Keys.loggedIn), object: nil, queue: nil) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.groups = self.settingGroups
                    self.tableView.reloadData()
                }
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init(SoshikiAPI.Keys.loggedOut), object: nil, queue: nil) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.groups = self.settingGroups
                    self.tableView.reloadData()
                }
            }
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
