//
//  EntrySourceListView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/5/23.
//

import SwiftUI

struct EntrySourceListView: View {
    @EnvironmentObject var contentViewModel: ContentViewModel

    let entry: Entry

    let sources: [Source]
    @State var source: Source?

    @State var history: History?

    @State var chapters: [ImageSourceChapter] = []
    @State var episodes: [VideoSourceEpisode] = []

    @State var sourceEntry: SourceEntry?

    @State var apiTask: Task<Void, Never>?

    let accentColor: Color?

    @State var webViewShown = false

    init(entry: Entry) {
        self.entry = entry
        self.sources = entry.platforms.first(where: { $0.id == "soshiki" })?.sources.enumerated().compactMap({ offset, source in
            entry.platforms.first(where: { $0.id == "soshiki" })?.sources.firstIndex(where: { source.id == $0.id }) == offset
                ? SourceManager.shared.sources.first(where: { $0.id == source.id })
                : nil
        }) ?? []
        self.source = sources.first
        self.accentColor = entry.color.flatMap({ Color(hex: $0) })
    }

    var body: some View {
        VStack {
            HStack(spacing: 10) {
                NavigationLink {
                    switch source {
                    case _ as TextSource:
                        EmptyView()
                    case let source as ImageSource:
                        ImageReaderView(
                            chapters: chapters,
                            chapter: history?.chapter.flatMap({ chapter in
                                chapters.firstIndex(where: { $0.chapter == chapter })
                            }) ?? chapters.count - 1,
                            source: source,
                            entry: entry,
                            history: history
                        )
                    case let source as VideoSource:
                        VideoPlayerView(
                            episodes: episodes,
                            episode: history?.episode.flatMap({ episode in
                                episodes.firstIndex(where: { $0.episode == episode })
                            }) ?? episodes.count - 1,
                            source: source,
                            entry: entry,
                            history: history
                        )
                    default:
                        EmptyView()
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                        if source is VideoSource {
                            Label(history?.episode != nil ? "Continue Watching" : "Watch Now", systemImage: "play.fill")
                                .fontWeight(.semibold)
                                .foregroundColor(accentColor?.contrastingFontColor() ?? .white)
                        } else {
                            Label(history?.chapter != nil ? "Continue Reading" : "Read Now", systemImage: "book.fill")
                                .fontWeight(.semibold)
                                .foregroundColor(accentColor?.contrastingFontColor() ?? .white)
                        }
                    }
                }
                Button {
                    self.apiTask = Task {
                        if contentViewModel.library(forMediaType: contentViewModel.mediaType)?.all.ids.contains(entry._id) == true {
                            await SoshikiAPI.shared.deleteEntryFromLibrary(mediaType: contentViewModel.mediaType, entryId: entry._id)
                        } else {
                            await SoshikiAPI.shared.addEntryToLibrary(mediaType: contentViewModel.mediaType, entryId: entry._id)
                        }
                        await contentViewModel.refreshLibraries()
                        self.apiTask = nil
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                        Image(systemName:
                            contentViewModel.library(forMediaType: contentViewModel.mediaType)?.all.ids.contains(entry._id) == true
                              ? "bookmark.fill"
                              : "bookmark"
                        ).foregroundColor(accentColor?.contrastingFontColor() ?? .white)
                            .fontWeight(.semibold)
                    }
                }.frame(width: 50)
                    .disabled(apiTask != nil)
                Button {
                    webViewShown.toggle()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                        Image(systemName: "safari.fill")
                            .fontWeight(.semibold)
                            .foregroundColor(accentColor?.contrastingFontColor() ?? .white)
                    }
                }.frame(width: 50)
                    .sheet(isPresented: $webViewShown) {
                        if let url = (sourceEntry?.url).flatMap({ URL(string: $0) }) {
                            WebView(url: url)
                        }
                    }
            }.frame(height: 50)
            HStack {
                if source is VideoSource {
                    Text("\(episodes.count) episodes").bold()
                } else {
                    Text("\(chapters.count) chapters").bold()
                }
                Spacer()
                Text("Source")
                Menu {
                    Button {
                        source = nil
                    } label: {
                        if source == nil {
                            Label("None", systemImage: "checkmark")
                        } else {
                            Text("None")
                        }
                    }
                    ForEach(sources, id: \.id) { source in
                        Button {
                            self.source = source
                        } label: {
                            if self.source == source {
                                Label(source.name, systemImage: "checkmark")
                            } else {
                                Text(source.name)
                            }
                        }
                    }
                } label: {
                    Text(source?.name ?? "None").padding(.trailing, -3)
                    Image(systemName: "chevron.down")
                }
            }
            VStack(alignment: .leading) {
                switch source {
                case _ as TextSource:
                    EmptyView()
                case let source as ImageSource:
                    ForEach(chapters.enumerated().map({ $0 }), id: \.element.id) { offset, chapter in
                        Divider()
                        NavigationLink {
                            ImageReaderView(
                                chapters: chapters,
                                chapter: offset,
                                source: source,
                                entry: entry,
                                history: history
                            )
                        } label: {
                            VStack(alignment: .leading) {
                                Text(chapter.toListString())
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
                case let source as VideoSource:
                    ForEach(episodes.enumerated().map({ $0 }), id: \.element.id) { offset, episode in
                        Divider()
                        NavigationLink {
                            VideoPlayerView(
                                episodes: episodes,
                                episode: offset,
                                source: source,
                                entry: entry,
                                history: history
                            )
                        } label: {
                            VStack(alignment: .leading) {
                                Text(episode.toListString())
                                    .font(.headline)
                                    .foregroundColor((history?.episode ?? -1) > episode.episode ? .secondary : .primary)
                                let episodeProgressString = (history?.timestamp).flatMap({
                                    episode.episode == history?.episode ? "\($0.toMinuteSecondString()) watched" : nil
                                })
                                Text([episode.type.rawValue.capitalized, episodeProgressString].compactMap({ $0 }).joined(separator: " • "))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }.multilineTextAlignment(.leading)
                        }.buttonStyle(.plain)
                    }
                default:
                    EmptyView()
                }
            }
        }.padding(10)
        .task {
            guard let source else { return }
            let mediaType: MediaType = source is TextSource ? .text : source is ImageSource ? .image : .video
            history = try? await SoshikiAPI.shared.getHistory(mediaType: mediaType, id: entry._id).get()
            if let sourceId = entry.platforms.first(where: { $0.id == "soshiki" })?.sources.first(where: { $0.id == source.id })?.entryId {
                sourceEntry = await source.getEntry(id: sourceId)
                switch source {
                case _ as TextSource:
                    break
                case let source as ImageSource:
                    chapters = await source.getChapters(id: sourceId)
                case let source as VideoSource:
                    episodes = await source.getEpisodes(id: sourceId)
                default:
                    break
                }
            }
        }.onChange(of: source) { source in
            Task {
                guard let source else { return }
                let mediaType: MediaType = source is TextSource ? .text : source is ImageSource ? .image : .video
                history = try? await SoshikiAPI.shared.getHistory(mediaType: mediaType, id: entry._id).get()
                if let sourceId = entry.platforms.first(where: { $0.id == "soshiki" })?.sources.first(where: { $0.id == source.id })?.entryId {
                    sourceEntry = await source.getEntry(id: sourceId)
                    switch source {
                    case _ as TextSource:
                        break
                    case let source as ImageSource:
                        chapters = await source.getChapters(id: sourceId)
                    case let source as VideoSource:
                        episodes = await source.getEpisodes(id: sourceId)
                    default:
                        break
                    }
                }
            }
        }
    }
}
