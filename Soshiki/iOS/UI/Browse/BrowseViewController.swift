//
//  BrowseViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/28/23.
//

import UIKit

class BrowseViewController: UITableViewController {
    var observers: [NSObjectProtocol] = []

    init() {
        super.init(style: .insetGrouped)
        self.title = "Browse"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")

        observers.append(
            NotificationCenter.default.addObserver(forName: .init(SourceManager.Keys.update), object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.tableView.reloadData()
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
}

extension BrowseViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return SourceManager.shared.textSources.count
        case 1: return SourceManager.shared.imageSources.count
        case 2: return SourceManager.shared.videoSources.count
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Text"
        case 1: return "Image"
        case 2: return "Video"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = SourceTableViewCell(source: SourceManager.shared.textSources[indexPath.item], reuseIdentifier: "SourceTableViewCell")
            cell.accessoryType = .disclosureIndicator
            return cell
        case 1:
            let cell = SourceTableViewCell(source: SourceManager.shared.imageSources[indexPath.item], reuseIdentifier: "SourceTableViewCell")
            cell.accessoryType = .disclosureIndicator
            return cell
        case 2:
            let cell = SourceTableViewCell(source: SourceManager.shared.videoSources[indexPath.item], reuseIdentifier: "SourceTableViewCell")
            cell.accessoryType = .disclosureIndicator
            return cell
        default: return tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if let source = SourceManager.shared.textSources[indexPath.item] as? JSTextSource {
                self.navigationController?.pushViewController(
                    DiscoverViewController(source: source),
                    animated: true
                )
            }
        case 1:
            if let source = SourceManager.shared.imageSources[indexPath.item] as? JSImageSource {
                self.navigationController?.pushViewController(
                    DiscoverViewController(source: source),
                    animated: true
                )
            }
        case 2:
            if let source = SourceManager.shared.videoSources[indexPath.item] as? JSVideoSource {
                self.navigationController?.pushViewController(
                    DiscoverViewController(source: source),
                    animated: true
                )
            }
        default: break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return SourceManager.shared.textSources[indexPath.item] is any NetworkSource ? 72 : 44
        case 1: return SourceManager.shared.imageSources[indexPath.item] is any NetworkSource ? 72 : 44
        case 2: return SourceManager.shared.videoSources[indexPath.item] is any NetworkSource ? 72 : 44
        default: return 44
        }
    }
}
