//
//  BrowseEntryView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/2/22.
//

import NukeUI
import SwiftUI

struct ImageBrowseEntryView: View {
    var shortEntry: SourceShortEntry
    var source: ImageSource

    @State var entry: SourceEntry?
    @State var chapters: [ImageSourceChapter] = []

    @State var descriptionExpanded = false

    @State var linkedEntry: EntryConnection?
    @State var history: HistoryEntry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(spacing: 20) {
                    LazyImage(url: URL(string: entry?.cover ?? shortEntry.cover)) { state in
                        if let image = state.image {
                            image
                        } else if state.error != nil {
                            Rectangle()
                                .overlay {
                                    Image(systemName: "exclamationmark.triangle")
                                }
                                .foregroundColor(.gray)
                        } else {
                            Rectangle()
                                .foregroundColor(.gray)
                        }
                    }.aspectRatio(1 / 1.5, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .frame(width: 150, height: 225)
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(style: StrokeStyle(lineWidth: 0.25))
                            .foregroundColor(.gray)
                        )
                    VStack(alignment: .leading) {
                        Spacer(minLength: 0)
                        Text(entry?.title ?? shortEntry.title)
                            .font(.title2)
                            .fontWeight(.heavy)
                        Text(entry?.staff.first ?? shortEntry.title)
                            .foregroundColor(.secondary)
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    Spacer(minLength: 0)
                }
                Text(entry?.description ?? "")
                    .lineLimit(descriptionExpanded ? nil : 4)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.subheadline)
                HStack {
                    Spacer()
                    Button {
                        descriptionExpanded.toggle()
                    } label: {
                        Text(descriptionExpanded ? "See Less" : "See More")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                }
                HStack(spacing: 10) {
                    NavigationLink {
                        ImageReaderView(
                            chapters: chapters,
                            chapter: (history?.chapter).flatMap({ chapter in
                                chapters.firstIndex(where: { $0.chapter == chapter })
                            }) ?? chapters.count - 1,
                            source: source,
                            linkedEntry: linkedEntry,
                            history: history
                        )
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                            Label(history?.chapter != nil ? "Continue Reading" : "Read Now", systemImage: "book.fill")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }.disabled(chapters.isEmpty)
                    NavigationLink {
                        if let soshikiEntry = linkedEntry?.entry {
                            EntryView(entry: soshikiEntry)
                        } else if let entry {
                            LinkView(entry: entry, source: source, linkedEntry: $linkedEntry)
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                            Image(systemName: "link")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }.frame(width: 50)
                    NavigationLink {
                        if let url = (entry?.url).flatMap({ URL(string: $0) }) {
                            WebView(url: url)
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                            Image(systemName: "safari.fill")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }.frame(width: 50)
                }.frame(height: 50)
                Text("\(chapters.count) chapters").bold()
                ForEach(chapters, id: \.id) { chapter in
                    Divider()
                    NavigationLink {
                        ImageReaderView(
                            chapters: chapters,
                            chapter: chapters.firstIndex(where: { $0.id == chapter.id })!,
                            source: source,
                            linkedEntry: linkedEntry,
                            history: history
                        )
                    } label: {
                        VStack(alignment: .leading) {
                            let volumeString = chapter.volume != nil && !chapter.volume!.isNaN ? "Volume \(chapter.volume!.toTruncatedString()) " : ""
                            let chapterNameString = chapter.name != nil && !chapter.name!.isEmpty ? ": \(chapter.name!)" : ""
                            Text("\(volumeString)Chapter \(chapter.chapter.toTruncatedString())\(chapterNameString)")
                                .font(.headline)
                                .foregroundColor((history?.chapter ?? -1) > chapter.chapter ? .secondary : .primary)
                            let chapterProgressString = (history?.page).flatMap({
                                chapter.chapter == history?.chapter ? "\($0) pages read" : nil
                            })
                            Text([chapter.translator, chapterProgressString].compactMap({ $0 }).joined(separator: " • "))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }.multilineTextAlignment(.leading)
                    }.buttonStyle(.plain)
                }
            }.padding(10)
        }.task {
            let entry = await source.getEntry(id: shortEntry.id)
            let chapters = await source.getChapters(id: shortEntry.id)
            Task { @MainActor in
                self.entry = entry
                self.chapters = chapters
            }
            linkedEntry = await GraphQL.query(
                QueryLink(mediaType: .image, platform: "Soshiki", source: source.id, sourceId: shortEntry.id),
                returning: [
                    .id,
                    .entry(SoshikiAPI.baseEntriesQuery)
                ],
                token: SoshikiAPI.shared.token
            )
            if let entryId = linkedEntry?.id {
                history = await GraphQL.query(
                    QueryHistoryEntry(mediaType: .image, id: entryId),
                    returning: [
                        .chapter,
                        .page
                    ],
                    token: SoshikiAPI.shared.token
                )
            }
        }
    }
}
