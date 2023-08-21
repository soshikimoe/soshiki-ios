//
//  LibraryCategoryEditViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/25/23.
//

import UIKit

class LibraryCategoryEditViewController_Old: UITableViewController {
    var observers: [NSObjectProtocol] = []

    var addCategoryText = ""

    init() {
        super.init(style: .insetGrouped)
        self.title = "Categories"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")

        observers.append(
            NotificationCenter.default.addObserver(forName: .init(LibraryManager.Keys.libraries), object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.tableView.reloadData()
                }
            }
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func alertAddCategory(mediaType: MediaType) {
        let alert = UIAlertController(title: "New Category", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Category Name"
            textField.delegate = self
        })
        let doneAction = UIAlertAction(title: "Add", style: .default, handler: { _ in
//            if let self,
//               !self.addCategoryText.isEmpty,
//               LibraryManager.shared.library(forMediaType: mediaType)?.categories.contains(where: { category in
//                   category.id == self.addCategoryText.lowercased().replacingOccurrences(of: " ", with: "_")
//               }) == false {
//                Task {
//                    await SoshikiAPI.shared.addLibraryCategory(
//                        mediaType: mediaType,
//                        id: self.addCategoryText.lowercased().replacingOccurrences(of: " ", with: "_"),
//                        name: self.addCategoryText
//                    )
//                    await LibraryManager.shared.refreshLibraries()
//                    self.addCategoryText = ""
//                }
//            }
        })
        alert.addAction(doneAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
}

extension LibraryCategoryEditViewController_Old {
    override func numberOfSections(in tableView: UITableView) -> Int {
        0 // LibraryManager.shared.libraries == nil ? 0 : 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
//        case 0: return (LibraryManager.shared.libraries?.text.categories.count ?? -1) + 1
//        case 1: return (LibraryManager.shared.libraries?.image.categories.count ?? -1) + 1
//        case 2: return (LibraryManager.shared.libraries?.video.categories.count ?? -1) + 1
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            content.image = UIImage(systemName: "plus.circle.fill")?.applyingSymbolConfiguration(.preferringMulticolor())
            content.text = "New Category"
        } else {
            switch indexPath.section {
//            case 0: content.text = LibraryManager.shared.libraries?.text.categories[safe: indexPath.row]?.name ?? ""
//            case 1: content.text = LibraryManager.shared.libraries?.image.categories[safe: indexPath.row]?.name ?? ""
//            case 2: content.text = LibraryManager.shared.libraries?.video.categories[safe: indexPath.row]?.name ?? ""
            default: break
            }
        }
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            self.alertAddCategory(mediaType: indexPath.section == 0 ? .text : indexPath.section == 1 ? .image : .video)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete, indexPath.row != self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            // let category: LibraryCategory?
            switch indexPath.section {
//            case 0: category = LibraryManager.shared.libraries?.text.categories[safe: indexPath.row]
//            case 1: category = LibraryManager.shared.libraries?.image.categories[safe: indexPath.row]
//            case 2: category = LibraryManager.shared.libraries?.video.categories[safe: indexPath.row]
            default: return
            }
            // guard let category else { return }
            // Task {
//                await SoshikiAPI.shared.deleteLibraryCategory(
//                    mediaType: indexPath.section == 0 ? .text : indexPath.section == 1 ? .image : .video,
//                    id: category.id
//                )
//                await LibraryManager.shared.refreshLibraries()
            // }
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

extension LibraryCategoryEditViewController_Old: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.addCategoryText = textField.text ?? ""
    }
}
