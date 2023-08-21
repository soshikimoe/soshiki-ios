//
//  LibraryViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/15/23.
//

import UIKit

class LibraryViewController: BaseViewController {
    var mediaType: MediaType

    var entries: [any Entry]
    var items: [LibraryItem]
    var categories: [LibraryCategory]

    var collectionView: UICollectionView!
    var delegate: Delegate!
    let refreshControl: UIRefreshControl

    var layout: UICollectionViewCompositionalLayout!
    var dataSource: UICollectionViewDiffableDataSource<String, LibraryItem>!

    var isLandscape: Bool {
        self.view.frame.width > self.view.frame.height
    }

    override init() {
        self.refreshControl = UIRefreshControl()

        self.mediaType = LibraryManager.shared.mediaType

        self.entries = []
        self.items = []
        self.categories = []

        super.init()

        self.title = "Library"

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 8

        self.layout = UICollectionViewCompositionalLayout(sectionProvider: { _, _ in
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .fractionalHeight(1)
                )
            )
            item.contentInsets = NSDirectionalEdgeInsets(all: 8)
            let section = NSCollectionLayoutSection(
                group: NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .absolute(140),
                        heightDimension: .absolute(260)
                    ),
                    subitems: [ item ]
                )
            )
            section.contentInsets = NSDirectionalEdgeInsets(horizontal: 8)
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(40)
                ),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topLeading
            )
            header.contentInsets = NSDirectionalEdgeInsets(top: 8, left: 8)
            section.boundarySupplementaryItems = [ header ]
            section.orthogonalScrollingBehavior = .continuous
            section.decorationItems = [
                NSCollectionLayoutDecorationItem.background(elementKind: "DiscoverSectionBackgroundReusableView")
            ]
            return section
        }, configuration: configuration)

        self.layout.register(DiscoverSectionBackgroundReusableView.self, forDecorationViewOfKind: "DiscoverSectionBackgroundReusableView")

        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)

        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell")

        self.delegate = Self.Delegate(self)
        self.collectionView.delegate = self.delegate

        self.dataSource = configureDataSource()

        reloadData()

        refresh()

        super.addObserver(LibraryManager.Keys.mediaType) { [weak self] _ in
            self?.refresh()
        }

        super.addObserver("app.settings.discoverSource") { [weak self] _ in
            self?.refresh()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureViews() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.mediaType.rawValue.capitalized, menu: UIMenu(children: [
            UIMenu(title: "", options: .displayInline, children: MediaType.allCases.map({ type in
                UIAction(title: type.rawValue.capitalized) { [weak self] _ in
                    self?.mediaType = type
                    self?.navigationItem.rightBarButtonItem?.title = type.rawValue.capitalized
                    self?.refresh()
                }
            })),
            UIAction(title: "Edit Categories", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.navigationController?.pushViewController(LibraryCategoryEditViewController(), animated: true)
            }
        ]))

        self.refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        self.collectionView.refreshControl = self.refreshControl

        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.showsHorizontalScrollIndicator = false

        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.collectionView)
    }

    override func applyConstraints() {
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }

    func configureDataSource() -> UICollectionViewDiffableDataSource<String, LibraryItem> {
        let cellRegistration = UICollectionView.CellRegistration<EntryCollectionViewCell, LibraryItem> { cell, _, item in
            if let entry = self.entries.first(where: { $0.sourceId == item.sourceId && $0.id == item.id }) {
                cell.setEntry(to: entry)
            }
        }

        let headerSupplementaryRegistration = UICollectionView.SupplementaryRegistration<ExpandableSectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { header, _, indexPath in
            header.setTitle(to: self.categories[safe: indexPath.section]?.name ?? "All")
            header.setExpandable(true)
            header.setExpandAction { [weak self] in
                guard let self else { return }
                if let category = self.categories[safe: indexPath.section] {
                    let items = self.items.filter({ $0.categories.contains(category.id) })
                    if let entries = self.entries as? [TextEntry] {
                        self.navigationController?.pushViewController(
                            LibrarySeeMoreViewController(items: items, entries: entries, category: category),
                            animated: true
                        )
                    } else if let entries = self.entries as? [ImageEntry] {
                        self.navigationController?.pushViewController(
                            LibrarySeeMoreViewController(items: items, entries: entries, category: category),
                            animated: true
                        )
                    } else if let entries = self.entries as? [VideoEntry] {
                        self.navigationController?.pushViewController(
                            LibrarySeeMoreViewController(items: items, entries: entries, category: category),
                            animated: true
                        )
                    }
                } else {
                    if let entries = self.entries as? [TextEntry] {
                        self.navigationController?.pushViewController(
                            LibrarySeeMoreViewController(items: self.items, entries: entries),
                            animated: true
                        )
                    } else if let entries = self.entries as? [ImageEntry] {
                        self.navigationController?.pushViewController(
                            LibrarySeeMoreViewController(items: self.items, entries: entries),
                            animated: true
                        )
                    } else if let entries = self.entries as? [VideoEntry] {
                        self.navigationController?.pushViewController(
                            LibrarySeeMoreViewController(items: self.items, entries: entries),
                            animated: true
                        )
                    }
                }
            }
        }

        let dataSource = UICollectionViewDiffableDataSource<String, LibraryItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, entry in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: entry)
        }

        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerSupplementaryRegistration, for: indexPath)
        }

        return dataSource
    }

    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<String, LibraryItem>()
        snapshot.appendSections(self.categories.map({ $0.id }) + [ "" ])
        for item in self.items {
            for category in item.categories where snapshot.sectionIdentifiers.contains(category) {
                snapshot.appendItems([ item.copy() ], toSection: category)
            }
            snapshot.appendItems([ item ], toSection: "")
        }
        self.dataSource.apply(snapshot)
    }

    @objc func refresh(_ sender: UIRefreshControl? = nil) {
        Task {
            self.categories = DataManager.shared.getLibraryCategories(ofType: self.mediaType)
            self.items = DataManager.shared.getLibraryItems(ofType: self.mediaType)
            switch self.mediaType {
            case .text: self.entries = DataManager.shared.getEntries(self.items) as [TextEntry]
            case .image: self.entries = DataManager.shared.getEntries(self.items) as [ImageEntry]
            case .video: self.entries = DataManager.shared.getEntries(self.items) as [VideoEntry]
            }
            self.reloadData()
            self.refreshControl.endRefreshing()
        }
    }

    @objc func pageControlValueChanged(_ sender: UIPageControl) {
        self.collectionView.scrollToItem(
            at: IndexPath(item: sender.currentPage, section: sender.tag),
            at: .centeredHorizontally,
            animated: true
        )
    }

    class Delegate: NSObject, UICollectionViewDelegate {
        weak var parent: LibraryViewController?

        init(_ parent: LibraryViewController) {
            self.parent = parent
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            if let entry = (collectionView.cellForItem(at: indexPath) as? EntryCollectionViewCell)?.entry,
               let item = self.parent?.items.first(where: { $0.sourceId == entry.sourceId && $0.id == entry.id }),
               let source = SourceManager.shared.sources.first(where: { $0.id == entry.sourceId }) {
                self.parent?.navigationController?.pushViewController(
                    EntryViewController(entry: entry, source: source, libraryItem: item),
                    animated: true
                )
            }
            collectionView.deselectItem(at: indexPath, animated: false)
        }
    }
}
