//
//  VideoPlayerView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/2/23.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @Environment(\.presentationMode) var presentationMode

    @StateObject var videoPlayerViewModel: VideoPlayerViewModel

    init(episodes: [VideoSourceEpisode], episode: Int, source: VideoSource, linkedEntry: EntryConnection?, history: HistoryEntry?) {
        self._videoPlayerViewModel = StateObject(
            wrappedValue: VideoPlayerViewModel(episodes: episodes, episode: episode, source: source, linkedEntry: linkedEntry, history: history)
        )
    }

    var body: some View {
        NavigationStack {
            VStack {
                VideoPlayerRepresentableView(videoPlayerViewModel: videoPlayerViewModel)
                if videoPlayerViewModel.details == nil {
                    ProgressView()
                }
                Spacer()
            }
        }.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Task {
                        await videoPlayerViewModel.viewController.setEpisode(to: videoPlayerViewModel.episode + 1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }.disabled(videoPlayerViewModel.episode == videoPlayerViewModel.episodes.count - 1)
            }
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Episode \(videoPlayerViewModel.episodes[videoPlayerViewModel.episode].episode.toTruncatedString())")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await videoPlayerViewModel.viewController.setEpisode(to: videoPlayerViewModel.episode - 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }.disabled(videoPlayerViewModel.episode == 0)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    videoPlayerViewModel.settingsViewShown.toggle()
                } label: {
                    Image(systemName: "gear")
                }.sheet(isPresented: $videoPlayerViewModel.settingsViewShown) {
                    NavigationView {
                        VideoPlayerSettingsView(videoPlayerViewModel: videoPlayerViewModel).toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button {
                                    videoPlayerViewModel.settingsViewShown = false
                                } label: {
                                    Text("Done").bold()
                                }
                            }
                        }.navigationTitle("Settings")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            videoPlayerViewModel.startup()
        }
    }
}

@MainActor class VideoPlayerViewModel: ObservableObject {
    var episodes: [VideoSourceEpisode]
    var source: VideoSource

    @Published var episode: Int

    @Published var details: VideoSourceEpisodeDetails?

    @Published var currentlyPlayingUrl: URL?

    @Published var settingsViewShown = false

    var history: HistoryEntry?
    var linkedEntry: EntryConnection?

    @AppStorage("settings.video.autoPlay") var autoPlay = true
    @AppStorage("settings.video.autoNextEpisode") var autoNextEpisode = true
    @AppStorage("settings.video.persistTimestamp") var persistTimestamp = false

    var viewController = VideoPlayerViewController()

    init(episodes: [VideoSourceEpisode], episode: Int, source: VideoSource, linkedEntry: EntryConnection?, history: HistoryEntry?) {
        self.episodes = episodes
        self.episode = episode
        self.source = source
        self.linkedEntry = linkedEntry
        self.history = history
    }

    func startup() {
        Task {
            let episode = episodes[episode]
            details = await source.getEpisodeDetails(id: episode.id, entryId: episode.entryId)
            if let url = details?.providers[safe: 0]?.urls[safe: 0].flatMap({ URL(string: $0.url) }) {
                await viewController.setUrl(url)
            }
        }
    }
}
