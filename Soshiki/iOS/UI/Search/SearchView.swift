//
//  SearchView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/20/22.
//

import SwiftUI
import SwiftUIX

struct SearchView: View {
    @StateObject var searchViewModel = SearchViewModel()

    @EnvironmentObject var contentViewModel: ContentViewModel

    @AppStorage("settings.library.itemsPerRow") var itemsPerRow: Int = 3

    var gridItems: [GridItem]!

    init() {
        gridItems = .init(repeating: .init(.flexible(), spacing: 10), count: itemsPerRow)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                SearchBar("Search", text: $searchViewModel.searchText, onEditingChanged: { _ in }, onCommit: {
                    searchViewModel.refreshSearch()
                })
                HStack {
                    Text("\(searchViewModel.searchResults.count) results")
                    Spacer()
                    Text("Media Type")
                    Menu {
                        Button {
                            contentViewModel.mediaType = .text
                            searchViewModel.refreshSearch()
                        } label: {
                            if contentViewModel.mediaType == .text {
                                Label("Text", systemImage: "checkmark")
                            } else {
                                Text("Text")
                            }
                        }
                        Button {
                            contentViewModel.mediaType = .image
                            searchViewModel.refreshSearch()
                        } label: {
                            if contentViewModel.mediaType == .image {
                                Label("Image", systemImage: "checkmark")
                            } else {
                                Text("Image")
                            }
                        }
                        Button {
                            contentViewModel.mediaType = .video
                            searchViewModel.refreshSearch()
                        } label: {
                            if contentViewModel.mediaType == .video {
                                Label("Video", systemImage: "checkmark")
                            } else {
                                Text("Video")
                            }
                        }
                    } label: {
                        Text(contentViewModel.mediaType.rawValue.capitalized).padding(.trailing, -3)
                        Image(systemName: "chevron.down")
                    }
                }.padding(.horizontal, 10)
                LazyVGrid(columns: gridItems, spacing: 10) {
                    ForEach(searchViewModel.searchResults, id: \._id) { entry in
                        NavigationLink {
                            EntryView(entry: entry)
                        } label: {
                            EntryCellView(entry: entry.toUnifiedEntry())
                        }.onAppear {
                            if searchViewModel.searchResults.last?._id == entry._id,
                               searchViewModel.searchTask == nil {
                                searchViewModel.getNextPage()
                            }
                        }
                    }
                }.padding(10)
            }.introspectScrollView { scrollView in
                scrollView.refreshControl = searchViewModel.refreshControl
            }.navigationTitle("Search")
        }.onAppear {
            searchViewModel.contentViewModel = contentViewModel
        }.task {
            await contentViewModel.refreshLibraries()
        }
    }
}

@MainActor class SearchViewModel: ObservableObject {
    let refreshControl: UIRefreshControl

    var contentViewModel: ContentViewModel!

    @Published var searchResults: [Entry] = []
    @Published var searchText = ""
    @Published var searchTask: Task<Void, Never>?

    var queryOffset = 0

    init() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshSearch), for: .valueChanged)
    }

    @objc func refreshSearch() {
        queryOffset = 0
        searchTask?.cancel()
        searchTask = Task {
            if let searchResults = try? await SoshikiAPI.shared.getEntries(mediaType: contentViewModel.mediaType, query: [
                .title(searchText)
                // .contentRating([.safe])
            ]).get() {
                self.searchResults = searchResults
            }
            self.searchTask = nil
        }
    }

    func getNextPage() {
        guard searchResults.count % 100 == 0 else { return }
        queryOffset += 100
        searchTask?.cancel()
        searchTask = Task {
            if let searchResults = try? await SoshikiAPI.shared.getEntries(mediaType: contentViewModel.mediaType, query: [
                .title(searchText),
                .offset(queryOffset)
                // .contentRating([.safe])
            ]).get() {
                self.searchResults.append(contentsOf: searchResults)
            }
            self.searchTask = nil
        }
    }
}
