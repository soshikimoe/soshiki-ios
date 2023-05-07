//
//  StringSelectViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/28/23.
//

import UIKit

class StringSelectViewController: UITableViewController {
    let options: [String]
    var selected: [(String, Bool)]

    enum SelectionMode {
        case single
        case multiple
    }
    let selectionMode: SelectionMode

    enum IndicatorType {
        case includeExclude
        case ascendDescend
    }
    let indicatorType: IndicatorType

    let canExcludeOrAscend: Bool

    var singleHandler: ((String?) -> Void)?
    var singleExcludeOrAscendHandler: (((String, Bool)?) -> Void)?
    var multipleHandler: (([String]) -> Void)?
    var multipleExcludeOrAscendHandler: (([(String, Bool)]) -> Void)?

    init(title: String, options: [String], selected: String?, indicatorType: IndicatorType, handler: @escaping (String?) -> Void) {
        self.options = options
        self.selected = selected.flatMap({ [ ($0, false) ] }) ?? []
        self.selectionMode = .single
        self.indicatorType = indicatorType
        self.canExcludeOrAscend = false
        self.singleHandler = handler
        super.init(style: .insetGrouped)
        self.title = title
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    init(title: String, options: [String], selected: (String, Bool)?, indicatorType: IndicatorType, handler: @escaping ((String, Bool)?) -> Void) {
        self.options = options
        self.selected = selected.flatMap({ [ $0 ] }) ?? []
        self.selectionMode = .single
        self.indicatorType = indicatorType
        self.canExcludeOrAscend = true
        self.singleExcludeOrAscendHandler = handler
        super.init(style: .insetGrouped)
        self.title = title
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    init(title: String, options: [String], selected: [String], handler: @escaping ([String]) -> Void) {
        self.options = options
        self.selected = selected.map({ ($0, false) })
        self.selectionMode = .multiple
        self.indicatorType = .includeExclude
        self.canExcludeOrAscend = false
        self.multipleHandler = handler
        super.init(style: .insetGrouped)
        self.title = title
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    init(title: String, options: [String], selected: [(String, Bool)], handler: @escaping ([(String, Bool)]) -> Void) {
        self.options = options
        self.selected = selected
        self.selectionMode = .multiple
        self.indicatorType = .includeExclude
        self.canExcludeOrAscend = true
        self.multipleExcludeOrAscendHandler = handler
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
        options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let option = options[indexPath.item]
        content.text = option
        if let item = selected.first(where: { $0.0 == option }) {
            if indicatorType == .includeExclude {
                cell.accessoryView = UIImageView(image: UIImage(systemName: item.1 ? "xmark" : "checkmark"))
            } else {
                cell.accessoryView = UIImageView(image: UIImage(systemName: item.1 ? "chevron.up" : "chevron.down"))
            }
        } else {
            cell.accessoryView = nil
        }
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let index = selected.firstIndex(where: { $0.0 == options[indexPath.item] }) {
            if canExcludeOrAscend, selected[index].1 == false {
                selected[index].1 = true
            } else {
                selected.remove(at: index)
            }
        } else if selectionMode == .single, !selected.isEmpty {
            selected[0] = (options[indexPath.item], false)
        } else {
            selected.append((options[indexPath.item], false))
        }
        singleHandler?(selected.first.flatMap({ $0.0 }))
        singleExcludeOrAscendHandler?(selected.first)
        multipleHandler?(selected.map({ $0.0 }))
        multipleExcludeOrAscendHandler?(selected)
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
    }
}
