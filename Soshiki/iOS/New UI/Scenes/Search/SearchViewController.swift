//
//  SearchViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/17/23.
//

import UIKit

class SearchViewController: BaseViewController {
    var mediaType: MediaType

    var entries: [String: [any Entry]]
    var sources: [any Source]

    var loadTask: Task<Void, Never>?

    var collectionView: UICollectionView!
    var delegate: Delegate!
    let refreshControl: UIRefreshControl
    let searchController: UISearchController

    var query: String

    var layout: UICollectionViewCompositionalLayout!
    var dataSource: UICollectionViewDiffableDataSource<String, AnyHashable>!

    var isLandscape: Bool {
        self.view.frame.width > self.view.frame.height
    }

    override init() {
        self.refreshControl = UIRefreshControl()
        self.searchController = UISearchController(searchResultsController: nil)

        self.mediaType = LibraryManager.shared.mediaType

        self.entries = [:]
        self.sources = []

        self.query = ""

        super.init()

        self.title = "Search"

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

        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.searchController.searchResultsUpdater = self.delegate
        self.navigationItem.searchController = self.searchController

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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.mediaType.rawValue.capitalized, menu: UIMenu(
            children: MediaType.allCases.map({ type in
                UIAction(title: type.rawValue.capitalized) { [weak self] _ in
                    self?.mediaType = type
                    self?.navigationItem.rightBarButtonItem?.title = type.rawValue.capitalized
                    self?.refresh()
                }
            })
        ))

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

    func configureDataSource() -> UICollectionViewDiffableDataSource<String, AnyHashable> {
        let cellRegistration = UICollectionView.CellRegistration<EntryCollectionViewCell, AnyHashable> { cell, _, entry in
            if let entry = entry as? any Entry {
                cell.setEntry(to: entry)
            }
        }

        let headerSupplementaryRegistration = UICollectionView.SupplementaryRegistration<ExpandableSectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { header, _, indexPath in
            header.setTitle(to: self.sources[safe: indexPath.section]?.name ?? "")
            header.setExpandable(true)
            header.setExpandAction { [weak self] in
                guard let self,
                      let source = self.sources[safe: indexPath.section],
                      let entries = self.entries[source.id] else { return }
                if let source = source as? JSTextSource, let entries = entries as? [TextEntry] {
                    self.navigationController?.pushViewController(
                        SearchSeeMoreViewController(source: source, entries: entries, query: self.query),
                        animated: true
                    )
                } else if let source = source as? JSImageSource, let entries = entries as? [ImageEntry] {
                    self.navigationController?.pushViewController(
                        SearchSeeMoreViewController(source: source, entries: entries, query: self.query),
                        animated: true
                    )
                } else if let source = source as? JSVideoSource, let entries = entries as? [VideoEntry] {
                    self.navigationController?.pushViewController(
                        SearchSeeMoreViewController(source: source, entries: entries, query: self.query),
                        animated: true
                    )
                }
            }
        }

        let dataSource = UICollectionViewDiffableDataSource<String, AnyHashable>(
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
        var snapshot = NSDiffableDataSourceSnapshot<String, AnyHashable>()
        snapshot.appendSections(self.sources.map({ $0.id }))
        for entry in self.entries {
            snapshot.appendItems(entry.value.map({ AnyHashable($0) }), toSection: entry.key)
        }
        self.dataSource.apply(snapshot)
    }

    @objc func refresh(_ sender: UIRefreshControl? = nil) {
        self.sources = SourceManager.shared.sources(ofType: self.mediaType)
        load(sender, delayMillis: 0)
    }

    func load(_ sender: UIRefreshControl? = nil, delayMillis: Int) {
        self.entries = [:]

        self.loadTask?.cancel()
        self.loadTask = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(delayMillis) * 1_000_000)
            } catch {
                return
            }

            await withTaskGroup(of: Void.self) { group in
                for source in self.sources {
                    group.addTask {
                        switch source {
                        case let source as JSTextSource:
                            if let results = await source.getSearchResults(query: self.query, page: 1, filters: [])?.results {
                                await Task { @MainActor in
                                    self.entries[source.id] = results
                                }.value
                            }
                        case let source as JSImageSource:
                            if let results = await source.getSearchResults(query: self.query, page: 1, filters: [])?.results {
                                await Task { @MainActor in
                                    self.entries[source.id] = results
                                }.value
                            }
                        case let source as JSVideoSource:
                            if let results = await source.getSearchResults(query: self.query, page: 1, filters: [])?.results {
                                await Task { @MainActor in
                                    self.entries[source.id] = results
                                }.value
                            }
                        default: break
                        }
                    }
                }
            }

            self.reloadData()
            sender?.endRefreshing()
            self.loadTask = nil
        }
    }

    @objc func pageControlValueChanged(_ sender: UIPageControl) {
        self.collectionView.scrollToItem(
            at: IndexPath(item: sender.currentPage, section: sender.tag),
            at: .centeredHorizontally,
            animated: true
        )
    }

    class Delegate: NSObject, UICollectionViewDelegate, UISearchResultsUpdating {
        weak var parent: SearchViewController?

        init(_ parent: SearchViewController) {
            self.parent = parent
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            if let source = self.parent?.sources[safe: indexPath.section],
               let entry = self.parent?.entries[source.id]?[safe: indexPath.item] {
                self.parent?.navigationController?.pushViewController(
                    EntryViewController(entry: entry, source: source),
                    animated: true
                )
            }
            collectionView.deselectItem(at: indexPath, animated: false)
        }

        func updateSearchResults(for searchController: UISearchController) {
            self.parent?.query = searchController.searchBar.text ?? ""
            self.parent?.load(delayMillis: 500)
        }
    }
}
