//
//  DiscoverViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/6/23.
//

import UIKit

class DiscoverViewController<SourceType: Source>: BaseViewController {
    typealias EntryType = SourceType.EntryType

    var source: SourceType

    var entries: [String: [EntryType]]
    var hasMoreMap: [String: Bool]

    var listings: [SourceListing]

    var collectionView: UICollectionView!
    var delegate: Delegate!
    let refreshControl: UIRefreshControl

    var layout: UICollectionViewCompositionalLayout!
    var dataSource: UICollectionViewDiffableDataSource<String, SourceType.EntryType>!

    var isLandscape: Bool {
        self.view.frame.width > self.view.frame.height
    }

    init(source: SourceType) {
        self.refreshControl = UIRefreshControl()

        self.source = source
        self.entries = [:]
        self.listings = []
        self.hasMoreMap = [:]

        super.init()

        self.title = self.source.name

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 8

        self.layout = UICollectionViewCompositionalLayout(sectionProvider: { section, _ in
            switch self.listings[section].type {
            case .featured:
                let section = NSCollectionLayoutSection(
                    group: NSCollectionLayoutGroup.horizontal(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1),
                            heightDimension: self.isLandscape ? .fractionalHeight(1) : .fractionalWidth(1.5)
                        ),
                        subitems: [
                            NSCollectionLayoutItem(
                                layoutSize: NSCollectionLayoutSize(
                                    widthDimension: .fractionalWidth(1),
                                    heightDimension: .fractionalHeight(1)
                                )
                            )
                        ]
                    )
                )
                section.orthogonalScrollingBehavior = .groupPaging
                let footer = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(26)
                    ),
                    elementKind: UICollectionView.elementKindSectionFooter,
                    alignment: .bottomLeading
                )
                footer.contentInsets = NSDirectionalEdgeInsets(all: 8)
                section.boundarySupplementaryItems = [ footer ]
                section.visibleItemsInvalidationHandler = { [weak self] items, location, environment in
                    if let indexPath = items.first?.indexPath,
                       let view = self?.collectionView.supplementaryView(
                        forElementKind: UICollectionView.elementKindSectionFooter,
                        at: indexPath
                       ) as? DiscoverFeaturedPageControlReusableView {
                        view.pageControl.currentPage = Int(round(location.x / environment.container.contentSize.width))
                    }
                }
                return section
            case .trending:
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
                            widthDimension: .fractionalWidth(0.9),
                            heightDimension: .absolute(200)
                        ),
                        subitems: [ item ]
                    )
                )
                section.contentInsets = NSDirectionalEdgeInsets(all: 8)
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
                section.orthogonalScrollingBehavior = .groupPaging
                section.decorationItems = [
                    NSCollectionLayoutDecorationItem.background(elementKind: "DiscoverSectionBackgroundReusableView")
                ]
                return section
            case .topRated:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(150 + 16 * 2)
                    )
                )
                item.contentInsets = NSDirectionalEdgeInsets(horizontal: 8)
                let section = NSCollectionLayoutSection(
                    group: NSCollectionLayoutGroup.vertical(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(0.9),
                            heightDimension: .absolute(450 + 16 * 2 * 3)
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
                section.orthogonalScrollingBehavior = .groupPaging
                section.decorationItems = [
                    NSCollectionLayoutDecorationItem.background(elementKind: "DiscoverSectionBackgroundReusableView")
                ]
                return section
            case .basic:
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
            }
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

    func configureDataSource() -> UICollectionViewDiffableDataSource<String, EntryType> {
        let featuredCellRegistration = UICollectionView.CellRegistration<DiscoverFeaturedEntryView, EntryType> { cell, _, entry in
            cell.setEntry(to: entry)
            cell.delegate = self
        }

        let trendingCellRegistration = UICollectionView.CellRegistration<DiscoverTrendingEntryView, EntryType> { cell, _, entry in
            cell.setEntry(to: entry)
        }

        let topCellRegistration = UICollectionView.CellRegistration<DiscoverTopEntryView, EntryType> { cell, indexPath, entry in
            cell.setEntry(to: entry, number: indexPath.item + 1)
        }

        let basicCellRegistration = UICollectionView.CellRegistration<EntryCollectionViewCell, EntryType> { cell, _, entry in
            cell.setEntry(to: entry)
        }

        let headerSupplementaryRegistration = UICollectionView.SupplementaryRegistration<ExpandableSectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { header, _, indexPath in
            header.setTitle(to: self.listings[indexPath.section].name)
            header.setExpandable(self.hasMoreMap[self.listings[indexPath.section].id] ?? false)
            header.setExpandAction { [weak self] in
                guard let self, let entries = self.entries[self.listings[indexPath.section].id] else { return }
                self.navigationController?.pushViewController(
                    DiscoverSeeMoreViewController(source: self.source, entries: entries, listing: self.listings[indexPath.section]),
                    animated: true
                )
            }
        }

        let footerSupplementaryRegistration = UICollectionView.SupplementaryRegistration<DiscoverFeaturedPageControlReusableView>(
            elementKind: UICollectionView.elementKindSectionFooter
        ) { footer, _, indexPath in
            footer.pageControl.tag = indexPath.section
            footer.pageControl.numberOfPages = self.entries[self.listings[indexPath.section].id]?.count ?? 0
            footer.pageControl.addTarget(self, action: #selector(self.pageControlValueChanged(_:)), for: .valueChanged)
        }

        let dataSource = UICollectionViewDiffableDataSource<String, EntryType>(
            collectionView: collectionView
        ) { collectionView, indexPath, entry in
            switch self.listings[indexPath.section].type {
            case .featured:
                return collectionView.dequeueConfiguredReusableCell(using: featuredCellRegistration, for: indexPath, item: entry)
            case .trending:
                return collectionView.dequeueConfiguredReusableCell(using: trendingCellRegistration, for: indexPath, item: entry)
            case .topRated:
                return collectionView.dequeueConfiguredReusableCell(using: topCellRegistration, for: indexPath, item: entry)
            case .basic:
                return collectionView.dequeueConfiguredReusableCell(using: basicCellRegistration, for: indexPath, item: entry)
            }
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerSupplementaryRegistration, for: indexPath)
            case UICollectionView.elementKindSectionFooter:
                return collectionView.dequeueConfiguredReusableSupplementary(using: footerSupplementaryRegistration, for: indexPath)
            default:
                return nil
            }
        }

        return dataSource
    }

    func reloadSections() {
        var snapshot = NSDiffableDataSourceSnapshot<String, EntryType>()
        snapshot.appendSections(self.listings.map({ $0.id }))
        self.dataSource.apply(snapshot)
    }

    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<String, EntryType>()
        snapshot.appendSections(self.listings.map({ $0.id }))
        for entries in self.entries {
            snapshot.appendItems(entries.value, toSection: entries.key)
        }
        self.dataSource.apply(snapshot)
    }

    func reloadData(in section: String) {
        var snapshot = NSDiffableDataSourceSectionSnapshot<EntryType>()
        if let entries = self.entries[section] {
            snapshot.append(entries)
        }
        self.dataSource.apply(snapshot, to: section)
    }

    @objc func refresh(_ sender: UIRefreshControl? = nil) {
        Task {
            self.listings = await self.source.getListings()
            self.reloadSections()
            for listing in self.listings {
                if let results = await self.source.getListing(listing: listing, page: 1) {
                    self.entries[listing.id] = results.results
                    self.hasMoreMap[listing.id] = results.hasMore
                    self.reloadData(in: listing.id)
                }
            }
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
        weak var parent: DiscoverViewController?

        init(_ parent: DiscoverViewController) {
            self.parent = parent
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            if let listing = self.parent?.listings[safe: indexPath.section],
               listing.type != .featured,
               let entry = self.parent?.entries[listing.id]?[indexPath.item],
               let source = self.parent?.source {
                self.parent?.navigationController?.pushViewController(EntryViewController(entry: entry, source: source), animated: true)
            }
            collectionView.deselectItem(at: indexPath, animated: false)
        }
    }
}

// MARK: - DiscoverViewController + DiscoverViewControllerChildDelegate

extension DiscoverViewController: DiscoverViewControllerChildDelegate {
    func didSelect(entry: EntryType) {
        self.navigationController?.pushViewController(EntryViewController(entry: entry, source: self.source), animated: true)
    }
}

// MARK: - DiscoverViewControllerChildDelegate

protocol DiscoverViewControllerChildDelegate<EntryType>: AnyObject {
    associatedtype EntryType: Entry

    func didSelect(entry: EntryType)
}
