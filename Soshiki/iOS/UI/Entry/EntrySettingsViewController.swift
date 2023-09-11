//
//  EntrySettingsViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/5/23.
//

import UIKit

class EntrySettingsViewController: SettingTableViewController {
    let entry: any Entry

    init(entry: any Entry) {
        self.entry = entry
        super.init(title: "Settings")

        self.groups = [
//            SettingGroup(id: "trackers", header: "Trackers", items: [
//                ButtonSettingItem(id: "trackers", title: "Trackers", presentsView: true) { [weak self] _ in
//                     guard let self else { return }
//                     self.navigationController?.pushViewController(EntryTrackersViewController(entry: self.entry), animated: true)
//                }
//            ]),
//            SettingGroup(
//                id: "notifications",
//                header: "Notifications",
//                footer: "A preferred source must be selected for notifications be recieved.",
//                items: [
//                    ToggleSettingItem(
//                        id: "notificationsEnabled",
//                        title: "Notifications",
//                        value: LibraryManager.shared.isNotifying(mediaType: entry.mediaType, id: entry._id)
//                    ) { [weak self] newValue in
//                        guard let self else { return }
//                        if newValue {
//                            if let source = self.preferredSource {
//                                Task {
//                                    _ = await SoshikiAPI.shared.addNotificationEntry(
//                                        mediaType: self.entry.mediaType,
//                                        id: self.entry._id,
//                                        source: source
//                                    )
//                                    await LibraryManager.shared.refreshUser()
//                                }
//                            }
//                        } else {
//                            Task {
//                                _ = await SoshikiAPI.shared.removeNotificationEntry(mediaType: self.entry.mediaType, id: self.entry._id)
//                                await LibraryManager.shared.refreshUser()
//                            }
//                        }
//                    }
//                ]
//            )
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
