//
//  TextReaderSettingsViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/28/23.
//

import UIKit

class TextReaderSettingsViewController: UITableViewController {
    var observers: [NSObjectProtocol] = []

    var fontSize = UserDefaults.standard.object(forKey: "settings.text.fontSize") as? Double ?? 40
    var margin = UserDefaults.standard.object(forKey: "settings.text.margin") as? Double ?? 80
    var font = UserDefaults.standard.string(forKey: "settings.text.font") ?? "Georgia"
    var fontColor = UserDefaults.standard.string(forKey: "settings.text.fontColor").flatMap({ UIColor.from(rawValue: $0) }) ?? .label
    var backgroundColor = UserDefaults.standard.string(forKey: "settings.text.backgroundColor").flatMap({
        UIColor.from(rawValue: $0)
    }) ?? .systemBackground

    init() {
        super.init(style: .insetGrouped)
        self.title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")

        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.text.fontSize"), object: nil, queue: nil) { [weak self] _ in
                self?.fontSize = UserDefaults.standard.object(forKey: "settings.text.fontSize") as? Double ?? 40
                self?.tableView.reloadRows(at: [IndexPath(item: 0, section: 0)], with: .none)
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.text.margin"), object: nil, queue: nil) { [weak self] _ in
                self?.margin = UserDefaults.standard.object(forKey: "settings.text.margin") as? Double ?? 80
                self?.tableView.reloadRows(at: [IndexPath(item: 1, section: 0)], with: .none)
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.text.font"), object: nil, queue: nil) { [weak self] _ in
                self?.font = UserDefaults.standard.string(forKey: "settings.text.font") ?? "Georgia"
                self?.tableView.reloadSections(IndexSet(integer: 1), with: .none)
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.text.fontColor"), object: nil, queue: nil) { [weak self] _ in
                self?.fontColor = UserDefaults.standard.string(forKey: "settings.text.fontColor").flatMap({ UIColor.from(rawValue: $0) }) ?? .label
                self?.tableView.reloadRows(at: [IndexPath(item: 2, section: 0)], with: .none)
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.text.backgroundColor"), object: nil, queue: nil) { [weak self] _ in
                self?.backgroundColor = UserDefaults.standard.string(forKey: "settings.text.backgroundColor").flatMap({
                    UIColor.from(rawValue: $0)
                }) ?? .systemBackground
                self?.tableView.reloadRows(at: [IndexPath(item: 3, section: 0)], with: .none)
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

    @objc func stepperDidChangeValue(_ sender: UIStepper) {
        if sender.tag == 0 {
            UserDefaults.standard.set(sender.value, forKey: "settings.text.fontSize")
            NotificationCenter.default.post(name: .init("settings.text.fontSize"), object: nil)
        } else {
            UserDefaults.standard.set(sender.value, forKey: "settings.text.margin")
            NotificationCenter.default.post(name: .init("settings.text.margin"), object: nil)
        }
    }

    @objc func colorWellDidChangeValue(_ sender: UIColorWell) {
        if sender.tag == 0 {
            UserDefaults.standard.set(sender.selectedColor?.rawValue, forKey: "settings.text.fontColor")
            NotificationCenter.default.post(name: .init("settings.text.fontColor"), object: nil)
        } else {
            UserDefaults.standard.set(sender.selectedColor?.rawValue, forKey: "settings.text.backgroundColor")
            NotificationCenter.default.post(name: .init("settings.text.backgroundColor"), object: nil)
        }
    }
}

extension TextReaderSettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 4 : UIFont.familyNames.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell

        if indexPath.section == 0 {
            switch indexPath.item {
            case 0:
                cell = UITableViewCell(style: .value1, reuseIdentifier: "UITableViewCellValue1")
                var content = cell.defaultContentConfiguration()
                content.text = "Font Size"
                content.secondaryText = fontSize.toTruncatedString()
                let stepper = UIStepper()
                stepper.value = fontSize
                stepper.minimumValue = 20
                stepper.maximumValue = 100
                stepper.stepValue = 5
                stepper.tag = 0
                stepper.addTarget(self, action: #selector(stepperDidChangeValue(_:)), for: .valueChanged)
                cell.accessoryView = stepper
                cell.contentConfiguration = content
            case 1:
                cell = UITableViewCell(style: .value1, reuseIdentifier: "UITableViewCellValue1")
                var content = cell.defaultContentConfiguration()
                content.text = "Margin"
                content.secondaryText = margin.toTruncatedString()
                let stepper = UIStepper()
                stepper.value = margin
                stepper.minimumValue = 0
                stepper.maximumValue = 200
                stepper.stepValue = 10
                stepper.tag = 1
                stepper.addTarget(self, action: #selector(stepperDidChangeValue(_:)), for: .valueChanged)
                cell.accessoryView = stepper
                cell.contentConfiguration = content
            case 2:
                let colorWell = UIColorWell()
                colorWell.selectedColor = fontColor
                colorWell.tag = 0
                colorWell.addTarget(self, action: #selector(colorWellDidChangeValue(_:)), for: .valueChanged)
                cell =  ColorPickerTableViewCell(title: "Font Color", colorWell: colorWell, reuseIdentifier: "ColorPickerTableViewCell")
            case 3:
                let colorWell = UIColorWell()
                colorWell.selectedColor = backgroundColor
                colorWell.tag = 1
                colorWell.addTarget(self, action: #selector(colorWellDidChangeValue(_:)), for: .valueChanged)
                cell =  ColorPickerTableViewCell(title: "Background Color", colorWell: colorWell, reuseIdentifier: "ColorPickerTableViewCell")
            default:
                cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            }
            cell.selectionStyle = .none
        } else {
            let family = UIFont.familyNames[indexPath.item]
            cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = family
            if let font = UIFont.fontNames(forFamilyName: family).first.flatMap({ UIFont(name: $0, size: 17) }) {
                content.textProperties.font = font
            }
            if family == font {
                cell.accessoryView = UIImageView(image: UIImage(systemName: "checkmark"))
            } else {
                cell.accessoryView = nil
            }
            cell.contentConfiguration = content
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            UserDefaults.standard.set(UIFont.familyNames[indexPath.item], forKey: "settings.text.font")
            NotificationCenter.default.post(name: .init("settings.text.font"), object: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "General" : "Font"
    }
}
