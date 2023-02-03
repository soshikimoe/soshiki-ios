//
//  SourceFiltersViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/28/23.
//

import UIKit

class SourceFiltersViewController: UITableViewController {
    var filters: [any SourceFilter] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    let updateHandler: (any SourceFilter) -> Void

    init(updateHandler: @escaping (any SourceFilter) -> Void) {
        self.updateHandler = updateHandler
        super.init(style: .insetGrouped)
        self.title = "Filters"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.rowHeight = UITableView.automaticDimension
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SourceFiltersViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { filters.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        FilterTableViewCell(filter: filters[indexPath.section]) { [weak self] filter in
            self?.filters[indexPath.section] = filter
            self?.updateHandler(filter)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? FilterTableViewCell)?.didSelect()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
