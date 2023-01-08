//
//  LibraryCellMenuView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/15/22.
//

import SwiftUI
import NukeUI

struct LibraryCellMenuView: View {
    @EnvironmentObject var contentViewModel: ContentViewModel
    var libraryViewModel: LibraryViewModel?

    var entry: Entry

    @State var history: History?

    var body: some View {
        Group {
//            Button {} label: {
//                Label("Mark as Read", systemImage: "eye")
//            }
//            Divider()
            Menu {
                Button {
                    Task {
                        await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [ .status(.completed) ])
                        history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get()
                    }
                } label: {
                    if history?.status == .completed {
                        Label("Completed", systemImage: "checkmark")
                    } else {
                        Text("Completed")
                    }
                }
                Button {
                    Task {
                        await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [ .status(.inProgress) ])
                        history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get()
                    }
                } label: {
                    if history?.status == .inProgress {
                        Label("In Progress", systemImage: "checkmark")
                    } else {
                        Text("In Progress")
                    }
                }
                Button {
                    Task {
                        await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [ .status(.dropped) ])
                        history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get()
                    }
                } label: {
                    if history?.status == .dropped {
                        Label("Dropped", systemImage: "checkmark")
                    } else {
                        Text("Dropped")
                    }
                }
                Button {
                    Task {
                        await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [ .status(.planned) ])
                        history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get()
                    }
                } label: {
                    if history?.status == .planned {
                        Label("Planned", systemImage: "checkmark")
                    } else {
                        Text("Planned")
                    }
                }
                Button {
                    Task {
                        await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [ .status(.paused) ])
                        history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get()
                    }
                } label: {
                    if history?.status == .paused {
                        Label("Paused", systemImage: "checkmark")
                    } else {
                        Text("Paused")
                    }
                }
            } label: {
                Label("Set Status", systemImage: "ellipsis")
            }
            Menu {
                ForEach(0..<21) { score in
                    Button {
                        Task {
                            await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [ .score(Double(score)/2) ])
                            history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get()
                        }
                    } label: {
                        if history?.score == Double(score)/2 {
                            Label(String(format: "%.1f", Double(score)/2), systemImage: "checkmark")
                        } else {
                            Text(String(format: "%.1f", Double(score)/2))
                        }
                    }
                }
            } label: {
                Label("Set Score", systemImage: "star")
            }
            Divider()
            Menu {
                ForEach(contentViewModel.library(forMediaType: entry.mediaType)?.categories.filter({
                    !$0.ids.contains(entry._id)
                }) ?? [], id: \.id) { category in
                    Button {
                        Task {
                            await SoshikiAPI.shared.addEntryToLibraryCategory(
                                mediaType: entry.mediaType,
                                id: category.id,
                                entryId: entry._id
                            )
                            await contentViewModel.refreshLibraries()
                            libraryViewModel?.setCategory(to: libraryViewModel?.category)
                        }
                    } label: {
                        Text(category.name)
                    }
                }
            } label: {
                Label("Add to Category", systemImage: "folder.badge.plus")
            }
            if let category = libraryViewModel?.category {
                Button {
                    Task {
                        await SoshikiAPI.shared.deleteEntryFromLibraryCategory(
                            mediaType: entry.mediaType,
                            id: category,
                            entryId: entry._id
                        )
                        await contentViewModel.refreshLibraries()
                        libraryViewModel?.setCategory(to: libraryViewModel?.category)
                    }
                } label: {
                    Label("Remove from Category", systemImage: "folder.badge.minus")
                }
            }
            Divider()
        }
        Group {
            Button {
                Task {
                    guard let url = entry.covers.first.flatMap({ URL(string: $0.image) }),
                          let response = try? await ImagePipeline.shared.image(for: url) else { return }
                    UIImageWriteToSavedPhotosAlbum(response.image, nil, nil, nil)
                }
            } label: {
                Label("Save Cover Image", systemImage: "square.and.arrow.down")
            }
//            Button {} label: {
//                Label("Download", systemImage: "arrow.down.circle")
//            }
//            Button {} label: {
//                Label("Share", systemImage: "square.and.arrow.up")
//            }
            Divider()
            Button(role: .destructive) {
                Task {
                    await SoshikiAPI.shared.deleteEntryFromLibrary(mediaType: entry.mediaType, entryId: entry._id)
                    libraryViewModel?.refresh()
                }
            } label: {
                Label("Remove from Library", systemImage: "trash")
            }
        }.task {
            history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get()
        }
    }
}
