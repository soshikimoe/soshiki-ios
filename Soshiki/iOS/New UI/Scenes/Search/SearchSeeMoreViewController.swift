//
//  SearchSeeMoreViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/17/23.
//

import UIKit

class SearchSeeMoreViewController<SourceType: Source>: BaseViewController {
    typealias EntryType = SourceType.EntryType

    let source: SourceType
    var entries: [EntryType]
    var filters: [SourceFilterGroup]
    var settings: [SourceFilterGroup]

    var query: String
    var page: Int
    var hasMore: Bool
    var entryLoadTask: Task<Void, Never>?

    var collectionView: UICollectionView!
    var layout: UICollectionViewCompositionalLayout!
    var dataSource: UICollectionViewDiffableDataSource<Int, EntryType>!
    var delegate: Delegate!

    let refreshControl: UIRefreshControl
    let searchController: UISearchController

    init(source: SourceType, entries: [EntryType], query: String) {
        self.source = source
        self.entries = entries
        self.query = query

        self.filters = []
        self.settings = []

        self.page = 1
        self.hasMore = true

        self.refreshControl = UIRefreshControl()
        self.searchController = UISearchController(searchResultsController: nil)

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

        self.title = source.name

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

        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.searchController.searchResultsUpdater = self.delegate
        self.searchController.searchBar.text = self.query
        self.navigationItem.searchController = self.searchController

        self.refresh()

        Task {
            self.filters = await self.source.getFilters()
            self.settings = await self.source.getSettings()
        }

        self.observers.append(
            NotificationCenter.default.addObserver(forName: .init("app.settings.itemsPerRow"), object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.layout.invalidateLayout()
                }
            }
        )
    }

    override func configureViews() {
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "line.3.horizontal.decrease"),
                primaryAction: UIAction { [weak self] _ in
                    if let filters = self?.filters {
                        self?.navigationController?.pushViewController(SearchFiltersViewController(filters: filters, handler: {
                            self?.refresh()
                        }), animated: true)
                    }
                }
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "gear"),
                primaryAction: UIAction { [weak self] _ in
                    if let settings = self?.settings, let sourceId = self?.source.id {
                        self?.navigationController?.pushViewController(
                            SourceSettingsViewController(settings: settings, sourceId: sourceId, handler: {
                                self?.refresh()
                            }),
                            animated: true
                        )
                    }
                }
            )
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = self.collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        self.collectionView.refreshControl = self.refreshControl
    }

    @objc func refresh(_ sender: UIRefreshControl? = nil) {
        self.entryLoadTask?.cancel()
        self.entries = []
        loadEntries(page: 1)
        sender?.endRefreshing()
    }

    func loadEntries(page: Int, delayMillis: Int = 0) {
        self.entryLoadTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delayMillis) * 1_000_000)
            if let results = await self.source.getSearchResults(query: self.query, page: page, filters: self.filters.flatMap({ $0.filters })) {
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

extension SearchSeeMoreViewController {
    class Delegate: NSObject, UICollectionViewDelegate, UISearchResultsUpdating {
        weak var parent: SearchSeeMoreViewController?

        init(_ parent: SearchSeeMoreViewController) {
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

        func updateSearchResults(for searchController: UISearchController) {
            self.parent?.query = searchController.searchBar.text ?? ""
            self.parent?.entryLoadTask?.cancel()
            self.parent?.entries = []
            self.parent?.loadEntries(page: 1, delayMillis: 500)
        }
    }
}
