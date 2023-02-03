//
//  VideoPlayerSettingsViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/27/23.
//

import UIKit

class VideoPlayerSettingsViewController: UITableViewController {
    var observers: [NSObjectProtocol] = []

    var autoPlay = UserDefaults.standard.object(forKey: "settings.video.autoPlay") as? Bool ?? true
    var autoNextEpisode = UserDefaults.standard.object(forKey: "settings.video.autoNextEpisode") as? Bool ?? true
    var persistTimestamp = UserDefaults.standard.object(forKey: "settings.video.persistTimestamp") as? Bool ?? false

    let urls: [(quality: Double?, urls: [(provider: String, url: String)])]
    var urlHeaderPoints: [Int] = []
    var currentlyPlayingUrl: URL?

    init(providers: [VideoSourceEpisodeProvider], currentlyPlayingUrl: URL?) {
        self.urls = VideoPlayerSettingsViewController.providerUrlsByQuality(providers)
        self.currentlyPlayingUrl = currentlyPlayingUrl
        super.init(style: .insetGrouped)
        self.title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")

        var at = 0
        for url in urls {
            urlHeaderPoints.append(at)
            at += url.urls.count + 1
        }

        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.video.autoPlay"), object: nil, queue: nil) { [weak self] _ in
                self?.autoPlay = UserDefaults.standard.object(forKey: "settings.video.autoPlay") as? Bool ?? true
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.video.autoNextEpisode"), object: nil, queue: nil) { [weak self] _ in
                self?.autoNextEpisode = UserDefaults.standard.object(forKey: "settings.video.autoNextEpisode") as? Bool ?? true
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.video.persistTimestamp"), object: nil, queue: nil) { [weak self] _ in
                self?.persistTimestamp = UserDefaults.standard.object(forKey: "settings.video.persistTimestamp") as? Bool ?? true
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.video.provider"), object: nil, queue: nil) { [weak self] notification in
                if let url = notification.object as? URL? {
                    self?.currentlyPlayingUrl = url
                }
            }
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    static func providerUrlsByQuality(_ providers: [VideoSourceEpisodeProvider]) -> [(quality: Double?, urls: [(provider: String, url: String)])] {
        var byQuality = [(quality: Double?, urls: [(provider: String, url: String)])]()
        for provider in providers {
            for url in provider.urls {
                if let index = byQuality.firstIndex(where: { $0.quality == url.quality }) {
                    byQuality[index].urls.append((provider: provider.name, url: url.url))
                } else {
                    byQuality.append((quality: url.quality, urls: [(provider: provider.name, url: url.url)]))
                }
            }
        }
        return byQuality.sorted(by: { quality1, quality2 in
            (quality1.quality ?? 0) > (quality2.quality ?? 0)
        })
    }

    @objc func toggleAutoPlay(_ sender: UISwitch) {
        UserDefaults.standard.setValue(sender.isOn, forKey: "settings.video.autoPlay")
        NotificationCenter.default.post(name: .init("settings.video.autoPlay"), object: nil)
    }

    @objc func toggleAutoNextEpisode(_ sender: UISwitch) {
        UserDefaults.standard.setValue(sender.isOn, forKey: "settings.video.autoNextEpisode")
        NotificationCenter.default.post(name: .init("settings.video.autoNextEpisode"), object: nil)
    }

    @objc func togglePersistTimestamp(_ sender: UISwitch) {
        UserDefaults.standard.setValue(sender.isOn, forKey: "settings.video.persistTimestamp")
        NotificationCenter.default.post(name: .init("settings.video.persistTimestamp"), object: nil)
    }
}

extension VideoPlayerSettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 3 : urls.count + urls.reduce(0, { accum, item in accum + item.urls.count })
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        var content = cell.defaultContentConfiguration()

        if indexPath.section == 0 {
            let toggle = UISwitch()
            switch indexPath.item {
            case 0:
                content.text = "Auto Play on Open"
                toggle.isOn = autoPlay
                toggle.addTarget(self, action: #selector(toggleAutoPlay(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            case 1:
                content.text = "Auto Play Next Episode"
                toggle.isOn = autoNextEpisode
                toggle.addTarget(self, action: #selector(toggleAutoNextEpisode(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            case 2:
                content.text = "Persist Time on Server Change"
                toggle.isOn = persistTimestamp
                toggle.addTarget(self, action: #selector(togglePersistTimestamp(_:)), for: .valueChanged)
                cell.accessoryView = toggle
            default: break
            }
        } else {
            if urlHeaderPoints.contains(indexPath.item) {
                guard let quality = urlHeaderPoints.firstIndex(of: indexPath.item).flatMap({ urls[safe: $0] }) else { return cell }
                content.text = quality.quality.flatMap({ "\($0.toTruncatedString())p" }) ?? "Unknown Quality"
                cell.selectionStyle = .none
                cell.indentationLevel = 0
                cell.accessoryView = nil
            } else {
                let offset = urlHeaderPoints.firstIndex(where: { $0 > indexPath.item }) ?? urlHeaderPoints.count
                guard offset > 0,
                      let url = urls[safe: offset - 1]?.urls[
                        safe: indexPath.item - offset - urls.enumerated().filter({ $0.offset < offset - 1 }).reduce(0, { accum, item in
                            accum + item.element.urls.count
                        })
                      ] else { return cell }
                content.text = url.provider
                cell.selectionStyle = .default
                cell.indentationLevel = 1
                if currentlyPlayingUrl?.absoluteString == url.url {
                    cell.accessoryView = UIImageView(image: UIImage(systemName: "checkmark"))
                } else {
                    cell.accessoryView = nil
                }
            }
        }
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let offset = urlHeaderPoints.firstIndex(where: { $0 > indexPath.item }) ?? urlHeaderPoints.count
        if !urlHeaderPoints.contains(indexPath.item),
           let url = urls[safe: offset - 1]?.urls[
             safe: indexPath.item - offset - urls.enumerated().filter({ $0.offset < offset - 1 }).reduce(0, { accum, item in
                 accum + item.element.urls.count
             })
           ].flatMap({ URL(string: $0.url) }) {
            NotificationCenter.default.post(name: .init("settings.video.provider"), object: url)
            tableView.reloadSections(IndexSet(integer: 1), with: .none)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "General" : "Provider"
    }
}
