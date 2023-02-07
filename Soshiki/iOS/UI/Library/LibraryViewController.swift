//
//  LibraryViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/24/23.
//

import UIKit

class LibraryViewController: UICollectionViewController {
    var entries: [Entry] {
        if let category = LibraryManager.shared.category,
           let ids = LibraryManager.shared.library()?.categories.first(where: { $0.id == category.id })?.ids {
            return LibraryManager.shared.entries.filter({ ids.contains($0._id) })
        } else {
            return LibraryManager.shared.entries
        }
    }

    let refreshControl = UIRefreshControl()

    var dataSource: UICollectionViewDiffableDataSource<Int, Entry>!

    let categoryButton = UIBarButtonItem(image: UIImage(systemName: "folder"), style: .plain, target: nil, action: nil)
    let categoryLabel = UILabel()

    var observers: [NSObjectProtocol] = []

    init() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { _, environment in
            let itemsPerRow = UserDefaults.standard.object(forKey: "app.settings.itemsPerRow") as? Int ?? 3
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(CGFloat(1) / CGFloat(itemsPerRow)),
                    heightDimension: .fractionalWidth(CGFloat(1.5) / CGFloat(itemsPerRow))
                )
            )
            item.contentInsets = .init(top: 5, leading: 5, bottom: 5, trailing: 5)
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(environment.container.contentSize.width * 3 / 2)
                ),
                subitem: item,
                count: itemsPerRow
            )
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 5, leading: 5, bottom: 5, trailing: 5)
            return section
        })
        super.init(collectionViewLayout: layout)

        self.title = "Library"

        let cellRegistration: UICollectionView.CellRegistration<LibraryCollectionViewCell, Entry> = .init(handler: { cell, _, entry in
            cell.setEntry(entry: entry)
        })
        dataSource = UICollectionViewDiffableDataSource(
            collectionView: self.collectionView,
            cellProvider: { collectionView, indexPath, itemIdentifier in
                collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
            }
        )
        self.collectionView.dataSource = dataSource

        categoryLabel.text = "All - \(LibraryManager.shared.mediaType.rawValue.capitalized)"
        self.navigationItem.rightBarButtonItems = [ categoryButton, UIBarButtonItem(customView: categoryLabel) ]

        observers.append(
            NotificationCenter.default.addObserver(forName: .init(LibraryManager.Keys.libraries), object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.updateCategoryLabel()
                    self?.updateCategoryMenu()
                    self?.reloadCollectionViewData()
                }
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init(LibraryManager.Keys.mediaType), object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.updateCategoryLabel()
                    self?.updateCategoryMenu()
                    self?.reloadCollectionViewData()
                }
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init(LibraryManager.Keys.category), object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.updateCategoryLabel()
                    self?.updateCategoryMenu()
                    self?.reloadCollectionViewData()
                }
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("app.settings.itemsPerRow"), object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.collectionViewLayout.invalidateLayout()
                }
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

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.collectionView.refreshControl = refreshControl
    }

    @objc func refresh() {
        Task {
            await LibraryManager.shared.refresh()
            refreshControl.endRefreshing()
        }
    }

    func reloadCollectionViewData() {
        var snapshot = NSDiffableDataSourceSectionSnapshot<Entry>()
        snapshot.append(entries)
        dataSource.apply(snapshot, to: 0)
    }

    func updateCategoryLabel() {
        if let category = LibraryManager.shared.category {
            categoryLabel.text = "\(category.name) - \(LibraryManager.shared.mediaType.rawValue.capitalized)"
        } else {
            categoryLabel.text = "All - \(LibraryManager.shared.mediaType.rawValue.capitalized)"
        }
    }

    func updateCategoryMenu() {
        if let libraries = LibraryManager.shared.libraries {
            var actions: [UIMenuElement] = MediaType.allCases.map({ mediaType in
                let library = mediaType == .text ? libraries.text : mediaType == .image ? libraries.image : libraries.video
                let actions = [
                    UIAction(
                        title: "All",
                        image: LibraryManager.shared.mediaType == mediaType && LibraryManager.shared.category == nil
                            ? UIImage(systemName: "checkmark")
                            : nil
                    ) { _ in
                        if LibraryManager.shared.mediaType != mediaType {
                            LibraryManager.shared.mediaType = mediaType
                        }
                        LibraryManager.shared.category = nil
                    }
                ] + library.categories.map({ category in
                    UIAction(
                        title: category.name,
                        image: LibraryManager.shared.mediaType == mediaType && LibraryManager.shared.category?.id == category.id
                            ? UIImage(systemName: "checkmark")
                            : nil
                    ) { _ in
                        if LibraryManager.shared.mediaType != mediaType {
                            LibraryManager.shared.mediaType = mediaType
                        }
                        LibraryManager.shared.category = category
                    }
                })
                return UIMenu(title: mediaType.rawValue.capitalized, children: actions)
            })
            actions.append(
                UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { [weak self] _ in
                    self?.navigationController?.pushViewController(LibraryCategoryEditViewController(), animated: true)
                }
            )
            categoryButton.menu = UIMenu(children: actions)
        } else {
            categoryButton.menu = nil
        }
    }
}

extension LibraryViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let entry = entries[safe: indexPath.item] {
            self.navigationController?.pushViewController(EntryViewController(entry: entry), animated: true)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
