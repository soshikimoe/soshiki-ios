//
//  VideoPlayerRepresentableView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/2/23.
//

import SwiftUI
import AVKit
import UIKit

struct VideoPlayerRepresentableView: UIViewControllerRepresentable {
    @ObservedObject var videoPlayerViewModel: VideoPlayerViewModel

    func makeUIViewController(context: Context) -> VideoPlayerViewController {
        videoPlayerViewModel.viewController.coordinator = context.coordinator
        return videoPlayerViewModel.viewController
    }

    func updateUIViewController(_ uiViewController: VideoPlayerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor class Coordinator {
        var parent: VideoPlayerRepresentableView

        init(_ parent: VideoPlayerRepresentableView) {
            self.parent = parent
        }

        var details: VideoSourceEpisodeDetails? {
            get {
                parent.videoPlayerViewModel.details
            } set {
                parent.videoPlayerViewModel.details = newValue
            }
        }

        var episodes: [VideoSourceEpisode] {
            parent.videoPlayerViewModel.episodes
        }

        var episode: Int {
            get {
                parent.videoPlayerViewModel.episode
            } set {
                parent.videoPlayerViewModel.episode = newValue
            }
        }

        var source: VideoSource {
            parent.videoPlayerViewModel.source
        }

        var entry: Entry? {
            parent.videoPlayerViewModel.entry
        }

        var history: History? {
            get { parent.videoPlayerViewModel.history }
            set { parent.videoPlayerViewModel.history = newValue }
        }
    }
}

class VideoPlayerViewController: AVPlayerViewController {
    var coordinator: VideoPlayerRepresentableView.Coordinator!

    var endObserver: NSObjectProtocol?
    var timeObserver: Any?

    var lastRegisteredTimestamp: Double = 0

    var previousDetails: VideoSourceEpisodeDetails?
    var nextDetails: VideoSourceEpisodeDetails?

    init() {
        super.init(nibName: nil, bundle: nil)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        if let timeObserver {
            self.player?.removeTimeObserver(timeObserver)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let url = coordinator.parent.videoPlayerViewModel.currentlyPlayingUrl {
            Task {
                await self.setUrl(url)
            }
        }
        if coordinator.episode > 0 {
            Task {
                let episode = coordinator.episodes[coordinator.episode - 1]
                nextDetails = await coordinator.source.getEpisodeDetails(id: episode.id, entryId: episode.entryId)
            }
        }
        if coordinator.episode < coordinator.episodes.count - 1 {
            Task {
                let episode = coordinator.episodes[coordinator.episode + 1]
                previousDetails = await coordinator.source.getEpisodeDetails(id: episode.id, entryId: episode.entryId)
            }
        }
        if coordinator.parent.videoPlayerViewModel.autoPlay {
            self.player?.play()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player?.pause()
    }

    func setUrl(_ url: URL) async {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }

        let currentTimestamp = self.player?.currentTime()
        let currentUrl = coordinator.parent.videoPlayerViewModel.currentlyPlayingUrl
        coordinator.parent.videoPlayerViewModel.currentlyPlayingUrl = url
        let request = await coordinator.source.modifyVideoRequest(request: URLRequest(url: url))
        let player = AVPlayer(playerItem: AVPlayerItem(asset: AVURLAsset(
            url: request?.url ?? url,
            options: ["AVURLAssetHTTPHeaderFieldsKey": request?.allHTTPHeaderFields ?? [:]]
        )))

        if let timeObserver {
            self.player?.removeTimeObserver(timeObserver)
        }
        self.timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 15, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .global(qos: .utility)
        ) { [weak self] time in
            guard let self else { return }
            let timestamp = round(Double(time.value) / Double(time.timescale))
            if let entry = self.coordinator.parent.videoPlayerViewModel.entry,
               self.lastRegisteredTimestamp != timestamp {
                self.lastRegisteredTimestamp = timestamp
                Task {
                    await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [
                        .timestamp(Int(timestamp)),
                        .episode(self.coordinator.episodes[self.coordinator.episode].episode)
                    ])
                    if let history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get() {
                        self.coordinator.history = history
                        await TrackerManager.shared.setHistory(entry: entry, history: history)
                    }
                }
            }
        }
        self.player?.pause()
        self.player = player
        if coordinator.parent.videoPlayerViewModel.autoPlay {
            self.player?.play()
        }
        if let currentTimestamp,
           let currentUrl,
           coordinator.details?.providers.contains(where: { $0.urls.contains(where: { $0.url == currentUrl.absoluteString }) }) == true,
           coordinator.parent.videoPlayerViewModel.persistTimestamp {
            await self.player?.seek(to: currentTimestamp)
        } else if let historyTimestamp = coordinator.parent.videoPlayerViewModel.history?.timestamp,
                  coordinator.parent.videoPlayerViewModel.history?.episode == coordinator.episodes[coordinator.episode].episode {
            await self.player?.seek(to: CMTime(seconds: Double(historyTimestamp), preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoFinished),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
    }

    @objc func videoFinished() {
        if coordinator.parent.videoPlayerViewModel.autoNextEpisode, coordinator.episode > 0 {
            Task {
                await setEpisode(to: coordinator.episode - 1)
            }
        }
    }

    func setEpisode(to episode: Int) async {
        guard episode >= 0, episode < coordinator.episodes.count else { return }
        if let nextDetails, nextDetails.id == coordinator.episodes[episode].id { // go to next episode
            previousDetails = coordinator.details
            coordinator.details = nextDetails
            if episode > 0 {
                Task {
                    let episode = coordinator.episodes[episode - 1]
                    self.nextDetails = await coordinator.source.getEpisodeDetails(id: episode.id, entryId: episode.entryId)
                }
            }
        } else if let previousDetails, previousDetails.id == coordinator.episodes[episode].id { // switch to previous episode
            nextDetails = coordinator.details
            coordinator.details = previousDetails
            if episode < coordinator.episodes.count - 1 {
                Task {
                    let episode = coordinator.episodes[episode + 1]
                    self.previousDetails = await coordinator.source.getEpisodeDetails(id: episode.id, entryId: episode.entryId)
                }
            }
        } else { // switch to arbitrary episode (idk how you would even do this but whatever)
            let newEpisode = coordinator.episodes[episode]
            coordinator.details = await coordinator.source.getEpisodeDetails(id: newEpisode.id, entryId: newEpisode.entryId)
            if episode > 0 {
                Task {
                    let episode = coordinator.episodes[episode - 1]
                    self.nextDetails = await coordinator.source.getEpisodeDetails(id: episode.id, entryId: episode.entryId)
                }
            }
            if episode < coordinator.episodes.count - 1 {
                Task {
                    let episode = coordinator.episodes[episode + 1]
                    self.previousDetails = await coordinator.source.getEpisodeDetails(id: episode.id, entryId: episode.entryId)
                }
            }
        }
        coordinator.episode = episode
        if let url = coordinator.details?.providers[safe: 0]?.urls[safe: 0].flatMap({ URL(string: $0.url) }) {
            await self.setUrl(url)
        }
    }
}
