//
//  SettingTableViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/5/23.
//

import UIKit

class SettingTableViewController: BaseViewController {
    var groups: [SettingGroup] = []

    let tableView: UITableView

    init(title: String) {
        self.tableView = UITableView(frame: .zero, style: .insetGrouped)

        super.init()

        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = self.tableView
    }

    override func configureViews() {
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
}

// MARK: - SettingTableViewController + UITableViewDataSource

extension SettingTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { groups.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groups[safe: section]?.items.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = groups[safe: indexPath.section]?.items[safe: indexPath.item] {
            return SettingItemTableViewCell(item: item)
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        groups[safe: section]?.header
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        groups[safe: section]?.footer
    }
}

// MARK: SettingTableViewController + UITableViewDelegate

extension SettingTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? SettingItemTableViewCell)?.didSelect()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
