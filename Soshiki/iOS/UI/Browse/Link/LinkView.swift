//
//  LinkView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/1/23.
//

import SwiftUI
import SwiftUIX

struct LinkView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var entry: SourceEntry
    var source: Source
    @Binding var linkedEntry: EntryConnection?

    @State var results: [Entry] = []

    @State var searchText = ""
    @State var searchTask: Task<Void, Never>?

    var body: some View {
        SearchBar(text: $searchText, onCommit: {
            searchTask?.cancel()
            searchTask = Task {
                results = await GraphQL.query(
                    QuerySearch(
                        mediaType: source is TextSource ? .text : source is ImageSource ? .image : .video,
                        query: searchText
                    ),
                    returning: SoshikiAPI.baseEntriesQuery,
                    token: SoshikiAPI.shared.token
                ) ?? []
            }
        })
        List(results, id: \.id!) { entry in
            Button {
                linkedEntry = EntryConnection(id: entry.id, entry: entry)
                Task {
                    _ = await GraphQL.mutation(
                        MutationSetLink(
                            mediaType: source is TextSource ? .text : source is ImageSource ? .image : .video,
                            platform: "Soshiki",
                            source: source.id,
                            sourceId: self.entry.id,
                            id: entry.id!
                        ),
                        returning: [.id],
                        token: SoshikiAPI.shared.token
                    )
                    presentationMode.wrappedValue.dismiss()
                }
            } label: {
                EntryRowView(
                    title: entry.info?.title ?? "",
                    subtitle: entry.info?.author ?? "",
                    cover: entry.info?.anilist?.coverImage?.large ?? entry.info?.cover ?? ""
                )
            }
        }.task {
            results = await GraphQL.query(
                QuerySearch(
                    mediaType: source is TextSource ? .text : source is ImageSource ? .image : .video,
                    query: entry.title
                ),
                returning: SoshikiAPI.baseEntriesQuery,
                token: SoshikiAPI.shared.token
            ) ?? []
        }
    }
}
