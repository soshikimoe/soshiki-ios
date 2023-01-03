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
                    Text("Media Type")
                    Picker("Media Type", selection: $contentViewModel.currentMediaType) {
                        ForEach(MediaType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }.padding(.leading, -8)
                    Spacer()
                }.padding(10)
                LazyVGrid(columns: gridItems, spacing: 10) {
                    ForEach(searchViewModel.searchResults.filter({ $0.id != nil }), id: \.id!) { item in
                        Button {
                            if searchViewModel.selecting && searchViewModel.selections.contains(where: { $0.id == item.id }) {
                                searchViewModel.selections.removeAll(where: { $0.id == item.id })
                            } else {
                                searchViewModel.selections.append(item)
                            }
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                NavigationLink {
                                    EntryView(entry: item)
                                } label: {
                                    EntryCellView(
                                        title: item.info?.title ?? "",
                                        subtitle: "",
                                        cover: item.info?.anilist?.coverImage?.large ?? item.info?.cover ?? ""
                                    )
                                }.allowsHitTesting(!searchViewModel.selecting)
                                if searchViewModel.selecting {
                                    if searchViewModel.selections.contains(where: { $0.id == item.id }) {
                                        ZStack {
                                            Image(systemName: "circle.fill")
                                                .foregroundColor(.white)
                                            Image(systemName: "checkmark.circle.fill")
                                        }.padding(10)
                                    } else {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill()
                                            .foregroundColor(.black.opacity(0.3))
                                        Image(systemName: "circle")
                                            .padding(10)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    }
                }.padding(10)
            }.introspectScrollView { scrollView in
                scrollView.refreshControl = searchViewModel.refreshControl
            }.toolbar {
                if searchViewModel.selecting {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            searchViewModel.selecting = false
                        } label: {
                            Text("Done")
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Menu {
                            Button {
                                Task {
                                    if let newLibrary = await GraphQL.mutation(
                                        MutationAddLibraryItems(
                                            mediaType: contentViewModel.currentMediaType,
                                            ids: searchViewModel.selections.map({ $0.id! }),
                                            category: nil
                                        ),
                                        returning: SoshikiAPI.baseLibrariesQuery,
                                        token: SoshikiAPI.shared.token
                                    ) {
                                        Task { @MainActor in
                                            if let index = contentViewModel.libraries.firstIndex(where: {
                                                $0.mediaType == contentViewModel.currentMediaType
                                            }) {
                                                contentViewModel.libraries[index] = newLibrary
                                            }
                                            searchViewModel.selecting = false
                                        }
                                    }
                                }
                            } label: {
                                Label("Add to Library", systemImage: "plus")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            searchViewModel.selecting = true
                        } label: {
                            Image(systemName: "checkmark.circle")
                        }
                    }
                }
            }.toolbar(searchViewModel.selecting ? .hidden : .visible, for: .tabBar)
                .toolbar(searchViewModel.selecting ? .visible : .hidden, for: .bottomBar)
                .navigationTitle("Search")
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

    @Published var selecting: Bool = false {
        didSet {
            if !selecting {
                selections = []
            }
        }
    }
    @Published var selections: [Entry] = []

    @Published var searchResults: [Entry] = []
    @Published var searchText = ""

    init() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshSearch), for: .valueChanged)
    }

    @objc func refreshSearch() {
        Task {
            if let searchResults = await GraphQL.query(
                QuerySearch(mediaType: contentViewModel.currentMediaType, query: self.searchText),
                returning: SoshikiAPI.baseEntriesQuery,
                token: SoshikiAPI.shared.token
            ) {
                self.searchResults = searchResults
            }
        }
    }
}
