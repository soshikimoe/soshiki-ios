//
//  VideoBrowseEntryView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/1/23.
//

import Foundation
import NukeUI
import SwiftUI

struct VideoBrowseEntryView: View {
    var shortEntry: SourceShortEntry
    var source: VideoSource

    @State var entry: SourceEntry?
    @State var episodes: [VideoSourceEpisode] = []

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
                        if !episodes.isEmpty {
                            VideoPlayerView(
                                episodes: episodes,
                                episode: history?.episode.flatMap({ episode in
                                    episodes.firstIndex(where: { $0.episode == episode })
                                }) ?? episodes.count - 1,
                                source: source,
                                linkedEntry: linkedEntry,
                                history: history
                            )
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                            Label(history?.episode != nil ? "Continue Watching" : "Watch Now", systemImage: "play.fill")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }.disabled(episodes.isEmpty)
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
                Text("\(episodes.count) episodes").bold()
                ForEach(episodes.enumerated().map({ $0 }), id: \.element.id) { offset, episode in
                    Divider()
                    NavigationLink {
                        VideoPlayerView(episodes: episodes, episode: offset, source: source, linkedEntry: linkedEntry, history: history)
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
            let entry = await source.getEntry(id: shortEntry.id)
            let episodes = await source.getEpisodes(id: shortEntry.id)
            Task { @MainActor in
                self.entry = entry
                self.episodes = episodes
            }
            linkedEntry = await GraphQL.query(
                QueryLink(mediaType: .video, platform: "Soshiki", source: source.id, sourceId: shortEntry.id),
                returning: [
                    .id,
                    .entry(SoshikiAPI.baseEntriesQuery)
                ],
                token: SoshikiAPI.shared.token
            )
            if let entryId = linkedEntry?.id {
                history = await GraphQL.query(
                    QueryHistoryEntry(mediaType: .video, id: entryId),
                    returning: [
                        .timestamp,
                        .episode
                    ],
                    token: SoshikiAPI.shared.token
                )
            }
        }
    }
}
