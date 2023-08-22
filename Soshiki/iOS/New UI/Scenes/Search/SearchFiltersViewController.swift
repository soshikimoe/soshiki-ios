//
//  SearchFiltersViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/20/23.
//

import Foundation
import UIKit

class SearchFiltersViewController: BaseViewController {
    let filters: [SourceFilterGroup]
    let handler: () -> Void

    let tableView: UITableView

    init(filters: [SourceFilterGroup], handler: @escaping () -> Void) {
        self.filters = filters
        self.handler = handler

        self.tableView = UITableView(frame: .zero, style: .insetGrouped)

        super.init()

        self.title = "Filters"

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = self.tableView
    }
}

extension SearchFiltersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { self.filters.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.filters[section].filters.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        FilterTableViewCell(filter: self.filters[indexPath.section].filters[indexPath.item]) { [weak self] _ in
            self?.handler()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        self.filters[section].header
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        self.filters[section].footer
    }
}

extension SearchFiltersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? FilterTableViewCell)?.didSelect()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
