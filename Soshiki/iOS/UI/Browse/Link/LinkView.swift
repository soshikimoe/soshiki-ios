//
//  LinkView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/1/23.
//

import SwiftUI

/*
struct LinkView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var entry: SourceEntry
    var source: any Source
    @Binding var linkedEntry: Entry?

    @State var results: [Entry] = []

    @State var searchText = ""
    @State var searchTask: Task<Void, Never>?

    var body: some View {
        SearchBar(text: $searchText, onCommit: {
            searchTask?.cancel()
            searchTask = Task {
                results = (try? await SoshikiAPI.shared.getEntries(
                    mediaType: source is (any TextSource) ? .text : source is (any ImageSource) ? .image : .video,
                    query: [ .title(searchText) ]
                ).get()) ?? []
            }
        })
        List(results, id: \._id) { entry in
            Button {
                linkedEntry = entry
                Task {
                    let res = await SoshikiAPI.shared.setLink(
                        mediaType: entry.mediaType,
                        id: entry._id,
                        platformId: "soshiki",
                        platformName: "Soshiki",
                        sourceId: source.id,
                        sourceName: source.name,
                        entryId: self.entry.id
                    )
                    print(res)
                    presentationMode.wrappedValue.dismiss()
                }
            } label: {
                EntryRowView(entry: entry.toLocalEntry())
            }
        }.task {
            results = (try? await SoshikiAPI.shared.getEntries(
                mediaType: source is (any TextSource) ? .text : source is (any ImageSource) ? .image : .video,
                query: [ .title(entry.title) ]
            ).get()) ?? []
        }
    }
}
*/
