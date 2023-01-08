//
//  LibraryCategoryEditView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/7/23.
//

import SwiftUI

struct LibraryCategoryEditView: View {
    @EnvironmentObject var contentViewModel: ContentViewModel

    @State var textContent = ""
    @State var imageContent = ""
    @State var videoContent = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Text") {
                    ForEach(contentViewModel.libraries?.text.categories ?? [], id: \.id) { category in
                        Text(category.name)
                    }.onDelete { indexSet in
                        indexSet.forEach({ index in
                            if let item = contentViewModel.libraries?.text.categories[index] {
                                Task {
                                    await SoshikiAPI.shared.deleteLibraryCategory(mediaType: .text, id: item.id)
                                    await contentViewModel.refreshLibraries()
                                }
                            }
                        })
                    }
                    TextField("Create New...", text: $textContent) {
                        guard contentViewModel.libraries?.text.categories.contains(where: { $0.id == textContent.lowercased() }) == false else {
                            return
                        }
                        Task {
                            await SoshikiAPI.shared.addLibraryCategory(mediaType: .text, id: textContent.lowercased(), name: textContent)
                            await contentViewModel.refreshLibraries()
                            textContent = ""
                        }
                    }
                }
                Section("Image") {
                    ForEach(contentViewModel.libraries?.image.categories ?? [], id: \.id) { category in
                        Text(category.name)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach({ index in
                            if let item = contentViewModel.libraries?.image.categories[index] {
                                Task {
                                    await SoshikiAPI.shared.deleteLibraryCategory(mediaType: .image, id: item.id)
                                    await contentViewModel.refreshLibraries()
                                }
                            }
                        })
                    }
                    TextField("Create New...", text: $imageContent) {
                        guard contentViewModel.libraries?.image.categories.contains(where: { $0.id == imageContent.lowercased() }) == false else {
                            return
                        }
                        Task {
                            await SoshikiAPI.shared.addLibraryCategory(mediaType: .image, id: imageContent.lowercased(), name: imageContent)
                            await contentViewModel.refreshLibraries()
                            imageContent = ""
                        }
                    }
                }
                Section("Video") {
                    ForEach(contentViewModel.libraries?.video.categories ?? [], id: \.id) { category in
                        Text(category.name)
                    }.onDelete { indexSet in
                        indexSet.forEach({ index in
                            if let item = contentViewModel.libraries?.video.categories[index] {
                                Task {
                                    await SoshikiAPI.shared.deleteLibraryCategory(mediaType: .video, id: item.id)
                                    await contentViewModel.refreshLibraries()
                                }
                            }
                        })
                    }
                    TextField("Create New...", text: $videoContent) {
                        guard contentViewModel.libraries?.video.categories.contains(where: { $0.id == videoContent.lowercased() }) == false else {
                            return
                        }
                        Task {
                            await SoshikiAPI.shared.addLibraryCategory(mediaType: .video, id: videoContent.lowercased(), name: videoContent)
                            await contentViewModel.refreshLibraries()
                            videoContent = ""
                        }
                    }
                }
            }.navigationTitle("Categories")
        }
    }
}
