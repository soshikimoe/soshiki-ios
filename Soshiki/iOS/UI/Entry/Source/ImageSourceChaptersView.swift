//
//  ImageSourceChaptersView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/2/23.
//

import SwiftUI

struct ImageSourceChaptersView: View {
    var sources: [ImageSource]

    var entry: Entry

    @State var chapters: [ImageSourceChapter] = []

    @State var descriptionExpanded = false

    @State var selectedSource: ImageSource?

    @State var sourceEntry: SourceEntry?

    var accentColor: Color?

    @EnvironmentObject var contentViewModel: ContentViewModel

    @State var history: HistoryEntry?

    init(entry: Entry, sources: [ImageSource]) {
        self.sources = sources
        self.selectedSource = sources[safe: 0]
        self.entry = entry
        self.accentColor = Color(hex: entry.info?.anilist?.coverImage?.color ?? "")
    }

    var body: some View {
        Group {
            HStack(spacing: 10) {
                NavigationLink {
                    if !chapters.isEmpty, let source = selectedSource {
                        ImageReaderView(
                            chapters: chapters,
                            chapter: history?.chapter.flatMap({ chapter in
                                chapters.firstIndex(where: { $0.chapter == chapter })
                            }) ?? chapters.count - 1,
                            source: source,
                            linkedEntry: EntryConnection(id: entry.id, entry: entry),
                            history: history
                        )
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                        Label(history?.episode != nil ? "Continue Reading" : "Read Now", systemImage: "book.fill")
                            .fontWeight(.semibold)
                            .foregroundColor(accentColor?.contrastingFontColor() ?? .white)
                    }
                }.disabled(chapters.isEmpty)
                Button {
                    contentViewModel.toggleLibraryStatus(for: entry)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                        Image(systemName: contentViewModel.libraries.first(where: {
                                $0.mediaType == contentViewModel.currentMediaType
                            })?.categories?.first(where: { $0.name == "" })?
                                .entries?.contains(where: { $0.entry?.id == entry.id }) ?? false ? "bookmark.fill" : "bookmark"
                        )
                            .foregroundColor(accentColor?.contrastingFontColor() ?? .white)
                            .fontWeight(.semibold)
                    }
                }.frame(width: 50)
                    .disabled(contentViewModel.isUpdatingLibraryStatus)
                Button {

                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                        Image(systemName: "gear")
                            .foregroundColor(accentColor?.contrastingFontColor() ?? .white)
                            .fontWeight(.semibold)
                    }
                }.frame(width: 50)
                let url = (sourceEntry?.url).flatMap({ URL(string: $0) })
                NavigationLink {
                    if let url {
                        WebView(url: url)
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                        Image(systemName: "safari.fill")
                            .fontWeight(.semibold)
                            .foregroundColor(accentColor?.contrastingFontColor() ?? .white)
                    }
                }.frame(width: 50)
                    .disabled(url == nil)
            }.frame(height: 50)
            HStack {
                Text("\(chapters.count) chapters").bold()
                Spacer()
                if !sources.isEmpty {
                    Picker("Source", selection: Binding(get: {
                        selectedSource.flatMap({ $0.id }) ?? ""
                    }, set: { newValue in
                        selectedSource = sources.first(where: { $0.id == newValue })
                    }) as Binding<String>) {
                        ForEach(sources) { source in
                            Text(source.name).tag(source.id)
                        }
                    }
                } else {
                    Text("No Linked Sources")
                }
            }
            VStack(alignment: .leading) {
                ForEach(chapters, id: \.id) { chapter in
                    Divider()
                    NavigationLink {
                        if let source = selectedSource {
                            ImageReaderView(
                                chapters: chapters,
                                chapter: chapters.firstIndex(where: { $0.id == chapter.id })!,
                                source: source,
                                linkedEntry: EntryConnection(id: entry.id, entry: entry),
                                history: history
                            )
                        }
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
            if let source = sources.first,
               let id = entry.platforms?.first(where: { $0.name == "Soshiki" })?.sources?.first(where: { $0.name == source.id })?.id {
                self.sourceEntry = await source.getEntry(id: id)
                self.chapters = await source.getChapters(id: id)
            }
            if let entryId = entry.id {
                history = await GraphQL.query(
                    QueryHistoryEntry(mediaType: .image, id: entryId),
                    returning: [
                        .page,
                        .chapter
                    ],
                    token: SoshikiAPI.shared.token
                )
            }
        }.onChange(of: selectedSource) { newValue in
            self.sourceEntry = nil
            self.chapters = []
            Task {
                if let source = newValue,
                   let id = entry.platforms?.first(where: { $0.name == "Soshiki" })?.sources?.first(where: { $0.name == source.id })?.id {
                    self.sourceEntry = await source.getEntry(id: id)
                    self.chapters = await source.getChapters(id: id)
                }
            }
        }
    }
}
