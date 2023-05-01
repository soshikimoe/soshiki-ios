//
//  VideoPlayerViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/27/23.
//

import UIKit
import AVKit

class VideoPlayerViewController_Old: AVPlayerViewController {
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
    var hideToolbarWhenPlaying = UserDefaults.standard.object(forKey: "settings.video.hideToolbarWhenPlaying") as? Bool ?? true
    var showSkipButton = UserDefaults.standard.object(forKey: "settings.video.showSkipButton") as? Bool ?? true

    var timeObserver: Any?
    var rateObserver: NSKeyValueObservation?
    var skipTimeObserver: Any?

    var lastRegisteredTimestamp: Double = 0

    var details: VideoSourceEpisodeDetails?
    var previousDetails: VideoSourceEpisodeDetails?
    var nextDetails: VideoSourceEpisodeDetails?

    var skipTimes: [Entry.SkipTimeItem]? {
        entry?.skipTimes?.filter({
            $0.episode == self.episodes[self.episode].episode
        }).min(by: {
            $0.times.count > $1.times.count
        })?.times.filter({
            $0.type.shouldSkip()
        })
    }
    let skipButton = UIButton(type: .roundedRect)
    var skipButtonWidthConstraint: NSLayoutConstraint?
    var currentSkipItem: Entry.SkipTimeItem?

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

        self.entersFullScreenWhenPlaybackBegins = true
        self.exitsFullScreenWhenPlaybackEnds = true

        self.delegate = self

        if showSkipButton, let contentOverlayView {
            skipButton.addTarget(self, action: #selector(skipButtonPressed), for: .touchUpInside)
            skipButton.setImage(UIImage(systemName: "forward.fill"), for: .normal)
            var configuration = UIButton.Configuration.plain()
            configuration.imagePadding = 8
            skipButton.configuration = configuration
            skipButton.tintColor = .black
            skipButton.backgroundColor = UIColor(white: 0.6, alpha: 0.8)
            skipButton.layer.cornerRadius = 5
            skipButton.clipsToBounds = true
            skipButton.alpha = 0
            skipButton.isHidden = true
            skipButton.translatesAutoresizingMaskIntoConstraints = false
            contentOverlayView.addSubview(skipButton)
            skipButton.bottomAnchor.constraint(equalTo: contentOverlayView.layoutMarginsGuide.bottomAnchor).isActive = true
            skipButton.trailingAnchor.constraint(equalTo: contentOverlayView.layoutMarginsGuide.trailingAnchor).isActive = true
            skipButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            skipButtonWidthConstraint = skipButton.widthAnchor.constraint(equalToConstant: skipButton.intrinsicContentSize.width + 15 * 2)
            skipButtonWidthConstraint?.isActive = true
        }

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
            NotificationCenter.default.addObserver(
                forName: .init("settings.video.hideToolbarWhenPlaying"),
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.hideToolbarWhenPlaying = UserDefaults.standard.object(forKey: "settings.video.hideToolbarWhenPlaying") as? Bool ?? true
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.video.showSkipButton"), object: nil, queue: nil) { [weak self] _ in
                self?.showSkipButton = UserDefaults.standard.object(forKey: "settings.video.showSkipButton") as? Bool ?? true
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
        let currentTimestamp = self.player?.currentTime()
        let currentUrl = self.currentlyPlayingUrl
        self.currentlyPlayingUrl = url
        let request = await self.source.modifyVideoRequest(request: URLRequest(url: url))
        let playerItem = AVPlayerItem(asset: AVURLAsset(
            url: request?.url ?? url,
            options: ["AVURLAssetHTTPHeaderFieldsKey": request?.allHTTPHeaderFields ?? [:]]
        ))
        var metadata: [AVMetadataItem] = []
        let titleMetadata = AVMutableMetadataItem()
        titleMetadata.identifier = .commonIdentifierTitle
        titleMetadata.value = self.episodes[self.episode].toListString() as any NSCopying & NSObjectProtocol
        if let copy = titleMetadata.copy() as? AVMetadataItem {
            metadata.append(copy)
        }
        if let entry {
            let subtitleMetadata = AVMutableMetadataItem()
            subtitleMetadata.identifier = .iTunesMetadataTrackSubTitle
            subtitleMetadata.value = entry.title as any NSCopying & NSObjectProtocol
            if let copy = subtitleMetadata.copy() as? AVMetadataItem {
                metadata.append(copy)
            }
        }
        playerItem.externalMetadata = metadata
        let player = AVPlayer(playerItem: playerItem)

        if let timeObserver {
            self.player?.removeTimeObserver(timeObserver)
        }
        rateObserver?.invalidate()
        self.player?.pause()
        self.player?.currentItem?.asset.cancelLoading()

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
        self.rateObserver = player.observe(\.rate) { [weak self] player, _ in
            guard let self else { return }
            Task { @MainActor in
                if player.rate == 0, self.navigationController?.isNavigationBarHidden == true {
                    self.navigationController?.setNavigationBarHidden(false, animated: false)
                    UIView.animate(withDuration: CATransaction.animationDuration()) {
                        self.navigationController?.navigationBar.alpha = 1
                    }
                } else if self.hideToolbarWhenPlaying,
                          self.navigationController?.topViewController == self,
                          player.rate > 0,
                          self.navigationController?.isNavigationBarHidden == false {
                    UIView.animate(withDuration: CATransaction.animationDuration()) {
                        self.navigationController?.navigationBar.alpha = 0
                    } completion: { _ in
                        self.navigationController?.setNavigationBarHidden(true, animated: false)
                    }
                }
            }
        }
        if let skipTimeObserver {
            self.player?.removeTimeObserver(skipTimeObserver)
        }
        if showSkipButton, let skipTimes, !skipTimes.isEmpty {
            self.skipTimeObserver = player.addBoundaryTimeObserver(forTimes: skipTimes.flatMap({ time in
                [NSValue(time: CMTime(seconds: time.start, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))]
                + (time.end.flatMap({ [NSValue(time: CMTime(seconds: $0 - 5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))] }) ?? [])
            }), queue: .global(qos: .utility)) { [weak self] in
                guard let self, let time = self.player?.currentTime().seconds else { return }
                if let assumedTime = skipTimes.first(where: { $0.start.equals(time, withTolerance: 1) }) {
                    self.currentSkipItem = assumedTime
                    Task { @MainActor in
                        self.setButtonTitle(to: "Skip \(assumedTime.type.rawValue)")
                        self.setButtonVisibility(true)
                    }
                } else if let assumedTime = skipTimes.first(where: { $0.end?.equals(time + 5, withTolerance: 1) == true }),
                          self.currentSkipItem?.type == assumedTime.type {
                    self.currentSkipItem = nil
                    Task { @MainActor in
                        self.setButtonVisibility(false)
                    }
                }
            }
        }
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

    @objc func skipButtonPressed() {
        if let endTime = currentSkipItem?.end ?? player?.currentItem?.duration.seconds {
            Task {
                await self.player?.seek(to: CMTime(seconds: endTime - 2, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                Task { @MainActor in
                    self.setButtonVisibility(false)
                }
            }
        }
    }

    func setButtonTitle(to title: String) {
        skipButton.setAttributedTitle(NSAttributedString(
            string: title,
            attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .bold)]
        ), for: .normal)
        skipButtonWidthConstraint?.isActive = false
        skipButtonWidthConstraint = skipButton.widthAnchor.constraint(equalToConstant: skipButton.intrinsicContentSize.width + 25)
    }

    func setButtonVisibility(_ visible: Bool) {
        guard self.skipButton.isHidden == visible else { return }
        if visible {
            self.skipButton.isHidden = false
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                self.skipButton.alpha = 1
            }
        } else {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                self.skipButton.alpha = 0
            } completion: { _ in
                self.skipButton.isHidden = true
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

extension VideoPlayerViewController_Old {
    @objc func closeViewer() {
        self.player?.pause()
        self.player?.currentItem?.asset.cancelLoading()
        self.player?.replaceCurrentItem(with: nil)
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
        self.navigationController?.pushViewController(
            VideoPlayerSettingsViewController_Old(providers: details?.providers ?? [], currentlyPlayingUrl: currentlyPlayingUrl),
            animated: true
        )
    }
}

extension VideoPlayerViewController_Old {
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

extension VideoPlayerViewController_Old: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

extension VideoPlayerViewController_Old: AVPlayerViewControllerDelegate {
    func playerViewController(_ playerViewController: AVPlayerViewController,
                              willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        self.navigationController?.navigationBar.isHidden = true
    }

    func playerViewController(_ playerViewController: AVPlayerViewController,
                              willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        self.navigationController?.navigationBar.isHidden = false
    }
}
