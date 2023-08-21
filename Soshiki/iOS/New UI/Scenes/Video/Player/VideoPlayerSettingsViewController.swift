//
//  VideoPlayerSettingsViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/14/23.
//

import UIKit

class VideoPlayerSettingsViewController: SettingTableViewController {
    var settingGroups: [SettingGroup] {
        [
            SettingGroup(id: "general", header: "General", items: [
                ToggleSettingItem(id: "autoPlay", title: "Auto Play on Open", value: self.autoPlay) { item in
                    UserDefaults.standard.set(item.value, forKey: "settings.video.autoPlay")
                    NotificationCenter.default.post(name: .init("settings.video.autoPlay"), object: nil)
                },
                ToggleSettingItem(id: "autoNextEpisode", title: "Auto Play Next Episode", value: self.autoNextEpisode) { item in
                    UserDefaults.standard.set(item.value, forKey: "settings.video.autoNextEpisode")
                    NotificationCenter.default.post(name: .init("settings.video.autoNextEpisode"), object: nil)
                },
                ToggleSettingItem(id: "persistTimestamp", title: "Persist Time on Server Change", value: self.persistTimestamp) { item in
                    UserDefaults.standard.set(item.value, forKey: "settings.video.persistTimestamp")
                    NotificationCenter.default.post(name: .init("settings.video.persistTimestamp"), object: nil)
                },
                ToggleSettingItem(id: "showSkipButton", title: "Show Skip Button", value: self.showSkipButton) { item in
                    UserDefaults.standard.set(item.value, forKey: "settings.video.showSkipButton")
                    NotificationCenter.default.post(name: .init("settings.video.showSkipButton"), object: nil)
                },
                ToggleSettingItem(id: "simplePlayer", title: "Simple Player", value: self.simplePlayer) { item in
                    UserDefaults.standard.set(item.value, forKey: "settings.video.simplePlayer")
                    NotificationCenter.default.post(name: .init("settings.video.simplePlayer"), object: nil)
                },
                NumberSettingItem(
                    id: "endThreshold",
                    title: "Episode End Threshold",
                    value: Double(self.endThreshold),
                    lowerBound: 0,
                    upperBound: 180,
                    step: 5
                ) { item in
                    UserDefaults.standard.set(Int(item.value), forKey: "settings.video.endThreshold")
                    NotificationCenter.default.post(name: .init("settings.video.endThreshold"), object: nil)
                }
            ])
        ]
    }

    var autoPlay = UserDefaults.standard.object(forKey: "settings.video.autoPlay") as? Bool ?? true
    var autoNextEpisode = UserDefaults.standard.object(forKey: "settings.video.autoNextEpisode") as? Bool ?? true
    var persistTimestamp = UserDefaults.standard.object(forKey: "settings.video.persistTimestamp") as? Bool ?? true
    var showSkipButton = UserDefaults.standard.object(forKey: "settings.video.showSkipButton") as? Bool ?? true
    var simplePlayer = UserDefaults.standard.object(forKey: "settings.video.simplePlayer") as? Bool ?? false
    var endThreshold = UserDefaults.standard.object(forKey: "settings.video.endThreshold") as? Int ?? 30

    init() {
        super.init(title: "Settings")

        self.groups = settingGroups

        super.addObserver("settings.video.autoPlay") { [weak self] _ in
            self?.autoPlay = UserDefaults.standard.object(forKey: "settings.video.autoPlay") as? Bool ?? true
        }

        super.addObserver("settings.video.autoNextEpisode") { [weak self] _ in
            self?.autoNextEpisode = UserDefaults.standard.object(forKey: "settings.video.autoNextEpisode") as? Bool ?? true
        }

        super.addObserver("settings.video.persistTimestamp") { [weak self] _ in
            self?.persistTimestamp = UserDefaults.standard.object(forKey: "settings.video.persistTimestamp") as? Bool ?? true
        }

        super.addObserver("settings.video.showSkipButton") { [weak self] _ in
            self?.showSkipButton = UserDefaults.standard.object(forKey: "settings.video.showSkipButton") as? Bool ?? true
        }

        super.addObserver("settings.video.simplePlayer") { [weak self] _ in
            self?.simplePlayer = UserDefaults.standard.object(forKey: "settings.video.simplePlayer") as? Bool ?? false
        }

        super.addObserver("settings.video.endThreshold") { [weak self] _ in
            self?.endThreshold = UserDefaults.standard.object(forKey: "settings.video.endThreshold") as? Int ?? 30
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
