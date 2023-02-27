//
//  EntrySettingsViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/5/23.
//

import UIKit

class EntrySettingsViewController: SettingTableViewController {
    let entry: Entry

    lazy var preferredSource: String? = LibraryManager.shared.preferredSource(mediaType: self.entry.mediaType, id: self.entry._id)

    init(entry: Entry) {
        self.entry = entry
        super.init(title: "Settings")

        self.groups = [
            SettingGroup(id: "trackers", header: "Trackers", items: [
                ButtonSettingItem(id: "trackers", title: "Trackers", presentsView: true) { [weak self] _ in
                    guard let self else { return }
                    self.navigationController?.pushViewController(EntryTrackersViewController(entry: self.entry), animated: true)
                }
            ]),
            SettingGroup(
                id: "notifications",
                header: "Notifications",
                footer: "A preferred source must be selected for notifications be recieved.",
                items: [
                    ToggleSettingItem(
                        id: "notificationsEnabled",
                        title: "Notifications",
                        value: LibraryManager.shared.isNotifying(mediaType: entry.mediaType, id: entry._id)
                    ) { [weak self] newValue in
                        guard let self else { return }
                        if newValue {
                            if let source = self.preferredSource {
                                Task {
                                    _ = await SoshikiAPI.shared.addNotificationEntry(
                                        mediaType: self.entry.mediaType,
                                        id: self.entry._id,
                                        source: source
                                    )
                                    await LibraryManager.shared.refreshUser()
                                }
                            }
                        } else {
                            Task {
                                _ = await SoshikiAPI.shared.removeNotificationEntry(mediaType: self.entry.mediaType, id: self.entry._id)
                                await LibraryManager.shared.refreshUser()
                            }
                        }
                    },
                    SelectSettingItem(
                        id: "preferredSource",
                        title: "Preferred Source",
                        value: preferredSource.flatMap({ source in SourceManager.shared.sources.first(where: { $0.id == source })?.name }),
                        options: SourceManager.shared.sources.compactMap({
                            entry.mediaType == .text
                                ? $0 as? any TextSource
                                : entry.mediaType == .image ? $0 as? any ImageSource : $0 as? any VideoSource
                        }).map({ $0.name })
                    ) { [weak self] newValue in
                        guard let self else { return }
                        self.preferredSource = SourceManager.shared.sources.first(where: { $0.name == newValue })?.id
                        if let source = self.preferredSource {
                            if LibraryManager.shared.isNotifying(mediaType: entry.mediaType, id: entry._id) {
                                Task {
                                    _ = await SoshikiAPI.shared.addNotificationEntry(
                                        mediaType: self.entry.mediaType,
                                        id: self.entry._id,
                                        source: source
                                    )
                                    await LibraryManager.shared.refreshUser()
                                }
                            }
                        } else {
                            Task {
                                _ = await SoshikiAPI.shared.removeNotificationEntry(mediaType: self.entry.mediaType, id: self.entry._id)
                                await LibraryManager.shared.refreshUser()
                            }
                        }
                    }
                ]
            )
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
