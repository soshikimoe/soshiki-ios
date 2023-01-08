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
    @Environment(\.presentationMode) var presentationMode

    var shortEntry: SourceShortEntry
    var source: VideoSource

    @State var entry: SourceEntry?
    @State var episodes: [VideoSourceEpisode] = []

    @State var descriptionExpanded = false

    @State var linkedEntry: Entry?
    @State var history: History?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                EntryHeaderView(entry: entry?.toUnifiedEntry() ?? shortEntry.toUnifiedEntry())
                HStack(spacing: 10) {
                    NavigationLink {
                        if !episodes.isEmpty {
                            VideoPlayerView(
                                episodes: episodes,
                                episode: history?.episode.flatMap({ episode in
                                    episodes.firstIndex(where: { $0.episode == episode })
                                }) ?? episodes.count - 1,
                                source: source,
                                entry: nil,
                                history: nil
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
                Text("\(episodes.count) episodes").bold()
                ForEach(episodes.enumerated().map({ $0 }), id: \.element.id) { offset, episode in
                    Divider()
                    NavigationLink {
                        VideoPlayerView(episodes: episodes, episode: offset, source: source, entry: nil, history: nil)
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
            let episodes = await source.getEpisodes(id: shortEntry.id)
            Task { @MainActor in
                self.entry = entry
                self.episodes = episodes
            }
            linkedEntry = (try? await SoshikiAPI.shared.getLink(
                mediaType: .video,
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
