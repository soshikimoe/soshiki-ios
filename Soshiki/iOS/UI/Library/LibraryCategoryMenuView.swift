//
//  LibraryListMenuView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/15/22.
//

import SwiftUI

struct LibraryCategoryMenuView: View {
    @EnvironmentObject var contentViewModel: ContentViewModel
    @ObservedObject var libraryViewModel: LibraryViewModel

    var body: some View {
        Menu {
            if let libraries = contentViewModel.libraries {
                Menu {
                    Button {
                        contentViewModel.mediaType = .text
                        libraryViewModel.setCategory(to: nil)
                    } label: {
                        if contentViewModel.mediaType == .text, libraryViewModel.category == nil {
                            Label("All", systemImage: "checkmark")
                        } else {
                            Text("All")
                        }
                    }
                    ForEach(libraries.text.categories, id: \.id) { category in
                        Button {
                            contentViewModel.mediaType = .text
                            libraryViewModel.setCategory(to: category.id)
                        } label: {
                            if contentViewModel.mediaType == .text, libraryViewModel.category == category.id {
                                Label(category.name, systemImage: "checkmark")
                            } else {
                                Text(category.name)
                            }
                        }
                    }
                } label: {
                    Text("Text")
                }
                Menu {
                    Button {
                        contentViewModel.mediaType = .image
                        libraryViewModel.setCategory(to: nil)
                    } label: {
                        if contentViewModel.mediaType == .image, libraryViewModel.category == nil {
                            Label("All", systemImage: "checkmark")
                        } else {
                            Text("All")
                        }
                    }
                    ForEach(libraries.image.categories, id: \.id) { category in
                        Button {
                            contentViewModel.mediaType = .image
                            libraryViewModel.setCategory(to: category.id)
                        } label: {
                            if contentViewModel.mediaType == .image, libraryViewModel.category == category.id {
                                Label(category.name, systemImage: "checkmark")
                            } else {
                                Text(category.name)
                            }
                        }
                    }
                } label: {
                    Text("Image")
                }
                Menu {
                    Button {
                        contentViewModel.mediaType = .video
                        libraryViewModel.setCategory(to: nil)
                    } label: {
                        if contentViewModel.mediaType == .video, libraryViewModel.category == nil {
                            Label("All", systemImage: "checkmark")
                        } else {
                            Text("All")
                        }
                    }
                    ForEach(libraries.video.categories, id: \.id) { category in
                        Button {
                            contentViewModel.mediaType = .video
                            libraryViewModel.setCategory(to: category.id)
                        } label: {
                            if contentViewModel.mediaType == .video, libraryViewModel.category == category.id {
                                Label(category.name, systemImage: "checkmark")
                            } else {
                                Text(category.name)
                            }
                        }
                    }
                } label: {
                    Text("Video")
                }
            }
            Divider()
            NavigationLink {
                LibraryCategoryEditView()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        } label: {
            Image(systemName: "folder")
        }
    }
}
