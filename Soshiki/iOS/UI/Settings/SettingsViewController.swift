//
//  SettingsViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/23/23.
//

import UIKit

class SettingsViewController: UITableViewController {
    var observers: [NSObjectProtocol] = []

    init() {
        super.init(style: .insetGrouped)
        self.title = "Settings"

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        observers.append(
            NotificationCenter.default.addObserver(forName: .init(SoshikiAPI.Keys.loggedIn), object: nil, queue: nil) { [weak self] _ in
                self?.tableView.reloadData()
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init(SoshikiAPI.Keys.loggedOut), object: nil, queue: nil) { [weak self] _ in
                self?.tableView.reloadData()
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

extension SettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 1
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Account"
        case 1: return "Sources"
        case 2: return "Trackers"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        switch indexPath.section {
        case 0:
            content.text = SoshikiAPI.shared.token == nil ? "Login" : "Logout"
            content.textProperties.color = .tintColor
        case 1:
            content.text = "Sources"
            cell.accessoryType = .disclosureIndicator
        case 2:
            content.text = "Trackers"
            cell.accessoryType = .disclosureIndicator
        default: break
        }
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if SoshikiAPI.shared.token == nil {
                present(SoshikiAPI.shared.loginViewController, animated: true)
            } else {
                SoshikiAPI.shared.logout()
            }
        case 1:
            navigationController?.pushViewController(SourcesViewController(), animated: true)
        case 2:
            navigationController?.pushViewController(TrackersViewController(), animated: true)
        default: break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
