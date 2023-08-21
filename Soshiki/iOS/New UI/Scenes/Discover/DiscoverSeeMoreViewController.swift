//
//  DiscoverSeeMoreViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/15/23.
//

import UIKit

class DiscoverSeeMoreViewController<SourceType: Source>: BaseViewController {
    typealias EntryType = SourceType.EntryType

    let source: SourceType
    var entries: [EntryType]
    let listing: SourceListing

    var page: Int
    var hasMore: Bool
    var entryLoadTask: Task<Void, Never>?

    var collectionView: UICollectionView!
    var layout: UICollectionViewCompositionalLayout!
    var dataSource: UICollectionViewDiffableDataSource<Int, EntryType>!
    var delegate: Delegate!

    let refreshControl: UIRefreshControl

    init(source: SourceType, entries: [EntryType], listing: SourceListing) {
        self.source = source
        self.entries = entries
        self.listing = listing

        self.page = 1
        self.hasMore = true

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

        self.title = listing.name

        let cellRegistration = UICollectionView.CellRegistration<EntryCollectionViewCell, EntryType> { cell, _, entry in
            cell.setEntry(to: entry)
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
        self.entryLoadTask?.cancel()
        self.entries = []
        loadEntries(page: 1)
        refreshControl.endRefreshing()
    }

    func loadEntries(page: Int) {
        self.entryLoadTask = Task {
            if let results = await self.source.getListing(listing: self.listing, page: page) {
                self.page = results.page
                self.hasMore = results.hasMore
                self.entries.append(contentsOf: results.results)
            } else {
                self.hasMore = false
            }
            reloadCollectionViewData()
            self.entryLoadTask = nil
        }
    }

    func reloadCollectionViewData() {
        var snapshot = NSDiffableDataSourceSectionSnapshot<EntryType>()
        snapshot.append(self.entries)
        self.dataSource.apply(snapshot, to: 0)
    }
}

extension DiscoverSeeMoreViewController {
    class Delegate: NSObject, UICollectionViewDelegate {
        weak var parent: DiscoverSeeMoreViewController?

        init(_ parent: DiscoverSeeMoreViewController) {
            self.parent = parent
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            if let entry = self.parent?.entries[indexPath.item],
               let source = self.parent?.source {
                self.parent?.navigationController?.pushViewController(EntryViewController(entry: entry, source: source), animated: true)
            }
            collectionView.deselectItem(at: indexPath, animated: false)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if let parent = self.parent,
               parent.hasMore,
               parent.entryLoadTask == nil,
               scrollView.contentSize.height - parent.view.bounds.height - scrollView.contentOffset.y < 500 {
                parent.loadEntries(page: parent.page + 1)
            }
        }
    }
}
