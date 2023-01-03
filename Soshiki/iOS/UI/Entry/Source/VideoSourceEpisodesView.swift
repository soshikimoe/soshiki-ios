//
//  VideoSourceEpisodesView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/2/23.
//

import SwiftUI

struct VideoSourceEpisodesView: View {
    var sources: [VideoSource]

    var entry: Entry

    @State var episodes: [VideoSourceEpisode] = []

    @State var descriptionExpanded = false

    @State var selectedSource: VideoSource?

    @State var sourceEntry: SourceEntry?

    var accentColor: Color?

    @EnvironmentObject var contentViewModel: ContentViewModel

    @State var history: HistoryEntry?

    init(entry: Entry, sources: [VideoSource]) {
        self.sources = sources
        self.selectedSource = sources[safe: 0]
        self.entry = entry
        self.accentColor = Color(hex: entry.info?.anilist?.coverImage?.color ?? "")
    }

    var body: some View {
        Group {
            HStack(spacing: 10) {
                NavigationLink {
                    if !episodes.isEmpty, let source = selectedSource {
                        VideoPlayerView(
                            episodes: episodes,
                            episode: history?.episode.flatMap({ episode in
                                episodes.firstIndex(where: { $0.episode == episode })
                            }) ?? episodes.count - 1,
                            source: source,
                            linkedEntry: EntryConnection(id: entry.id, entry: entry),
                            history: history
                        )
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                        Label(history?.episode != nil ? "Continue Watching" : "Watch Now", systemImage: "play.fill")
                            .fontWeight(.semibold)
                            .foregroundColor(accentColor?.contrastingFontColor() ?? .white)
                    }
                }.disabled(episodes.isEmpty)
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
                Text("\(episodes.count) episodes").bold()
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
                ForEach(episodes.enumerated().map({ $0 }), id: \.element.id) { offset, episode in
                    Divider()
                    NavigationLink {
                        if let source = selectedSource {
                            VideoPlayerView(
                                episodes: episodes,
                                episode: offset,
                                source: source,
                                linkedEntry: EntryConnection(id: entry.id, entry: entry),
                                history: history
                            )
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            let episodeNameString = episode.name != nil && !episode.name!.isEmpty ? ": \(episode.name!)" : ""
                            Text("Episode \(episode.episode.toTruncatedString())\(episodeNameString)")
                                .font(.headline)
                                .foregroundColor((history?.episode ?? -1) > episode.episode ? .secondary : .primary)
                            let episodeTimeString = history?.timestamp.flatMap({
                                history?.episode == episode.episode ? " • \($0.toMinuteSecondString()) watched" : ""
                            }) ?? ""
                            Text(episode.type.rawValue.capitalized + episodeTimeString)
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
                self.episodes = await source.getEpisodes(id: id)
            }
            if let entryId = entry.id {
                history = await GraphQL.query(
                    QueryHistoryEntry(mediaType: .video, id: entryId),
                    returning: [
                        .timestamp,
                        .episode
                    ],
                    token: SoshikiAPI.shared.token
                )
            }
        }.onChange(of: selectedSource) { newValue in
            self.sourceEntry = nil
            self.episodes = []
            Task {
                if let source = newValue,
                   let id = entry.platforms?.first(where: { $0.name == "Soshiki" })?.sources?.first(where: { $0.name == source.id })?.id {
                    self.sourceEntry = await source.getEntry(id: id)
                    self.episodes = await source.getEpisodes(id: id)
                }
            }
        }
    }
}
