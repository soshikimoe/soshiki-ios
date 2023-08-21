//
//  LibraryViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/24/23.
//

import UIKit

class LibraryViewController_Old: UICollectionViewController {
    var entries: [Entry_Old] {
        []
//        if let category = LibraryManager.shared.category,
//           let ids = LibraryManager.shared.library()?.categories.first(where: { $0.id == category.id })?.ids {
//            return LibraryManager.shared.entries.filter({ ids.contains($0._id) })
//        } else {
//            return LibraryManager.shared.entries
//        }
    }

    var notificationBadges: [String: Int] = [:]

    let refreshControl = UIRefreshControl()

    var dataSource: UICollectionViewDiffableDataSource<Int, Entry_Old>!

    let categoryButton = UIBarButtonItem(image: UIImage(systemName: "folder"), style: .plain, target: nil, action: nil)
    let categoryLabel = UILabel()

    var observers: [NSObjectProtocol] = []

    init() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { _, environment in
            let itemsPerRow = UserDefaults.standard.object(forKey: "app.settings.itemsPerRow") as? Int ?? 3
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(environment.container.contentSize.width / CGFloat(itemsPerRow) * 1.5 + 40)
                ),
                subitem: NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(CGFloat(1) / CGFloat(itemsPerRow)),
                        heightDimension: .estimated(environment.container.contentSize.width / CGFloat(itemsPerRow) * 1.5 + 40)
                    )
                ),
                count: itemsPerRow
            )
            group.interItemSpacing = .fixed(16)
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 16
            section.contentInsets = NSDirectionalEdgeInsets(all: 8)
            return section
        })
        super.init(collectionViewLayout: layout)

        self.title = "Library"

        let cellRegistration: UICollectionView.CellRegistration<EntryCollectionViewCell, Entry_Old> = .init(handler: { _, _, _ in
            // cell.setEntry(to: entry.toSourceEntry())
//            if let notificationBadge = self.notificationBadges[entry._id] {
//                cell.setNotificationBadge(to: notificationBadge)
//            } else {
//                cell.setNotificationBadge(to: 0)
//            }
        })
        dataSource = UICollectionViewDiffableDataSource(
            collectionView: self.collectionView,
            cellProvider: { collectionView, indexPath, itemIdentifier in
                collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
            }
        )
        self.collectionView.dataSource = dataSource

        // categoryLabel.text = "All - \(LibraryManager.shared.mediaType.rawValue.capitalized)"
        self.navigationItem.rightBarButtonItems = [ categoryButton, UIBarButtonItem(customView: categoryLabel) ]
        Task {
            await reloadNotificationBadges()
        }

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
//        observers.append(
//            NotificationCenter.default.addObserver(forName: .init("app.openToEntry"), object: nil, queue: nil) { [weak self] notification in
//                if let entry = notification.object as? Entry_Old {
//                    self?.navigationController?.pushViewController(EntryViewController_Old(entry: entry), animated: true)
//                }
//            }
//        )
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
            // await LibraryManager.shared.refresh()
            await reloadNotificationBadges()
            refreshControl.endRefreshing()
        }
    }

    func reloadCollectionViewData() {
        var snapshot = NSDiffableDataSourceSectionSnapshot<Entry_Old>()
        snapshot.append(entries)
        dataSource.apply(snapshot, to: 0)
    }

    func updateCategoryLabel() {
//        if let category = LibraryManager.shared.category {
//            categoryLabel.text = "\(category.name) - \(LibraryManager.shared.mediaType.rawValue.capitalized)"
//        } else {
//            categoryLabel.text = "All - \(LibraryManager.shared.mediaType.rawValue.capitalized)"
//        }
    }

    func updateCategoryMenu() {
//        if let libraries = LibraryManager.shared.libraries {
//            var actions: [UIMenuElement] = MediaType.allCases.map({ mediaType in
//                let library = mediaType == .text ? libraries.text : mediaType == .image ? libraries.image : libraries.video
//                let actions = [
//                    UIAction(
//                        title: "All",
//                        image: LibraryManager.shared.mediaType == mediaType && LibraryManager.shared.category == nil
//                            ? UIImage(systemName: "checkmark")
//                            : nil
//                    ) { _ in
//                        if LibraryManager.shared.mediaType != mediaType {
//                            LibraryManager.shared.mediaType = mediaType
//                        }
//                        LibraryManager.shared.category = nil
//                    }
//                ] + library.categories.map({ category in
//                    UIAction(
//                        title: category.name,
//                        image: LibraryManager.shared.mediaType == mediaType && LibraryManager.shared.category?.id == category.id
//                            ? UIImage(systemName: "checkmark")
//                            : nil
//                    ) { _ in
//                        if LibraryManager.shared.mediaType != mediaType {
//                            LibraryManager.shared.mediaType = mediaType
//                        }
//                        LibraryManager.shared.category = category
//                    }
//                })
//                return UIMenu(title: mediaType.rawValue.capitalized, children: actions)
//            })
//            actions.append(
//                UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { [weak self] _ in
//                    self?.navigationController?.pushViewController(LibraryCategoryEditViewController(), animated: true)
//                }
//            )
//            categoryButton.menu = UIMenu(children: actions)
//        } else {
//            categoryButton.menu = nil
//        }
    }

    func reloadNotificationBadges() async {
        notificationBadges = [:]
        for notification in await UNUserNotificationCenter.current().deliveredNotifications() {
            if let id = notification.request.content.userInfo["id"] as? String {
                notificationBadges[id] = notification.request.content.userInfo["count"] as? Int ?? 0
            }
        }
        collectionView.reloadData()
    }
}

extension LibraryViewController_Old {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if let entry = entries[safe: indexPath.item] {
//            self.navigationController?.pushViewController(EntryViewController(entry: entry), animated: true)
//        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
