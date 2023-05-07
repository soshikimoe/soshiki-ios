//
//  DiscoverViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/6/23.
//

import UIKit

class DiscoverViewController: BaseViewController {
    var entries: [String: [SourceEntry]]

    var sections: [String]

    var collectionView: UICollectionView!
    let refreshControl: UIRefreshControl

    var dataSource: UICollectionViewDiffableDataSource<Int, [SourceEntry]>!

    var isLandscape: Bool {
        self.view.frame.width > self.view.frame.height
    }

    var tracker: Tracker? {
        UserDefaults.standard.string(forKey: "app.settings.discoverSource").flatMap({ name in
            TrackerManager.shared.trackers.first(where: { $0.name == name && $0.schema >= 2 })
        }) ?? TrackerManager.shared.trackers.filter({ $0.schema >= 2 }).first
    }

    override init() {
        self.refreshControl = UIRefreshControl()

        self.entries = [:]
        self.sections = []

        super.init()

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = .none

        let layout = StretchingCollectionViewCompositionalLayout(sectionProvider: { section, _ in
            switch section {
            case 0: // Trending
                let section = NSCollectionLayoutSection(
                    group: NSCollectionLayoutGroup.horizontal(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1),
                            heightDimension: .absolute(200 + 40)
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
                section.boundarySupplementaryItems = [
                    NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1),
                            heightDimension: self.isLandscape ? .absolute(self.view.frame.height) : .fractionalWidth(1.5)
                        ),
                        elementKind: UICollectionView.elementKindSectionHeader,
                        alignment: .top
                    )
                ]
                return section
            case 1: // Top Rated
                return NSCollectionLayoutSection(
                    group: NSCollectionLayoutGroup.horizontal(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1),
                            heightDimension: .absolute(450 + 40)
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
            default: // Standard Category
                return NSCollectionLayoutSection(
                    group: NSCollectionLayoutGroup.horizontal(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1),
                            heightDimension: .absolute(240 + 40)
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
            }
        }, configuration: configuration)

        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell")
        self.collectionView.delegate = self

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

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        self.navigationItem.standardAppearance = appearance
        self.navigationItem.scrollEdgeAppearance = appearance
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
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

    func configureDataSource() -> UICollectionViewDiffableDataSource<Int, [SourceEntry]> {
        let headerRegistration = UICollectionView.SupplementaryRegistration<DiscoverFeaturedView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { view, _, _ in
            view.setEntries(to: self.entries["Featured"] ?? [])
            view.delegate = self
        }

        let trendingCellRegistration = UICollectionView.CellRegistration<DiscoverTrendingView, [SourceEntry]> { cell, _, entries in
            cell.setEntries(to: entries)
            cell.delegate = self
        }

        let topCellRegistration = UICollectionView.CellRegistration<DiscoverTopView, [SourceEntry]> { cell, _, entries in
            cell.setEntries(to: entries)
            cell.delegate = self
        }

        let categoryCellRegistration = UICollectionView.CellRegistration<DiscoverCategoryView, [SourceEntry]> { cell, indexPath, entries in
            cell.setTitle(to: self.sections[safe: indexPath.section - 2] ?? "")
            cell.setEntries(to: entries)
            cell.delegate = self
        }

        let dataSource = UICollectionViewDiffableDataSource<Int, [SourceEntry]>(
            collectionView: collectionView
        ) { collectionView, indexPath, entries in
            switch indexPath.section {
            case 0: // Trending
                return collectionView.dequeueConfiguredReusableCell(using: trendingCellRegistration, for: indexPath, item: entries)
            case 1: // Top Rated
                return collectionView.dequeueConfiguredReusableCell(using: topCellRegistration, for: indexPath, item: entries)
            default: // Standard Category
                return collectionView.dequeueConfiguredReusableCell(using: categoryCellRegistration, for: indexPath, item: entries)
            }
        }

        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }

        return dataSource
    }

    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, [SourceEntry]>()
        snapshot.appendSections(Array(0..<(self.sections.count + 2)))
        for (index, section) in ([ "Trending", "Top" ] + self.sections).enumerated() {
            if let entries = self.entries[section] {
                snapshot.appendItems([ entries ], toSection: index)
            }
        }
        self.dataSource.apply(snapshot)
    }

    func reloadData(in section: String, index: Int) {
        var snapshot = NSDiffableDataSourceSectionSnapshot<[SourceEntry]>()
        if let entries = self.entries[section] {
            snapshot.append([ entries ])
        }
        self.dataSource.apply(snapshot, to: index)
    }

    @objc func refresh(_ sender: UIRefreshControl? = nil) {
        Task {
            if let tracker = self.tracker {
                self.sections = tracker.getDiscoverSections(mediaType: LibraryManager.shared.mediaType)
                for (index, section) in ([ "Featured", "Trending", "Top" ] + self.sections).enumerated() {
                    let entries = await tracker.getDiscoverEntries(mediaType: LibraryManager.shared.mediaType, category: section)
                    self.entries[section] = entries
                    if index >= 1 {
                        self.reloadData(in: section, index: index - 1) // Trending is 1 in the above array but 0 in the collection view
                    } else if let header = self.collectionView.supplementaryView(
                        forElementKind: UICollectionView.elementKindSectionHeader,
                        at: IndexPath(item: 0, section: 0)
                    ) as? DiscoverFeaturedView {
                        header.setEntries(to: entries)
                    }
                }
            }
            sender?.endRefreshing()
        }
    }
}

// MARK: - DiscoverViewController + UICollectionViewDelegate

extension DiscoverViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for view in self.collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader) {
            if let view = view as? DiscoverFeaturedView {
                view.scrollViewDidScroll(scrollView)
            }
        }
    }
}

// MARK: - DiscoverViewController + StretchingCollectionViewLayoutParent

extension DiscoverViewController: StretchingLayoutParent {
    var headerHeight: CGFloat {
        self.isLandscape ? self.view.frame.height : self.view.frame.width * 1.5
    }
}

extension DiscoverViewController: DiscoverViewControllerChildDelegate {
    func didSelect(entry: SourceEntry) {
        if let tracker = self.tracker {
            self.navigationController?.pushViewController(EntryViewController(sourceEntry: entry, tracker: tracker), animated: true)
        }
    }
}

// MARK: - DiscoverViewControllerChildDelegate

protocol DiscoverViewControllerChildDelegate: AnyObject {
    func didSelect(entry: SourceEntry)
}
