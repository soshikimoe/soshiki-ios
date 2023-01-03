//
//  LibraryListMenuView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/15/22.
//

import SwiftUI

struct LibraryCategoryMenuView: View {
    @EnvironmentObject var contentViewModel: ContentViewModel

    var body: some View {
        Menu {
            if let categories = contentViewModel.libraries.first(where: { $0.mediaType == .text })?.categories {
                Menu {
                    if let allCategory = categories.first(where: { $0.name == "" }) {
                        Button {
                            contentViewModel.currentCategory = allCategory
                        } label: {
                            if contentViewModel.currentCategory.name == allCategory.name && contentViewModel.currentMediaType == .text {
                                Label("All", systemImage: "checkmark")
                            } else {
                                Text("All")
                            }
                        }
                    }
                    ForEach(categories.filter({ $0.name != "" }), id: \.name) { category in
                        Button {
                            contentViewModel.currentCategory = category
                        } label: {
                            if contentViewModel.currentCategory.name == category.name && contentViewModel.currentMediaType == .text {
                                Label(category.name ?? "", systemImage: "checkmark")
                            } else {
                                Text(category.name ?? "")
                            }
                        }
                    }
                } label: {
                    Label("Text", systemImage: "doc.text")
                }
            }
            if let categories = contentViewModel.libraries.first(where: { $0.mediaType == .image })?.categories {
                Menu {
                    if let allCategory = categories.first(where: { $0.name == "" }) {
                        Button {
                            contentViewModel.currentCategory = allCategory
                        } label: {
                            if contentViewModel.currentCategory.name == allCategory.name && contentViewModel.currentMediaType == .image {
                                Label("All", systemImage: "checkmark")
                            } else {
                                Text("All")
                            }
                        }
                    }
                    ForEach(categories.filter({ $0.name != "" }), id: \.name) { category in
                        Button {
                            contentViewModel.currentCategory = category
                        } label: {
                            if contentViewModel.currentCategory.name == category.name && contentViewModel.currentMediaType == .image {
                                Label(category.name ?? "", systemImage: "checkmark")
                            } else {
                                Text(category.name ?? "")
                            }
                        }
                    }
                } label: {
                    Label("Image", systemImage: "book")
                }
            }
            if let categories = contentViewModel.libraries.first(where: { $0.mediaType == .video })?.categories {
                Menu {
                    if let allCategory = categories.first(where: { $0.name == "" }) {
                        Button {
                            contentViewModel.currentCategory = allCategory
                        } label: {
                            if contentViewModel.currentCategory.name == allCategory.name && contentViewModel.currentMediaType == .video {
                                Label("All", systemImage: "checkmark")
                            } else {
                                Text("All")
                            }
                        }
                    }
                    ForEach(categories.filter({ $0.name != "" }), id: \.name) { category in
                        Button {
                            contentViewModel.currentCategory = category
                        } label: {
                            if contentViewModel.currentCategory.name == category.name && contentViewModel.currentMediaType == .video {
                                Label(category.name ?? "", systemImage: "checkmark")
                            } else {
                                Text(category.name ?? "")
                            }
                        }
                    }
                } label: {
                    Label("Video", systemImage: "film")
                }
            }
            Divider()
            Button {} label: {
                Label("Edit", systemImage: "pencil")
            }
        } label: {
            Image(systemName: "folder")
        }
    }
}
