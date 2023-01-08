//
//  BrowseEntryView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/2/22.
//

import NukeUI
import SwiftUI

struct ImageBrowseEntryView: View {
    @Environment(\.presentationMode) var presentationMode

    var shortEntry: SourceShortEntry
    var source: ImageSource

    @State var entry: SourceEntry?
    @State var chapters: [ImageSourceChapter] = []

    @State var descriptionExpanded = false

    @State var linkedEntry: Entry?
    @State var history: History?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                EntryHeaderView(entry: entry?.toUnifiedEntry() ?? shortEntry.toUnifiedEntry())
                HStack(spacing: 10) {
                    NavigationLink {
                        ImageReaderView(
                            chapters: chapters,
                            chapter: (history?.chapter).flatMap({ chapter in
                                chapters.firstIndex(where: { $0.chapter == chapter })
                            }) ?? chapters.count - 1,
                            source: source,
                            entry: nil,
                            history: nil
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
                        if let entry = linkedEntry {
                            EntryView(entry: entry)
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
                            entry: nil,
                            history: nil
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
        }.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .foregroundStyle(.white, .tint, .tint)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(.white, .tint, .tint)
                }
            }
        }.task {
            let entry = await source.getEntry(id: shortEntry.id)
            let chapters = await source.getChapters(id: shortEntry.id)
            Task { @MainActor in
                self.entry = entry
                self.chapters = chapters
            }
            linkedEntry = (try? await SoshikiAPI.shared.getLink(
                mediaType: .image,
                platformId: "soshiki",
                sourceId: source.id,
                entryId: shortEntry.id
            ).get())?.first
            if let entry = linkedEntry {
                history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get()
            }
        }
    }
}
