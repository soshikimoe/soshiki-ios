//
//  LibraryView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/14/22.
//

import SwiftUI
import Introspect

struct LibraryView: View {
    @AppStorage("settings.library.itemsPerRow") var itemsPerRow: Int = 3

    @StateObject var libraryViewModel = LibraryViewModel()
    @EnvironmentObject var contentViewModel: ContentViewModel

    var gridItems: [GridItem]!

    init() {
        gridItems = .init(repeating: .init(.flexible(), spacing: 10), count: itemsPerRow)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridItems, spacing: 10) {
                    ForEach(
                        contentViewModel.libraries
                            .first(where: { $0.mediaType == contentViewModel.currentMediaType })?.categories?
                            .first(where: { $0.name == contentViewModel.currentCategory.name })?.entries?
                            .filter({ $0.entry != nil }) ?? [],
                        id: \.entry!.id!
                    ) { item in
                        Button {
                            if libraryViewModel.selecting && libraryViewModel.selections.contains(where: { $0.id == item.entry!.id }) {
                                libraryViewModel.selections.removeAll(where: { $0.id == item.entry!.id })
                            } else {
                                libraryViewModel.selections.append(item.entry!)
                            }
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                NavigationLink {
                                    EntryView(entry: item.entry!)
                                } label: {
                                    EntryCellView(
                                        title: item.entry!.info?.title ?? "",
                                        subtitle: "",
                                        cover: item.entry!.info?.anilist?.coverImage?.large ?? item.entry!.info?.cover ?? ""
                                    )
                                        .contextMenu {
                                            LibraryCellMenuView(entry: item.entry!)
                                        }
                                }.allowsHitTesting(!libraryViewModel.selecting)
                                if libraryViewModel.selecting {
                                    if libraryViewModel.selections.contains(where: { $0.id == item.entry!.id }) {
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
                scrollView.refreshControl = libraryViewModel.refreshControl
            }.toolbar {
                if libraryViewModel.selecting {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            libraryViewModel.selecting = false
                        } label: {
                            Text("Done")
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Menu {
                            if contentViewModel.currentCategory.name != "" {
                                Button {
                                    Task {
                                        if let newLibrary = await GraphQL.mutation(
                                            MutationRemoveLibraryItemsFromCategory(
                                                mediaType: contentViewModel.currentMediaType,
                                                ids: libraryViewModel.selections.map({ $0.id! }),
                                                category: contentViewModel.currentCategory.name!
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
                                                libraryViewModel.selecting = false
                                            }
                                        }
                                    }
                                } label: {
                                    Label("Remove from Category", systemImage: "folder.badge.minus")
                                }
                            }
                            Button {
                                Task {
                                    if let newLibrary = await GraphQL.mutation(
                                        MutationRemoveLibraryItems(
                                            mediaType: contentViewModel.currentMediaType,
                                            ids: libraryViewModel.selections.map({ $0.id! })
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
                                            libraryViewModel.selecting = false
                                        }
                                    }
                                }
                            } label: {
                                Label("Remove from Library", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        LibraryCategoryMenuView()
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            libraryViewModel.selecting = true
                        } label: {
                            Image(systemName: "checkmark.circle")
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    let category = contentViewModel.currentCategory.name.flatMap({ $0 == "" ? "All" : $0 }) ?? ""
                    let mediaType = contentViewModel.currentMediaType.rawValue.capitalized
                    Text("\(category) - \(mediaType)")
                }
            }.toolbar(libraryViewModel.selecting ? .hidden : .visible, for: .tabBar)
                .toolbar(libraryViewModel.selecting ? .visible : .hidden, for: .bottomBar)
                .navigationTitle("Library")
        }.task {
            await contentViewModel.refreshLibraries()
        }.onAppear {
            libraryViewModel.contentViewModel = contentViewModel
        }.environmentObject(libraryViewModel)
    }
}

@MainActor class LibraryViewModel: ObservableObject {
    let refreshControl = UIRefreshControl()

    var contentViewModel: ContentViewModel?

    @Published var selecting: Bool = false {
        didSet {
            if !selecting {
                selections = []
            }
        }
    }
    @Published var selections: [Entry] = []

    init() {
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    @objc func refresh() {
        Task { [weak self] in
            await self?.contentViewModel?.refreshLibraries()
            self?.refreshControl.endRefreshing()
        }
    }
}
