//
//  SettingTableViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/5/23.
//

import UIKit

class SettingTableViewController: UITableViewController {
    var groups: [SettingGroup] = []

    init(title: String) {
        super.init(style: .insetGrouped)
        self.title = title
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.rowHeight = UITableView.automaticDimension
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SettingTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { groups.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groups[safe: section]?.items.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = groups[safe: indexPath.section]?.items[safe: indexPath.item] {
            return SettingItemTableViewCell(item: item)
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        groups[safe: section]?.header
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        groups[safe: section]?.footer
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? SettingItemTableViewCell)?.didSelect()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
