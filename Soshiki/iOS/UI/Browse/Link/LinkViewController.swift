//
//  LinkViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/1/23.
//

import UIKit

class LinkViewController: UITableViewController {
    let source: any Source
    let sourceEntry: SourceEntry
    var mediaType: MediaType {
        source is any TextSource ? .text : source is any ImageSource ? .image : .video
    }
    var currentSearch: String
    var offset = 0
    var hasMore = true

    var searchResults: [Entry_Old] = []

    var loadTask: Task<Void, Never>?

    let searchController = UISearchController(searchResultsController: nil)

    var dataSource: UITableViewDiffableDataSource<Int, Entry_Old>!

    init(source: any Source, entry: SourceEntry) {
        self.source = source
        self.sourceEntry = entry
        self.currentSearch = entry.title
        super.init(style: .insetGrouped)
        self.title = "Link"

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")

        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.text = self.currentSearch
        self.navigationItem.searchController = searchController

        self.dataSource = UITableViewDiffableDataSource(
            tableView: self.tableView,
            cellProvider: { _, _, entry in
                EntryTableViewCell(entry: entry, reuseIdentifier: "EntryTableViewCell")
            }
        )
        self.tableView.dataSource = self.dataSource

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl

        self.refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadTableViewData() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Entry_Old>()
        snapshot.appendSections([0])
        snapshot.appendItems(searchResults, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    @objc func refresh() {
        loadTask?.cancel()
        loadTask = Task {
            self.offset = 0
            self.hasMore = true
//            if let results = try? await SoshikiAPI.shared.getEntries(
//                mediaType: mediaType,
//                query: [
//                    .title(currentSearch),
//                    .offset(offset),
//                    .limit(100)
//                ]
//            ).get() {
//                self.searchResults = results
//                self.offset = results.count
//                self.hasMore = !results.isEmpty
//                self.reloadTableViewData()
//            }
            self.loadTask = nil
        }
    }
}

extension LinkViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { searchResults.count }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if let entry = searchResults[safe: indexPath.item] {
//            Task {
//                await SoshikiAPI.shared.setLink(
//                    mediaType: mediaType,
//                    id: entry._id,
//                    platformId: "soshiki",
//                    platformName: "Soshiki",
//                    sourceId: source.id,
//                    sourceName: source.name,
//                    entryId: sourceEntry.id
//                )
//                NotificationCenter.default.post(name: .init("app.link.update"), object: sourceEntry.id)
//            }
//            self.navigationController?.popViewController(animated: true)
//        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension LinkViewController {
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if hasMore, loadTask == nil, scrollView.contentSize.height - view.bounds.height - scrollView.contentOffset.y < 200 {
            loadTask = Task {
//                if let results = try? await SoshikiAPI.shared.getEntries(
//                    mediaType: mediaType,
//                    query: [
//                        .title(currentSearch),
//                        .offset(offset),
//                        .limit(100)
//                    ]
//                ).get() {
//                    self.searchResults.append(contentsOf: results)
//                    self.searchResults = self.searchResults.removingDuplicates()
//                    self.hasMore = !results.isEmpty
//                    self.offset = self.searchResults.count
//                    self.reloadTableViewData()
//                }
                self.loadTask = nil
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 97 }
}

extension LinkViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        self.currentSearch = searchController.searchBar.text ?? ""
        self.refresh()
    }
}
