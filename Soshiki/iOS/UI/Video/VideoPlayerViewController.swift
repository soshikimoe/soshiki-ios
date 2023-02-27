//
//  VideoPlayerViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/27/23.
//

import UIKit
import AVKit

class VideoPlayerViewController: AVPlayerViewController {
    var observers: [NSObjectProtocol] = []

    var episodes: [VideoSourceEpisode]
    var source: any VideoSource
    var history: History?
    var entry: Entry?

    var episode: Int {
        didSet {
            self.title = "Episode \(episodes[episode].episode.toTruncatedString())"
        }
    }

    var currentlyPlayingUrl: URL?

    var autoPlay = UserDefaults.standard.object(forKey: "settings.video.autoPlay") as? Bool ?? true
    var autoNextEpisode = UserDefaults.standard.object(forKey: "settings.video.autoNextEpisode") as? Bool ?? true
    var persistTimestamp = UserDefaults.standard.object(forKey: "settings.video.persistTimestamp") as? Bool ?? false

    var endObserver: NSObjectProtocol?
    var timeObserver: Any?

    var lastRegisteredTimestamp: Double = 0

    var details: VideoSourceEpisodeDetails?
    var previousDetails: VideoSourceEpisodeDetails?
    var nextDetails: VideoSourceEpisodeDetails?

    lazy var singleTapGestureRecognizer: UITapGestureRecognizer = {
        let single = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        single.numberOfTapsRequired = 1
        single.delegate = self
        return single
    }()

    init(episodes: [VideoSourceEpisode], episode: Int, source: any VideoSource, entry: Entry?, history: History?) {
        self.episodes = episodes
        self.episode = episode
        self.source = source
        self.entry = entry
        self.history = history
        super.init(nibName: nil, bundle: nil)

        self.allowsPictureInPicturePlayback = true

        self.view.backgroundColor = .systemBackground
        self.hidesBottomBarWhenPushed = true
        self.navigationItem.hidesBackButton = true
        self.navigationItem.largeTitleDisplayMode = .never

        // self.view.addGestureRecognizer(singleTapGestureRecognizer)

        let closeViewerButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeViewer)
        )
        let previousEpisodeButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(previousEpisode)
        )
        let nextEpisodeButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(nextEpisode)
        )
        let openSettingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings)
        )

        self.navigationItem.leftBarButtonItems = [ closeViewerButton, previousEpisodeButton ]
        self.navigationItem.rightBarButtonItems = [ openSettingsButton, nextEpisodeButton ]

        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.video.autoPlay"), object: nil, queue: nil) { [weak self] _ in
                self?.autoPlay = UserDefaults.standard.object(forKey: "settings.video.autoPlay") as? Bool ?? true
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.video.autoNextEpisode"), object: nil, queue: nil) { [weak self] _ in
                self?.autoNextEpisode = UserDefaults.standard.object(forKey: "settings.video.autoNextEpisode") as? Bool ?? true
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.video.persistTimestamp"), object: nil, queue: nil) { [weak self] _ in
                self?.persistTimestamp = UserDefaults.standard.object(forKey: "settings.video.persistTimestamp") as? Bool ?? true
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.video.provider"), object: nil, queue: nil) { [weak self] notification in
                if let url = notification.object as? URL? {
                    self?.currentlyPlayingUrl = url
                    if let url {
                        Task {
                            await self?.setUrl(url)
                        }
                    }
                }
            }
        )

        Task {
            await setEpisode(to: episode)
        }
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
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
            try audioSession.setActive(true)
        } catch {
            print(error)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.compactAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player?.pause()
        let transparentAppearance = UINavigationBarAppearance()
        transparentAppearance.configureWithTransparentBackground()
        let defaultAppearance = UINavigationBarAppearance()
        defaultAppearance.configureWithDefaultBackground()
        self.navigationController?.navigationBar.standardAppearance = defaultAppearance
        self.navigationController?.navigationBar.compactAppearance = defaultAppearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = transparentAppearance
        self.navigationController?.navigationBar.compactScrollEdgeAppearance = transparentAppearance
    }

    func setUrl(_ url: URL) async {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }

        let currentTimestamp = self.player?.currentTime()
        let currentUrl = self.currentlyPlayingUrl
        self.currentlyPlayingUrl = url
        let request = await self.source.modifyVideoRequest(request: URLRequest(url: url))
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
            if let entry = self.entry,
               self.lastRegisteredTimestamp != timestamp {
                self.lastRegisteredTimestamp = timestamp
                Task {
                    await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [
                        .timestamp(Int(timestamp)),
                        .episode(self.self.episodes[self.self.episode].episode)
                    ])
                    if let history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get() {
                        self.self.history = history
                        await TrackerManager.shared.setHistory(entry: entry, history: history)
                    }
                }
            }
        }
        self.player?.pause()
        self.player = player
        if self.autoPlay {
            self.player?.play()
        }
        if let currentTimestamp,
           let currentUrl,
           self.details?.providers.contains(where: { $0.urls.contains(where: { $0.url == currentUrl.absoluteString }) }) == true,
           self.persistTimestamp {
            await self.player?.seek(to: currentTimestamp)
        } else if let historyTimestamp = self.history?.timestamp,
                  self.history?.episode == self.episodes[self.episode].episode {
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
        if self.autoNextEpisode, self.episode > 0 {
            Task {
                await setEpisode(to: self.episode - 1)
            }
        }
    }

    func setEpisode(to episode: Int) async {
        guard episode >= 0, episode < self.episodes.count else { return }
        if let nextDetails, nextDetails.id == self.episodes[episode].id { // go to next episode
            previousDetails = self.details
            self.details = nextDetails
            if episode > 0 {
                Task {
                    let episode = self.episodes[episode - 1]
                    self.nextDetails = await self.source.getEpisodeDetails(id: episode.id, entryId: episode.entryId)
                }
            }
        } else if let previousDetails, previousDetails.id == self.episodes[episode].id { // switch to previous episode
            nextDetails = self.details
            self.details = previousDetails
            if episode < self.episodes.count - 1 {
                Task {
                    let episode = self.episodes[episode + 1]
                    self.previousDetails = await self.source.getEpisodeDetails(id: episode.id, entryId: episode.entryId)
                }
            }
        } else { // switch to arbitrary episode (idk how you would even do this but whatever)
            let newEpisode = self.episodes[episode]
            self.details = await self.source.getEpisodeDetails(id: newEpisode.id, entryId: newEpisode.entryId)
            if episode > 0 {
                Task {
                    let episode = self.episodes[episode - 1]
                    self.nextDetails = await self.source.getEpisodeDetails(id: episode.id, entryId: episode.entryId)
                }
            }
            if episode < self.episodes.count - 1 {
                Task {
                    let episode = self.episodes[episode + 1]
                    self.previousDetails = await self.source.getEpisodeDetails(id: episode.id, entryId: episode.entryId)
                }
            }
        }
        self.episode = episode
        if let url = self.details?.providers[safe: 0]?.urls[safe: 0].flatMap({ URL(string: $0.url) }) {
            await self.setUrl(url)
        }
    }
}

extension VideoPlayerViewController {
    @objc func closeViewer() {
        self.navigationController?.popViewController(animated: true)
    }

    @objc func previousEpisode() {
        Task {
            await setEpisode(to: episode + 1)
        }
    }

    @objc func nextEpisode() {
        Task {
            await setEpisode(to: episode - 1)
        }
    }

    @objc func openSettings() {
        present(VideoPlayerSettingsViewController(providers: details?.providers ?? [], currentlyPlayingUrl: currentlyPlayingUrl), animated: true)
    }
}

extension VideoPlayerViewController {
    @objc func singleTap() {
        if self.navigationController?.navigationBar.isHidden == true {
            self.navigationController?.navigationBar.isHidden = false
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                self.navigationController?.navigationBar.alpha = 1
            }
        } else {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                self.navigationController?.navigationBar.alpha = 0
            } completion: { _ in
                self.navigationController?.navigationBar.isHidden = true
            }
        }
    }
}

extension VideoPlayerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
