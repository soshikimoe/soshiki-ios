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
                    let entries = contentViewModel.mediaType == .text
                        ? libraryViewModel.textEntries
                        : contentViewModel.mediaType == .image ? libraryViewModel.imageEntries : libraryViewModel.videoEntries
                    ForEach(entries, id: \._id) { entry in
                        NavigationLink {
                            EntryView(libraryViewModel: libraryViewModel, entry: entry)
                        } label: {
                            EntryCellView(entry: entry.toUnifiedEntry())
                        }.contextMenu {
                            LibraryCellMenuView(libraryViewModel: libraryViewModel, entry: entry)
                        }
                    }
                }.padding(10)
            }.introspectScrollView { scrollView in
                scrollView.refreshControl = libraryViewModel.refreshControl
            }.toolbar {
                if let categoryName = contentViewModel.library(forMediaType: contentViewModel.mediaType)?.categories.first(where: {
                    $0.id == libraryViewModel.category
                })?.name ?? (libraryViewModel.category == nil ? "All" : nil) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text("\(categoryName) - \(contentViewModel.mediaType.rawValue.capitalized)")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    LibraryCategoryMenuView(libraryViewModel: libraryViewModel)
                }
            }.navigationTitle("Library")
//                .toolbar(libraryViewModel.selecting ? .hidden : .visible, for: .tabBar)
//                .toolbar(libraryViewModel.selecting ? .visible : .hidden, for: .bottomBar)
        }.onChange(of: contentViewModel.mediaType) { _ in
            libraryViewModel.setCategory(to: nil)
        }.onAppear {
            libraryViewModel.contentViewModel = contentViewModel
            libraryViewModel.refresh()
        }.environmentObject(libraryViewModel)
    }
}

@MainActor class LibraryViewModel: ObservableObject {
    let refreshControl = UIRefreshControl()

    var contentViewModel: ContentViewModel!

    var allTextEntries: [Entry] = []
    @Published var textEntries: [Entry] = []

    var allImageEntries: [Entry] = []
    @Published var imageEntries: [Entry] = []

    var allVideoEntries: [Entry] = []
    @Published var videoEntries: [Entry] = []

    @Published var category: String?

    init() {
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    @objc func refresh() {
        Task { [weak self] in
            await self?.contentViewModel?.refreshLibraries()
            allTextEntries = []
            for offset in stride(from: 0, to: contentViewModel?.libraries?.text.all.ids.count ?? 0, by: 100) {
                if let newEntries = try? await SoshikiAPI.shared.getEntries(mediaType: .text, query: [
                    .ids(contentViewModel?.libraries?.text.all.ids ?? []), .limit(100), .offset(offset)
                ]).get() {
                    allTextEntries.append(contentsOf: newEntries)
                }
            }
            allImageEntries = []
            for offset in stride(from: 0, to: contentViewModel?.libraries?.image.all.ids.count ?? 0, by: 100) {
                if let newEntries = try? await SoshikiAPI.shared.getEntries(mediaType: .image, query: [
                    .ids(contentViewModel?.libraries?.image.all.ids ?? []), .limit(100), .offset(offset)
                ]).get() {
                    allImageEntries.append(contentsOf: newEntries)
                }
            }
            allVideoEntries = []
            for offset in stride(from: 0, to: contentViewModel?.libraries?.video.all.ids.count ?? 0, by: 100) {
                if let newEntries = try? await SoshikiAPI.shared.getEntries(mediaType: .video, query: [
                    .ids(contentViewModel?.libraries?.video.all.ids ?? []), .limit(100), .offset(offset)
                ]).get() {
                    allVideoEntries.append(contentsOf: newEntries)
                }
            }
            self?.setCategory(to: self?.category)
            self?.refreshControl.endRefreshing()
        }
    }

    func setCategory(to category: String?) {
        if let category,
           let ids = contentViewModel.library(forMediaType: contentViewModel.mediaType)?.categories.first(where: { $0.id == category })?.ids {
            switch contentViewModel.mediaType {
            case .text: self.textEntries = allTextEntries.filter({ ids.contains($0._id) })
            case .image: self.imageEntries = allImageEntries.filter({ ids.contains($0._id) })
            case .video: self.videoEntries = allVideoEntries.filter({ ids.contains($0._id) })
            }
        } else {
            switch contentViewModel.mediaType {
            case .text: self.textEntries = allTextEntries
            case .image: self.imageEntries = allImageEntries
            case .video: self.videoEntries = allVideoEntries
            }
        }
        self.category = category
    }
}
