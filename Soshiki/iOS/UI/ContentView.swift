//
//  ContentView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/14/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject var contentViewModel = ContentViewModel()

    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "folder.fill")
                }
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "globe")
                }
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }.environmentObject(contentViewModel)
    }
}

@MainActor class ContentViewModel: ObservableObject {
    @Published var libraries: [Library] = []
    @Published var currentCategory: Category = Category(name: nil, entries: nil)
    @Published var currentMediaType: MediaType = .image

    @Published var isUpdatingLibraryStatus = false

    func refreshLibraries() async {
        let libraries = await GraphQL.query(QueryLibraries(), returning: SoshikiAPI.baseLibrariesQuery, token: SoshikiAPI.shared.token) ?? []
        Task { [weak self] in
            self?.libraries = libraries
            if let currentCategory = self?.currentCategory, currentCategory.name == nil {
                self?.currentCategory = libraries.first(where: { $0.mediaType == .image })?
                    .categories?
                    .first(where: { $0.name == "" }) ?? currentCategory
            }
        }
    }

    func toggleLibraryStatus(for entry: Entry) {
        Task {
            isUpdatingLibraryStatus = true
            if libraries.first(where: { $0.mediaType == currentMediaType })?
                        .categories?.first(where: { $0.name == "" })?
                        .entries?.contains(where: { $0.entry?.id == entry.id }) ?? false {
                if let library = await GraphQL.mutation(
                    MutationRemoveLibraryItem(
                        mediaType: currentMediaType,
                        id: entry.id!
                    ),
                    returning: SoshikiAPI.baseLibrariesQuery,
                    token: SoshikiAPI.shared.token
                ) {
                    if let index = libraries.firstIndex(where: { $0.mediaType == library.mediaType }) {
                        libraries[index] = library
                    }
                }
            } else {
                if let library = await GraphQL.mutation(
                    MutationAddLibraryItem(
                        mediaType: currentMediaType,
                        id: entry.id!,
                        category: nil
                    ),
                    returning: SoshikiAPI.baseLibrariesQuery,
                    token: SoshikiAPI.shared.token
                ) {
                    if let index = libraries.firstIndex(where: { $0.mediaType == library.mediaType }) {
                        libraries[index] = library
                    }
                }
            }
            isUpdatingLibraryStatus = false
        }
    }
}
