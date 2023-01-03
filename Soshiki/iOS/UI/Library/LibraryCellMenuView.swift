//
//  LibraryCellMenuView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/15/22.
//

import SwiftUI

struct LibraryCellMenuView: View {
    @EnvironmentObject var contentViewModel: ContentViewModel

    var entry: Entry

    var body: some View {
        Group {
            Button {} label: {
                Label("Mark as Read", systemImage: "eye")
            }
            Divider()
            Menu {
                Button {} label: {
                    Text("Completed")
                }
                Button {} label: {
                    Text("Ongoing")
                }
                Button {} label: {
                    Text("Dropped")
                }
                Button {} label: {
                    Text("Planned")
                }
                Button {} label: {
                    Text("Paused")
                }
            } label: {
                Label("Set Status", systemImage: "ellipsis")
            }
            Menu {
                ForEach(0..<21) { score in
                    Button {} label: {
                        Text(String(format: "%.1f", Double(score)/2))
                    }
                }
            } label: {
                Label("Set Score", systemImage: "star")
            }
            Divider()
            if let categories = contentViewModel.libraries.first(where: { $0.mediaType == contentViewModel.currentMediaType })?.categories {
                Menu {
                    ForEach(
                        categories.filter({ $0.name != nil && $0.name != "" && !($0.entries?.contains(where: {
                            $0.entry?.id == entry.id
                        }) ?? false )}),
                        id: \.name) { category in
                        Button {
                            Task {
                                if let newLibrary = await GraphQL.mutation(
                                    MutationAddLibraryItemToCategory(
                                        mediaType: contentViewModel.currentMediaType,
                                        id: entry.id!,
                                        category: category.name!
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
                                    }
                                }
                            }
                        } label: {
                            Text(category.name ?? "")
                        }
                    }
                } label: {
                    Label("Add to Category", systemImage: "folder.badge.plus")
                }
            }
            if contentViewModel.currentCategory.name != nil && contentViewModel.currentCategory.name != "" {
                Button {
                    Task {
                        if let newLibrary = await GraphQL.mutation(
                            MutationRemoveLibraryItemFromCategory(
                                mediaType: contentViewModel.currentMediaType,
                                id: entry.id!,
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
                            }
                        }
                    }
                } label: {
                    Label("Remove from Category", systemImage: "folder.badge.minus")
                }
            }
            Divider()
        }
        Group {
            Button {} label: {
                Label("Save Cover Image", systemImage: "square.and.arrow.down")
            }
            Button {} label: {
                Label("Refresh Information", systemImage: "arrow.clockwise")
            }
            Button {} label: {
                Label("Download", systemImage: "arrow.down.circle")
            }
            Button {} label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Divider()
            Button(role: .destructive) {} label: {
                Label("Remove from Library", systemImage: "trash")
            }
        }
    }
}
