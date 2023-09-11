//
//  SourcesViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/23/23.
//

import UIKit
import Nuke
import NukeExtensions

class SourcesViewController: UITableViewController {
    var observers: [NSObjectProtocol] = []

    var addSourceText = ""

    var sourceLists: [String] { SourceManager.shared.sourceLists }

    var textSources: [any Source] { SourceManager.shared.textSources.filter({ $0 is any NetworkSource }) }
    var imageSources: [any Source] { SourceManager.shared.imageSources.filter({ $0 is any NetworkSource }) }
    var videoSources: [any Source] { SourceManager.shared.videoSources.filter({ $0 is any NetworkSource }) }

    var uninstalledTextSources: [TextSourceManifest] { SourceManager.shared.uninstalledTextSources }
    var uninstalledImageSources: [ImageSourceManifest] { SourceManager.shared.uninstalledImageSources }
    var uninstalledVideoSources: [VideoSourceManifest] { SourceManager.shared.uninstalledVideoSources }

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
    override func numberOfSections(in tableView: UITableView) -> Int { 4 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return sourceLists.count
        case 1: return textSources.count + uninstalledTextSources.count
        case 2: return imageSources.count + uninstalledImageSources.count
        case 3: return videoSources.count + uninstalledVideoSources.count
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.accessoryView = nil
        var configuration = cell.defaultContentConfiguration()
        switch indexPath.section {
        case 0:
            configuration.text = self.sourceLists[indexPath.item]
        case 1:
            if let source = self.textSources[safe: indexPath.item] {
                configuration.text = source.name
                configuration.secondaryText = (source as? any NetworkSource)?.author
                configuration.image = (source as? any NetworkSource).flatMap({ UIImage(contentsOfFile: $0.image.path) })
                configuration.imageProperties.cornerRadius = 10
                configuration.imageProperties.maximumSize = CGSize(width: 50, height: 50)
            } else if let source = self.uninstalledTextSources[safe: indexPath.item - self.textSources.count] {
                configuration.text = source.name
                configuration.secondaryText = source.author
                if let baseUrl = source.baseUrl, let url = URL(string: baseUrl)?.appendingPathComponent([
                    source.path.split(separator: "/").dropLast(1).joined(separator: "/"),
                    "res",
                    source.icon
                ].joined(separator: "/")) {
                    ImagePipeline.shared.loadImage(with: url) { response in
                        configuration.image = try? response.get().image
                        cell.contentConfiguration = configuration
                    }
                }
                configuration.imageProperties.cornerRadius = 10
                configuration.imageProperties.maximumSize = CGSize(width: 50, height: 50)
                cell.selectionStyle = .none
                cell.accessoryView = InstallButton("INSTALL") {
                    guard let baseUrl = source.baseUrl.flatMap({ URL(string: $0) }) else { return }
                    Task {
                        await SourceManager.shared.installSource(baseUrl.appendingPathComponent(source.path))
                    }
                }
            }
        case 2:
            if let source = self.imageSources[safe: indexPath.item] {
                configuration.text = source.name
                configuration.secondaryText = (source as? any NetworkSource)?.author
                configuration.image = (source as? any NetworkSource).flatMap({ UIImage(contentsOfFile: $0.image.path) })
                configuration.imageProperties.cornerRadius = 10
                configuration.imageProperties.maximumSize = CGSize(width: 50, height: 50)
            } else if let source = self.uninstalledImageSources[safe: indexPath.item - self.imageSources.count] {
                configuration.text = source.name
                configuration.secondaryText = source.author
                if let baseUrl = source.baseUrl, let url = URL(string: baseUrl)?.appendingPathComponent([
                    source.path.split(separator: "/").dropLast(1).joined(separator: "/"),
                    "res",
                    source.icon
                ].joined(separator: "/")) {
                    ImagePipeline.shared.loadImage(with: url) { response in
                        configuration.image = try? response.get().image
                        cell.contentConfiguration = configuration
                    }
                }
                configuration.imageProperties.cornerRadius = 10
                configuration.imageProperties.maximumSize = CGSize(width: 50, height: 50)
                cell.selectionStyle = .none
                cell.accessoryView = InstallButton("INSTALL") {
                    guard let baseUrl = source.baseUrl.flatMap({ URL(string: $0) }) else { return }
                    Task {
                        await SourceManager.shared.installSource(baseUrl.appendingPathComponent(source.path))
                    }
                }
            }
        case 3:
            if let source = self.videoSources[safe: indexPath.item] {
                configuration.text = source.name
                configuration.secondaryText = (source as? any NetworkSource)?.author
                configuration.image = (source as? any NetworkSource).flatMap({ UIImage(contentsOfFile: $0.image.path) })
                configuration.imageProperties.cornerRadius = 10
                configuration.imageProperties.maximumSize = CGSize(width: 50, height: 50)
            } else if let source = self.uninstalledVideoSources[safe: indexPath.item - self.videoSources.count] {
                configuration.text = source.name
                configuration.secondaryText = source.author
                if let baseUrl = source.baseUrl, let url = URL(string: baseUrl)?.appendingPathComponent([
                    source.path.split(separator: "/").dropLast(1).joined(separator: "/"),
                    "res",
                    source.icon
                ].joined(separator: "/")) {
                    ImagePipeline.shared.loadImage(with: url) { response in
                        configuration.image = try? response.get().image
                        cell.contentConfiguration = configuration
                    }
                }
                configuration.imageProperties.cornerRadius = 10
                configuration.imageProperties.maximumSize = CGSize(width: 50, height: 50)
                cell.selectionStyle = .none
                cell.accessoryView = InstallButton("INSTALL") {
                    guard let baseUrl = source.baseUrl.flatMap({ URL(string: $0) }) else { return }
                    Task {
                        await SourceManager.shared.installSource(baseUrl.appendingPathComponent(source.path))
                    }
                }
            }
        default: break
        }
        cell.contentConfiguration = configuration
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 72 }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            switch indexPath.section {
            case 0:
                let lists = self.sourceLists
                for source in DataManager.shared.getSources() as [TextSourceManifest] where source.baseUrl == lists[indexPath.item] {
                    DataManager.shared.removeSource(source)
                }
                for source in DataManager.shared.getSources() as [ImageSourceManifest] where source.baseUrl == lists[indexPath.item] {
                    DataManager.shared.removeSource(source)
                }
                for source in DataManager.shared.getSources() as [VideoSourceManifest] where source.baseUrl == lists[indexPath.item] {
                    DataManager.shared.removeSource(source)
                }
                NotificationCenter.default.post(name: .init(SourceManager.Keys.update), object: nil)
            case 1: SourceManager.shared.removeSource(id: textSources[indexPath.item].id)
            case 2: SourceManager.shared.removeSource(id: imageSources[indexPath.item].id)
            case 3: SourceManager.shared.removeSource(id: videoSources[indexPath.item].id)
            default: break
            }
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Source Lists"
        case 1: return "Text"
        case 2: return "Image"
        case 3: return "Video"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case 0: return true
        case 1: return self.textSources.indices.contains(indexPath.item)
        case 2: return self.imageSources.indices.contains(indexPath.item)
        case 3: return self.videoSources.indices.contains(indexPath.item)
        default: return false
        }
    }
}

extension SourcesViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        addSourceText = textField.text ?? ""
    }
}
