//
//  ImageReaderSettingsViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/28/23.
//

import UIKit

class ImageReaderSettingsViewController: SettingTableViewController {
    var settingGroups: [SettingGroup] {
        [
            SettingGroup(id: "general", header: "General", items: [
                SelectSettingItem(
                    id: "readingMode",
                    title: "Reading Mode",
                    value: ImageReaderViewController.ReadingMode.allCases.map({
                        SourceSelectFilterOption(id: $0.rawValue, name: $0.rawValue, selected: $0 == self.readingMode)
                    })
                ) { item in
                    UserDefaults.standard.set(item.value.first(where: { $0.selected })?.id, forKey: "settings.image.readingMode")
                    NotificationCenter.default.post(name: .init("settings.image.readingMode"), object: nil)
                }
            ])
        ]
    }

    var readingMode = (UserDefaults.standard.object(forKey: "settings.image.readingMode") as? String).flatMap({
        ImageReaderViewController.ReadingMode(rawValue: $0)
    }) ?? .rightToLeftPaged

    init() {
        super.init(title: "Settings")

        self.groups = settingGroups

        super.addObserver("settings.image.readingMode") { [weak self] _ in
            self?.readingMode = (UserDefaults.standard.object(forKey: "settings.image.readingMode") as? String).flatMap({
                ImageReaderViewController.ReadingMode(rawValue: $0)
            }) ?? .rightToLeftPaged
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
