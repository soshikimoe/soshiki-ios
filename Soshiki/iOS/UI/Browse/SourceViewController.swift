//
//  SourceViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/28/23.
//

import UIKit

class SourceViewController: UICollectionViewController {
    var observers: [NSObjectProtocol] = []

    let source: any Source
    let refreshControl = UIRefreshControl()

    var listings: [SourceListing] = [.init(id: "", name: "All")]
    var filters: [any SourceFilter] {
        get {
            sourceFiltersViewController.filters
        } set {
            sourceFiltersViewController.filters = newValue
        }
    }
    var settings: [any SourceFilter] {
        get {
            sourceSettingsViewController.settings
        } set {
            sourceSettingsViewController.settings = newValue
        }
    }

    var dataSource: UICollectionViewDiffableDataSource<Int, SourceShortEntry>!

    var entries: [SourceShortEntry] = []
    var previousResultsInfo: SourceEntryResultsInfo?
    var loadTask: Task<Void, Never>?
    var hasMore = true

    lazy var sourceFiltersViewController = SourceFiltersViewController(updateHandler: { [weak self] _ in
        self?.resultsType = .search
        self?.reloadListingMenu()
        self?.refresh()
    })

    lazy var sourceSettingsViewController = SourceSettingsViewController(updateHandler: { [weak self] setting in
        guard let self else { return }
        UserDefaults.standard.set(setting.value, forKey: "settings.source.\(self.source.id).\(setting.id)")
        self.refresh()
    })

    enum ResultsType {
        case listing
        case search
    }
    var resultsType: ResultsType = .listing

    var currentListing: SourceListing = .init(id: "", name: "All")

    var currentSearch: String = ""

    let searchController = UISearchController(searchResultsController: nil)

    let listingButton = UIButton()
    let listingLabel = UILabel()

    init(source: any Source) {
        self.source = source
        LibraryManager.shared.mediaType = source is any TextSource ? .text : source is any ImageSource ? .image : .video

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
        let config = UICollectionViewCompositionalLayoutConfiguration()
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(25)
            ),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        config.boundarySupplementaryItems = [ header ]
        layout.configuration = config
        super.init(collectionViewLayout: layout)

        self.title = source.name

        let cellRegistration: UICollectionView.CellRegistration<EntryCollectionViewCell, SourceShortEntry> = .init(handler: { cell, _, entry in
            cell.setEntry(entry: entry.toLocalEntry())
        })
        self.dataSource = UICollectionViewDiffableDataSource(
            collectionView: self.collectionView,
            cellProvider: { collectionView, indexPath, itemIdentifier in
                collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
            }
        )

        let registration = UICollectionView.SupplementaryRegistration<UICollectionReusableView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] headerView, _, _ in
            guard let self else { return }
            let titleLabel = UILabel()
            titleLabel.text = "Listing"
            titleLabel.textColor = .secondaryLabel
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(titleLabel)
            headerView.addSubview(self.listingLabel)
            headerView.addSubview(self.listingButton)
            titleLabel.leadingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.leadingAnchor, constant: 8).isActive = true
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
            self.listingLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 5).isActive = true
            self.listingLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
            self.listingButton.leadingAnchor.constraint(equalTo: self.listingLabel.trailingAnchor, constant: 5).isActive = true
            self.listingButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        }
        self.dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            if kind == UICollectionView.elementKindSectionHeader {
                return collectionView.dequeueConfiguredReusableSupplementary(using: registration, for: indexPath)
            } else {
                return nil
            }
        }

        self.collectionView.dataSource = self.dataSource

        self.refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        self.collectionView.refreshControl = self.refreshControl

        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.searchController.searchResultsUpdater = self
        self.navigationItem.searchController = searchController

        listingButton.translatesAutoresizingMaskIntoConstraints = false
        listingButton.showsMenuAsPrimaryAction = true
        listingButton.setImage(UIImage(systemName: "chevron.up.chevron.down"), for: .normal)

        listingLabel.translatesAutoresizingMaskIntoConstraints = false
        listingLabel.text = currentListing.name
        listingLabel.font = .systemFont(ofSize: 17, weight: .semibold)

        let filtersButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease"),
            style: .plain,
            target: self,
            action: #selector(openSourceFiltersView)
        )

        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(openSourceSettingsView)
        )

        navigationItem.rightBarButtonItems = [ settingsButton, filtersButton ]

        refresh()

        observers.append(
            NotificationCenter.default.addObserver(forName: .init("app.settings.itemsPerRow"), object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.collectionViewLayout.invalidateLayout()
                }
            }
        )

        Task {
            self.filters = await source.getFilters()
            var settings = await source.getSettings()
            for index in settings.indices {
                if let value = UserDefaults.standard.object(forKey: "settings.source.\(source.id).\(settings[index].id)") {
                    settings[index].trySetValue(to: value)
                }
            }
            self.settings = settings
            self.listings.append(contentsOf: await source.getListings())
            reloadListingMenu()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func reloadCollectionViewData() {
        var snapshot = NSDiffableDataSourceSectionSnapshot<SourceShortEntry>()
        snapshot.append(entries)
        dataSource.apply(snapshot, to: 0, animatingDifferences: false)
    }

    func reloadListingMenu() {
        listingLabel.text = resultsType == .listing ? currentListing.name : "None"
        self.listingButton.menu = UIMenu(children: self.listings.map({ listing in
            UIAction(
                title: listing.name,
                image: self.resultsType == .listing && self.currentListing.id == listing.id ? UIImage(systemName: "checkmark") : nil
            ) { [weak self] _ in
                self?.resultsType = .listing
                self?.currentListing = listing
                self?.refresh()
                self?.reloadListingMenu()
            }
        }))
    }

    @objc func refresh(_ refreshControl: UIRefreshControl? = nil) {
        hasMore = true
        loadTask?.cancel()
        loadTask = Task {
            if resultsType == .listing {
                if let results = await source.getListing(listing: currentListing, previousResultsInfo: nil) {
                    entries = results.entries
                    previousResultsInfo = SourceEntryResultsInfo(page: results.page)
                    hasMore = results.hasMore
                    reloadCollectionViewData()
                }
            } else {
                if let results = await source.getSearchResults(query: currentSearch, filters: filters, previousResultsInfo: nil) {
                    entries = results.entries
                    previousResultsInfo = SourceEntryResultsInfo(page: results.page)
                    hasMore = results.hasMore
                    reloadCollectionViewData()
                }
            }
            refreshControl?.endRefreshing()
            self.loadTask = nil
        }
    }

    @objc func openSourceFiltersView() {
        self.navigationController?.pushViewController(sourceFiltersViewController, animated: true)
    }

    @objc func openSourceSettingsView() {
        self.navigationController?.pushViewController(sourceSettingsViewController, animated: true)
    }
}

extension SourceViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.navigationController?.pushViewController(
            SourceEntryViewController(sourceShortEntry: entries[indexPath.item], source: source),
            animated: true
        )
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension SourceViewController {
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if hasMore, loadTask == nil, scrollView.contentSize.height - view.bounds.height - scrollView.contentOffset.y < 500 {
            loadTask = Task {
                if self.resultsType == .listing {
                    if let results = await source.getListing(listing: currentListing, previousResultsInfo: previousResultsInfo) {
                        self.entries.append(contentsOf: results.entries)
                        self.entries = self.entries.removingDuplicates()
                        self.hasMore = results.hasMore
                        self.previousResultsInfo = SourceEntryResultsInfo(page: results.page)
                        self.reloadCollectionViewData()
                    }
                } else {
                    if let results = await source.getSearchResults(query: currentSearch, filters: filters, previousResultsInfo: previousResultsInfo) {
                        self.entries.append(contentsOf: results.entries)
                        self.entries = self.entries.removingDuplicates()
                        self.hasMore = results.hasMore
                        self.previousResultsInfo = SourceEntryResultsInfo(page: results.page)
                        self.reloadCollectionViewData()
                    }
                }
                self.loadTask = nil
            }
        }
    }
}

extension SourceViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        self.currentSearch = searchController.searchBar.text ?? ""
        self.resultsType = .search
        self.reloadListingMenu()
        self.refresh()
    }
}
