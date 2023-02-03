//
//  ImageReaderSettingsViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/31/22.
//

import UIKit

class ImageReaderSettingsViewController: UITableViewController {
    var observers: [NSObjectProtocol] = []

    var pagesToPreload = UserDefaults.standard.object(forKey: "settings.image.pagesToPreload") as? Int ?? 3
    var readingMode = UserDefaults.standard.string(forKey: "settings.image.readingMode").flatMap({ ReadingMode(rawValue: $0) }) ?? .rtl

    init() {
        super.init(style: .insetGrouped)
        self.title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")

        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.image.pagesToPreload"), object: nil, queue: nil) { [weak self] _ in
                self?.pagesToPreload = UserDefaults.standard.object(forKey: "settings.image.pagesToPreload") as? Int ?? 3
                self?.tableView.reloadRows(at: [ IndexPath(item: 1, section: 0) ], with: .none)
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.image.readingMode"), object: nil, queue: nil) { [weak self] _ in
                self?.readingMode = UserDefaults.standard.string(forKey: "settings.image.readingMode").flatMap({ ReadingMode(rawValue: $0) }) ?? .rtl
                self?.tableView.reloadRows(at: [ IndexPath(item: 0, section: 0) ], with: .none)
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

extension ImageReaderSettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 2 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { "General" }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "UITableViewCellValue1")
        var content = cell.defaultContentConfiguration()
        switch indexPath.item {
        case 0:
            content.text = "Reading Mode"
            content.secondaryText = readingMode.rawValue.capitalized
            cell.accessoryType = .disclosureIndicator
            cell.contentConfiguration = content
        case 1:
            content.text = "Pages to Preload"
            content.secondaryText = "\(pagesToPreload)"
            let stepper = UIStepper()
            stepper.minimumValue = 1
            stepper.maximumValue = 5
            stepper.value = Double(pagesToPreload)
            stepper.addTarget(self, action: #selector(stepperDidChangeValue(_:)), for: .valueChanged)
            stepper.isEnabled = true
            cell.contentConfiguration = content
            cell.accessoryView = stepper
            cell.selectionStyle = .none
        default: break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            present(ImageReaderReadingModeViewController(), animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc func stepperDidChangeValue(_ sender: UIStepper) {
        UserDefaults.standard.set(Int(sender.value), forKey: "settings.image.pagesToPreload")
        NotificationCenter.default.post(name: .init("settings.image.pagesToPreload"), object: nil)
        self.tableView.reloadRows(at: [ IndexPath(item: 1, section: 0) ], with: .none)
    }
}

class ImageReaderReadingModeViewController: UITableViewController {
    var readingMode = UserDefaults.standard.string(forKey: "settings.image.readingMode").flatMap({ ReadingMode(rawValue: $0) }) ?? .rtl {
        didSet {
            UserDefaults.standard.set(readingMode.rawValue, forKey: "settings.image.readingMode")
            NotificationCenter.default.post(name: .init("settings.image.readingMode"), object: nil)
        }
    }
    init() {
        super.init(style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ImageReaderReadingModeViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        ReadingMode.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let mode = ReadingMode.allCases[indexPath.item]
        content.text = mode.rawValue
        if mode == readingMode {
            cell.accessoryView = UIImageView(image: UIImage(systemName: "checkmark"))
        } else {
            cell.accessoryView = nil
        }
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        readingMode = ReadingMode.allCases[indexPath.item]
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
    }
}
