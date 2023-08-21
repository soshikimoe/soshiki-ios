//
//  LibraryCategoryEditViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/17/23.
//

import UIKit

class LibraryCategoryEditViewController: UITableViewController {
    var addCategoryText = ""

    var categories: [MediaType: [LibraryCategory]] = [:]

    init() {
        super.init(style: .insetGrouped)
        self.title = "Categories"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")

        reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadData() {
        for type in MediaType.allCases {
            self.categories[type] = DataManager.shared.getLibraryCategories(ofType: type)
        }
        self.tableView.reloadData()
    }

    func alertAddCategory(mediaType: MediaType) {
        let alert = UIAlertController(title: "New Category", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Category Name"
            textField.delegate = self
        })
        let doneAction = UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            if let self,
               !self.addCategoryText.isEmpty,
               self.categories[mediaType]?.contains(where: {
                   $0.id == self.addCategoryText.lowercased().replacingOccurrences(of: " ", with: "_")
               }) == false {
                DataManager.shared.addLibraryCategories([
                    LibraryCategory(
                        mediaType: mediaType,
                        id: self.addCategoryText.lowercased().replacingOccurrences(of: " ", with: "_"),
                        name: self.addCategoryText
                    )
                ], ofType: mediaType)
                self.reloadData()
            }
        })
        alert.addAction(doneAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
}

extension LibraryCategoryEditViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (self.categories[MediaType.allCases[section]]?.count ?? 0) + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            content.image = UIImage(systemName: "plus.circle.fill")?.applyingSymbolConfiguration(.preferringMulticolor())
            content.text = "New Category"
        } else {
            content.text = self.categories[MediaType.allCases[indexPath.section]]?[safe: indexPath.item]?.name
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
            guard let category = self.categories[MediaType.allCases[indexPath.section]]?[safe: indexPath.item] else { return }
            DataManager.shared.removeLibraryCategories([ category ], ofType: category.mediaType)
            reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        MediaType.allCases[section].rawValue.capitalized
    }
}

extension LibraryCategoryEditViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.addCategoryText = textField.text ?? ""
    }
}
