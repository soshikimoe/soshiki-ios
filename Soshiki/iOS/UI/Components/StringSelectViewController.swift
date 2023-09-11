//
//  StringSelectViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/28/23.
//

import UIKit

class StringSelectViewController: UITableViewController {
    var options: [SourceSelectFilterOption]

    enum IndicatorType {
        case includeExclude
        case ascendDescend
    }
    let indicatorType: IndicatorType

    let canExcludeOrAscend: Bool

    let canSelectMultiple: Bool

    var handler: () -> Void

    init(title: String, options: [SourceSelectFilterOption], tristate: Bool, multi: Bool, type: IndicatorType, handler: @escaping () -> Void) {
        self.options = options
        self.canExcludeOrAscend = tristate
        self.canSelectMultiple = multi
        self.indicatorType = type
        self.handler = handler
        super.init(style: .insetGrouped)
        self.title = title
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StringSelectViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let option = self.options[indexPath.item]
        content.text = option.name
        if option.selected {
            let excludedOrAscended = option.excluded ?? option.ascending ?? false
            if self.indicatorType == .includeExclude {
                cell.accessoryView = UIImageView(image: UIImage(systemName: excludedOrAscended ? "xmark" : "checkmark"))
            } else {
                cell.accessoryView = UIImageView(image: UIImage(systemName: excludedOrAscended ? "chevron.up" : "chevron.down"))
            }
        } else {
            cell.accessoryView = nil
        }
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = self.options[indexPath.item]

        if !self.canSelectMultiple, let currentlySelected = self.options.first(where: { $0.selected }) {
            currentlySelected.selected = false
        }

        if !option.selected {
            option.selected = true
        } else {
            if self.canExcludeOrAscend {
                if self.indicatorType == .includeExclude {
                    if option.excluded == true {
                        option.excluded = false
                        option.selected = false
                    } else {
                        option.excluded = true
                    }
                } else {
                    if option.ascending == true {
                        option.ascending = false
                        option.selected = false
                    } else {
                        option.ascending = true
                    }
                }
            } else {
                option.selected = false
            }
        }

        handler()
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
    }
}
