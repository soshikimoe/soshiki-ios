//
//  SourceView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/30/22.
//

import SwiftUI
import SwiftUIX

struct SourceView: View {
    var source: Source

    @AppStorage("settings.library.itemsPerRow") var itemsPerRow: Int = 3

    var gridItems: [GridItem]!

    @StateObject var sourceViewModel: SourceViewModel

    init(source: Source) {
        self.source = source
        self._sourceViewModel = StateObject(wrappedValue: SourceViewModel(source: source))
        gridItems = .init(repeating: .init(.flexible(), spacing: 10), count: itemsPerRow)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                SearchBar("Search", text: $sourceViewModel.searchText, onEditingChanged: { _ in }, onCommit: {
                    sourceViewModel.selectedListing = SourceListing(id: "", name: "All")
                    sourceViewModel.resultsType = .search
                    sourceViewModel.refreshSearch()
                })
                HStack {
                    Text("Listing")
                    Picker("Listing", selection: $sourceViewModel.selectedListing) {
                        ForEach(sourceViewModel.listings, id: \.id) { listing in
                            Text(listing.name).tag(listing)
                        }
                    }.pickerStyle(.menu)
                        .padding(.leading, -10)
                    Spacer()
                }.padding(.leading)
                LazyVGrid(columns: gridItems, spacing: 10) {
                    ForEach(sourceViewModel.searchResults?.entries ?? [], id: \.id) { item in
                        NavigationLink {
                            if let imageSource = source as? ImageSource {
                                ImageBrowseEntryView(shortEntry: item, source: imageSource)
                            } else if let videoSource = source as? VideoSource {
                                VideoBrowseEntryView(shortEntry: item, source: videoSource)
                            }
                        } label: {
                            SourceEntryCellView(entry: item)
                        }.onAppear {
                            if sourceViewModel.searchResults?.entries.last?.id == item.id, sourceViewModel.loadingTask == nil {
                                sourceViewModel.getNextPage()
                            }
                        }
                    }
                }.padding(10)
            }.introspectScrollView { scrollView in
                scrollView.refreshControl = sourceViewModel.refreshControl
            }.navigationTitle(source.name)
        }.sheet(isPresented: $sourceViewModel.filterViewPresented) {
            NavigationView {
                SourceFilterView(filters: $sourceViewModel.filters).toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            sourceViewModel.filterViewPresented = false
                        } label: {
                            Text("Done").bold()
                        }
                    }
                }.navigationTitle("Filters")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }.sheet(isPresented: $sourceViewModel.settingsViewPresented) {
            NavigationView {
                SourceSettingsView(source: sourceViewModel.source, settings: $sourceViewModel.settings).toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            sourceViewModel.settingsViewPresented = false
                        } label: {
                            Text("Done").bold()
                        }
                    }
                }.navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }.onChange(of: sourceViewModel.selectedListing) { _ in
            sourceViewModel.searchResults = nil
            sourceViewModel.searchText = ""
            sourceViewModel.resultsType = .listing
            sourceViewModel.refreshListing()
        }.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    sourceViewModel.filterViewPresented.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    sourceViewModel.settingsViewPresented.toggle()
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }
}

@MainActor class SourceViewModel: ObservableObject {
    let source: Source

    let refreshControl: UIRefreshControl

    @Published var searchText = ""

    @Published var searchResults: SourceEntryResults?

    @Published var filters: [any SourceFilter] = []
    @Published var filterViewPresented: Bool = false

    @Published var listings: [SourceListing] = [SourceListing(id: "", name: "All")]
    @Published var selectedListing: SourceListing = SourceListing(id: "", name: "All")

    @Published var settings: [any SourceFilter] = []
    @Published var settingsViewPresented: Bool = false

    enum ResultsType {
        case listing
        case search
    }
    var resultsType: ResultsType = .listing

    init(source: Source) {
        self.source = source
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        Task {
            filters = await source.getFilters()
            listings.append(contentsOf: await source.getListings())
            settings = await source.getSettings()
        }
        refreshListing()
    }

    @objc func refresh() {
        if resultsType == .search {
            refreshSearch()
        } else if resultsType == .listing {
            refreshListing()
        }
    }

    var loadingTask: Task<Void, Never>?

    func getNextPage() {
        guard let searchResults, searchResults.hasMore else { return }
        loadingTask = Task {
            let newSearchResults: SourceEntryResults?
            if resultsType == .search {
                newSearchResults = await source.getSearchResults(
                    query: self.searchText,
                    filters: self.filters,
                    previousResultsInfo: SourceEntryResultsInfo(page: searchResults.page + 1)
                )
            } else {
                newSearchResults = await source.getListing(
                    listing: selectedListing,
                    previousResultsInfo: SourceEntryResultsInfo(page: searchResults.page + 1)
                )
            }
            if let newSearchResults {
                Task { @MainActor in
                    self.searchResults = SourceEntryResults(
                        page: newSearchResults.page,
                        hasMore: newSearchResults.hasMore,
                        entries: searchResults.entries + newSearchResults.entries
                    )
                    loadingTask = nil
                }
            } else {
                loadingTask = nil
            }
        }
    }

    func refreshSearch() {
        loadingTask = Task {
            if let searchResults = await source.getSearchResults(query: self.searchText, filters: self.filters) {
                Task { @MainActor in
                    self.searchResults = searchResults
                    loadingTask = nil
                    refreshControl.endRefreshing()
                }
            } else {
                loadingTask = nil
            }
        }
    }

    func refreshListing() {
        loadingTask = Task {
            if let listingResults = await source.getListing(listing: selectedListing) {
                Task { @MainActor in
                    self.searchResults = listingResults
                    loadingTask = nil
                    refreshControl.endRefreshing()
                }
            } else {
                loadingTask = nil
            }
        }
    }
}
