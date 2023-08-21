//
//  LibrarySeeMoreViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/17/23.
//

import UIKit

class LibrarySeeMoreViewController<EntryType: Entry>: BaseViewController {
    let category: LibraryCategory?
    var items: [LibraryItem]
    var entries: [EntryType]

    var collectionView: UICollectionView!
    var layout: UICollectionViewCompositionalLayout!
    var dataSource: UICollectionViewDiffableDataSource<Int, LibraryItem>!
    var delegate: Delegate!

    let refreshControl: UIRefreshControl

    init(items: [LibraryItem], entries: [EntryType], category: LibraryCategory? = nil) {
        self.category = category
        self.items = items
        self.entries = entries

        self.refreshControl = UIRefreshControl()

        super.init()

        self.layout = UICollectionViewCompositionalLayout(sectionProvider: { _, environment in
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

        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell")

        self.title = category?.name ?? "All"

        let cellRegistration = UICollectionView.CellRegistration<EntryCollectionViewCell, LibraryItem> { cell, _, item in
            if let entry = self.entries.first(where: { $0.sourceId == item.sourceId && $0.id == item.id }) {
                cell.setEntry(to: entry)
            }
        }

        self.dataSource = UICollectionViewDiffableDataSource(
            collectionView: self.collectionView,
            cellProvider: { collectionView, indexPath, entry in
                collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: entry)
            }
        )
        self.collectionView.dataSource = dataSource

        self.delegate = Self.Delegate(self)
        self.collectionView.delegate = self.delegate

        self.refresh()

        self.observers.append(
            NotificationCenter.default.addObserver(forName: .init("app.settings.itemsPerRow"), object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.layout.invalidateLayout()
                }
            }
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = self.collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.collectionView.refreshControl = refreshControl
    }

    @objc func refresh() {
        if let category {
            self.items = DataManager.shared.getLibraryItems(ofType: category.mediaType, in: category.id)
        } else {
            self.items = DataManager.shared.getLibraryItems(
                ofType: EntryType.self is TextEntry.Type ? .text : EntryType.self is ImageEntry.Type ? .image : .video
            )
        }
        self.entries = DataManager.shared.getEntries(self.items)
        reloadCollectionViewData()
        refreshControl.endRefreshing()
    }

    func reloadCollectionViewData() {
        var snapshot = NSDiffableDataSourceSectionSnapshot<LibraryItem>()
        snapshot.append(self.items)
        self.dataSource.apply(snapshot, to: 0)
    }
}

extension LibrarySeeMoreViewController {
    class Delegate: NSObject, UICollectionViewDelegate {
        weak var parent: LibrarySeeMoreViewController?

        init(_ parent: LibrarySeeMoreViewController) {
            self.parent = parent
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            if let item = self.parent?.items[safe: indexPath.item],
               let entry = self.parent?.entries.first(where: { $0.sourceId == item.sourceId && $0.id == item.id }),
               let source = SourceManager.shared.sources.first(where: { $0.id == item.sourceId }) {
                self.parent?.navigationController?.pushViewController(
                    EntryViewController(entry: entry, source: source, libraryItem: item),
                    animated: true
                )
            }
            collectionView.deselectItem(at: indexPath, animated: false)
        }
    }
}
