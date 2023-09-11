//
//  SourceSettingsViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/21/23.
//

import Foundation
import UIKit

class SourceSettingsViewController: BaseViewController {
    let settings: [SourceFilterGroup]
    let sourceId: String
    let handler: () -> Void

    let tableView: UITableView

    init(settings: [SourceFilterGroup], sourceId: String, handler: @escaping () -> Void) {
        self.settings = settings
        self.sourceId = sourceId
        self.handler = handler

        self.tableView = UITableView(frame: .zero, style: .insetGrouped)

        super.init()

        self.title = "Settings"

        self.tableView.delegate = self
        self.tableView.dataSource = self

        for settingGroup in settings {
            for setting in settingGroup.filters {
                switch setting {
                case .text(let setting):
                    if let value = UserDefaults.standard.value(forKey: "settings.source.\(sourceId).\(setting.id)").flatMap({
                        try? String.fromObject($0)
                    }) {
                        setting.value = value
                    }
                case .toggle(let setting):
                    if let value = UserDefaults.standard.value(forKey: "settings.source.\(sourceId).\(setting.id)").flatMap({
                        try? Bool.fromObject($0)
                    }) {
                        setting.value = value
                    }
                case .segment(let setting):
                    if let value = UserDefaults.standard.value(forKey: "settings.source.\(sourceId).\(setting.id)").flatMap({
                        try? [SourceSelectFilterOption].fromObject($0)
                    }) {
                        setting.value = value
                    }
                case .select(let setting):
                    if let value = UserDefaults.standard.value(forKey: "settings.source.\(sourceId).\(setting.id)").flatMap({
                        try? [SourceSelectFilterOption].fromObject($0)
                    }) {
                        setting.value = value
                    }
                case .excludableSelect(let setting):
                    if let value = UserDefaults.standard.value(forKey: "settings.source.\(sourceId).\(setting.id)").flatMap({
                        try? [SourceSelectFilterOption].fromObject($0)
                    }) {
                        setting.value = value
                    }
                case .multiSelect(let setting):
                    if let value = UserDefaults.standard.value(forKey: "settings.source.\(sourceId).\(setting.id)").flatMap({
                        try? [SourceSelectFilterOption].fromObject($0)
                    }) {
                        setting.value = value
                    }
                case .excludableMultiSelect(let setting):
                    if let value = UserDefaults.standard.value(forKey: "settings.source.\(sourceId).\(setting.id)").flatMap({
                        try? [SourceSelectFilterOption].fromObject($0)
                    }) {
                        setting.value = value
                    }
                case .sort(let setting):
                    if let value = UserDefaults.standard.value(forKey: "settings.source.\(sourceId).\(setting.id)").flatMap({
                        try? [SourceSelectFilterOption].fromObject($0)
                    }) {
                        setting.value = value
                    }
                case .ascendableSort(let setting):
                    if let value = UserDefaults.standard.value(forKey: "settings.source.\(sourceId).\(setting.id)").flatMap({
                        try? [SourceSelectFilterOption].fromObject($0)
                    }) {
                        setting.value = value
                    }
                case .number(let setting):
                    if let value = UserDefaults.standard.value(forKey: "settings.source.\(sourceId).\(setting.id)").flatMap({
                        try? Double.fromObject($0)
                    }) {
                        setting.value = value
                    }
                }
            }
        }

        self.tableView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = self.tableView
    }
}

extension SourceSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { self.settings.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.settings[section].filters.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        FilterTableViewCell(filter: self.settings[indexPath.section].filters[indexPath.item]) { [weak self] setting in
            if let sourceId = self?.sourceId, let object = try? setting.value.toObject() {
                UserDefaults.standard.set(object, forKey: "settings.source.\(sourceId).\(setting.id)")
            }
            self?.handler()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        self.settings[section].header
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        self.settings[section].footer
    }
}

extension SourceSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? FilterTableViewCell)?.didSelect()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
