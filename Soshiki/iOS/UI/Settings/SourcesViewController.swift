//
//  SourcesViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/23/23.
//

import UIKit

class SourcesViewController: UITableViewController {
    var observers: [NSObjectProtocol] = []

    var addSourceText = ""

    var textSources: [any Source] { SourceManager.shared.textSources.filter({ $0 is any NetworkSource }) }
    var imageSources: [any Source] { SourceManager.shared.imageSources.filter({ $0 is any NetworkSource }) }
    var videoSources: [any Source] { SourceManager.shared.videoSources.filter({ $0 is any NetworkSource }) }

    init() {
        super.init(style: .insetGrouped)
        self.title = "Sources"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")

        observers.append(
            NotificationCenter.default.addObserver(forName: .init(SourceManager.Keys.update), object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.tableView.reloadData()
                }
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

    override func viewDidLoad() {
        super.viewDidLoad()
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(alertAddSource))
        self.navigationItem.rightBarButtonItem = addButton
    }

    @objc func alertAddSource() {
        let alert = UIAlertController(title: "Install a Source", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Source URL"
            textField.delegate = self
        })
        let doneAction = UIAlertAction(title: "Install", style: .default, handler: { [weak self] _ in
            if let self, let url = URL(string: self.addSourceText) {
                if url.pathExtension == "soshikisource" {
                    Task {
                        await SourceManager.shared.installSource(url)
                    }
                } else if url.pathExtension == "soshikisources" {
                    Task {
                        await SourceManager.shared.installSources(url)
                    }
                }
            }
            self?.addSourceText = ""
        })
        alert.addAction(doneAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.addSourceText = ""
        }
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
}

extension SourcesViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return textSources.count
        case 1: return imageSources.count
        case 2: return videoSources.count
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return SourceTableViewCell(source: textSources[indexPath.item], reuseIdentifier: "SourceTableViewCell")
        case 1: return SourceTableViewCell(source: imageSources[indexPath.item], reuseIdentifier: "SourceTableViewCell")
        case 2: return SourceTableViewCell(source: videoSources[indexPath.item], reuseIdentifier: "SourceTableViewCell")
        default: return tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 72 }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            switch indexPath.section {
            case 0: SourceManager.shared.removeSource(id: textSources[indexPath.item].id)
            case 1: SourceManager.shared.removeSource(id: imageSources[indexPath.item].id)
            case 2: SourceManager.shared.removeSource(id: videoSources[indexPath.item].id)
            default: break
            }
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Text"
        case 1: return "Image"
        case 2: return "Video"
        default: return nil
        }
    }
}

extension SourcesViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        addSourceText = textField.text ?? ""
    }
}
