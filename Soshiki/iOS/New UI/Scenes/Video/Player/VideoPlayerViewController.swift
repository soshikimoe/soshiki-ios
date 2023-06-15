//
//  VideoPlayerViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/11/23.
//

import UIKit
import AVKit
import MediaPlayer
import GoogleCast

class VideoPlayerViewController: BaseViewController {
    let playerLayer: AVPlayerLayer
    let controlsView: UIView
    let controlsGradientLayer: CAGradientLayer
    let castLabel: UILabel

    let settingsViewController: VideoPlayerSettingsViewController

    // MARK: Top Row Buttons
    let topButtonStackView: UIStackView

    let closeButton: UIButton
    let topButtonSpacerView: UIView
    let pictureInPictureButton: UIButton
    let airplayButton: UIButton
    let _airplayButton: AVRoutePickerView
    let castButton: GCKUICastButton
    let settingsButton: UIButton

    // MARK: Center Row Buttons
    let centerButtonStackView: UIStackView

    let previousEpisodeButton: UIButton
    let skipBackwardButton: UIButton
    let playPauseButton: UIButton
    let skipForwardButton: UIButton
    let nextEpisodeButton: UIButton

    // MARK: Bottom Row Items
    let bottomStackView: UIStackView

    let bottomButtonTitleStackView: UIStackView
    let bottomButtonTitleSpacerView: UIView

    let titleStackView: UIStackView
    let titleLabel: UILabel
    let subtitleLabel: UILabel

    let bottomButtonStackView: UIStackView
    let captionsButton: UIButton
    let rateButton: CallbackMenuButton
    let providerButton: CallbackMenuButton

    let seekSliderBackgroundView: UIView
    let seekSliderForegroundView: UIView

    let timeStackView: UIStackView
    let leftTimeLabel: UILabel
    let timeSpacerView: UIView
    let rightTimeLabel: UILabel

    // MARK: Brightness and Volume Sliders
    let brightnessStackView: UIStackView
    let brightnessSliderBackgroundView: UIView
    let brightnessSliderForegroundView: UIView
    let brightnessImageView: UIImageView

    let volumeStackView: UIStackView
    let volumeSliderBackgroundView: UIView
    let volumeSliderForegroundView: UIView
    let volumeImageView: UIImageView

    // MARK: Gesture Recognizers
    let tapGestureRecognizer: UITapGestureRecognizer
    let panGestureRecognizer: UIPanGestureRecognizer

    var seekSliderForegroundViewWidthConstraint: NSLayoutConstraint!
    var brightnessSliderForegroundViewHeightConstraint: NSLayoutConstraint!
    var volumeSliderForegroundViewHeightConstraint: NSLayoutConstraint!

    var initialBarSize: CGFloat
    var panType: PanType?

    // MARK: Miscellaneous
    var castSession: GCKCastSession?
    var castUpdateTimer: Timer?
    var castingBegan: Bool = false

    var controlsHideTask: Task<Void, Never>?

    var playbackRate: Double = 1

    var timeObservers: [Any]
    var keyValueObservers: [NSKeyValueObservation]

    var isPaused: Bool = true

    var volume: Double {
        get {
            Double(self.playerLayer.player?.volume ?? 0)
        } set {
            self.playerLayer.player?.volume = Float(newValue)
        }
    }

    var brightness: Double {
        get {
            Double(self.view.window?.screen.brightness ?? 0)
        } set {
            self.view.window?.screen.brightness = CGFloat(newValue.clamped(to: 0...1))
        }
    }

    let pictureInPictureController: AVPictureInPictureController?

    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: Entry
    var source: any VideoSource
    var episodes: [VideoSourceEpisode]
    var episodeIndex: Int

    var previousEpisode: VideoSourceEpisode? {
        self.episodes[safe: episodeIndex + 1]
    }
    var currentEpisode: VideoSourceEpisode? {
        self.episodes[safe: episodeIndex]
    }
    var nextEpisode: VideoSourceEpisode? {
        self.episodes[safe: episodeIndex - 1]
    }

    var previousDetails: VideoSourceEpisodeDetails?
    var currentDetails: VideoSourceEpisodeDetails?
    var nextDetails: VideoSourceEpisodeDetails?

    var entry: Entry?
    var history: History?

    var currentUrl: URL?

    let skipButton: UIButton
    let chapterLabel: UILabel

    var currentSkipItem: Entry.SkipTimeItem?
    var skipTimes: [Entry.SkipTimeItem] { // Get the skip times for the current episode
        self.entry?.skipTimes?.filter({
            $0.episode == self.currentEpisode?.episode // Find the ones that are for this episode
        }).max(by: {
            $0.times.count < $1.times.count // Find the one for this episode that has the most times
        })?.times ?? []
    }

    var hasCrossedEndThreshold: Bool

    // MARK: Settings
    var autoPlay = UserDefaults.standard.object(forKey: "settings.video.autoPlay") as? Bool ?? true
    var autoNextEpisode = UserDefaults.standard.object(forKey: "settings.video.autoNextEpisode") as? Bool ?? true
    var persistTimestamp = UserDefaults.standard.object(forKey: "settings.video.persistTimestamp") as? Bool ?? true
    var showSkipButton = UserDefaults.standard.object(forKey: "settings.video.showSkipButton") as? Bool ?? true
    var simplePlayer = UserDefaults.standard.object(forKey: "settings.video.simplePlayer") as? Bool ?? false
    var endThreshold = UserDefaults.standard.object(forKey: "settings.video.endThreshold") as? Int ?? 30

    init(source: any VideoSource, episodes: [VideoSourceEpisode], episodeIndex: Int, entry: Entry? = nil, history: History? = nil) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)

        self.playerLayer = AVPlayerLayer()
        self.controlsView = UIView()
        self.controlsGradientLayer = CAGradientLayer()
        self.castLabel = UILabel()

        self.settingsViewController = VideoPlayerSettingsViewController()

        self.topButtonStackView = UIStackView()
        self.closeButton = UIButton(type: .roundedRect)
        self.topButtonSpacerView = UIView()
        self.pictureInPictureButton = UIButton(type: .roundedRect)
        self.airplayButton = UIButton(type: .roundedRect)
        self._airplayButton = AVRoutePickerView()
        self.castButton = GCKUICastButton(type: .roundedRect)
        self.settingsButton = UIButton(type: .roundedRect)

        self.centerButtonStackView = UIStackView()
        self.previousEpisodeButton = UIButton(type: .roundedRect)
        self.skipBackwardButton = UIButton(type: .roundedRect)
        self.playPauseButton = UIButton(type: .roundedRect)
        self.skipForwardButton = UIButton(type: .roundedRect)
        self.nextEpisodeButton = UIButton(type: .roundedRect)

        self.bottomStackView = UIStackView()
        self.bottomButtonTitleStackView = UIStackView()
        self.bottomButtonTitleSpacerView = UIView()
        self.titleStackView = UIStackView()
        self.titleLabel = UILabel()
        self.subtitleLabel = UILabel()
        self.bottomButtonStackView = UIStackView()
        self.captionsButton = UIButton(type: .roundedRect)
        self.rateButton = CallbackMenuButton(type: .roundedRect)
        self.providerButton = CallbackMenuButton(type: .roundedRect)
        self.seekSliderBackgroundView = UIView()
        self.seekSliderForegroundView = UIView()
        self.timeStackView = UIStackView()
        self.leftTimeLabel = UILabel()
        self.timeSpacerView = UIView()
        self.rightTimeLabel = UILabel()

        self.brightnessStackView = UIStackView()
        self.brightnessSliderBackgroundView = UIView()
        self.brightnessSliderForegroundView = UIView()
        self.brightnessImageView = UIImageView()

        self.volumeStackView = UIStackView()
        self.volumeSliderBackgroundView = UIView()
        self.volumeSliderForegroundView = UIView()
        self.volumeImageView = UIImageView()

        self.tapGestureRecognizer = UITapGestureRecognizer()
        self.panGestureRecognizer = UIPanGestureRecognizer()

        self.initialBarSize = 0

        self.timeObservers = []
        self.keyValueObservers = []

        if AVPictureInPictureController.isPictureInPictureSupported() {
            self.pictureInPictureController = AVPictureInPictureController(playerLayer: self.playerLayer)
        } else {
            self.pictureInPictureController = nil
        }

        self.source = source
        self.episodes = episodes
        self.episodeIndex = episodeIndex

        self.entry = entry
        self.history = history

        self.skipButton = UIButton(type: .roundedRect)
        self.chapterLabel = UILabel()

        self.hasCrossedEndThreshold = false

        super.init()

        resetControlsHideTimer()

        self.hidesBottomBarWhenPushed = true

        GCKCastContext.sharedInstance().sessionManager.add(self)

        super.addObserver("settings.video.autoPlay") { [weak self] _ in
            self?.autoPlay = UserDefaults.standard.object(forKey: "settings.video.autoPlay") as? Bool ?? true
        }

        super.addObserver("settings.video.autoNextEpisode") { [weak self] _ in
            self?.autoNextEpisode = UserDefaults.standard.object(forKey: "settings.video.autoNextEpisode") as? Bool ?? true
        }

        super.addObserver("settings.video.persistTimestamp") { [weak self] _ in
            self?.persistTimestamp = UserDefaults.standard.object(forKey: "settings.video.persistTimestamp") as? Bool ?? true
        }

        super.addObserver("settings.video.showSkipButton") { [weak self] _ in
            self?.showSkipButton = UserDefaults.standard.object(forKey: "settings.video.showSkipButton") as? Bool ?? true
        }

        super.addObserver("settings.video.simplePlayer") { [weak self] _ in
            guard let self else { return }
            self.simplePlayer = UserDefaults.standard.object(forKey: "settings.video.simplePlayer") as? Bool ?? false
            self.previousEpisodeButton.isHidden = self.simplePlayer
            self.skipBackwardButton.isHidden = self.simplePlayer
            self.skipForwardButton.isHidden = self.simplePlayer
            self.nextEpisodeButton.isHidden = self.simplePlayer
            self.subtitleLabel.isHidden = self.simplePlayer
            self.brightnessStackView.isHidden = self.simplePlayer
            self.volumeStackView.isHidden = self.simplePlayer
        }

        super.addObserver("settings.video.endThreshold") { [weak self] _ in
            self?.endThreshold = UserDefaults.standard.object(forKey: "settings.video.endThreshold") as? Int ?? 30
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        GCKCastContext.sharedInstance().sessionManager.remove(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession {
            self.sessionManager(GCKCastContext.sharedInstance().sessionManager, didStart: session)
        }

        Task {
            await setEpisode(toIndex: self.episodeIndex)
        }
    }

    override func configureViews() {
        self.view.backgroundColor = .black

        self.playerLayer.frame = self.view.bounds
        self.playerLayer.videoGravity = .resizeAspect
        self.view.layer.addSublayer(self.playerLayer)

        self.controlsGradientLayer.colors = [
            UIColor(white: 0, alpha: 0.6).cgColor,
            UIColor(white: 0, alpha: 0.3).cgColor,
            UIColor(white: 0, alpha: 0.6).cgColor
        ]
        self.controlsGradientLayer.locations = [ 0, 0.5, 1 ]
        self.controlsGradientLayer.frame = self.view.bounds
        self.controlsGradientLayer.needsDisplayOnBoundsChange = true
        self.controlsView.layer.insertSublayer(self.controlsGradientLayer, at: 0)

        self.castLabel.text = "Casting with Google Cast"
        self.castLabel.textColor = .lightGray
        self.castLabel.isHidden = true

        self.castLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.castLabel)

        // MARK: Top Row Buttons

        self.closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        self.closeButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        self.closeButton.tintColor = .white
        self.closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)

        self.pictureInPictureButton.setImage(UIImage(systemName: "rectangle.inset.bottomright.filled"), for: .normal)
        self.pictureInPictureButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        self.pictureInPictureButton.tintColor = .white
        self.pictureInPictureButton.addTarget(self, action: #selector(pictureInPictureButtonPressed(_:)), for: .touchUpInside)

        self.airplayButton.setImage(UIImage(systemName: "airplayvideo"), for: .normal)
        self.airplayButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        self.airplayButton.tintColor = .white
        self.airplayButton.addTarget(self, action: #selector(airplayButtonPressed(_:)), for: .touchUpInside)

        self._airplayButton.isHidden = true
        self.airplayButton.addSubview(self._airplayButton)

        self.castButton.tintColor = .white

        self.settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
        self.settingsButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        self.settingsButton.tintColor = .white
        self.settingsButton.addTarget(self, action: #selector(settingsButtonPressed(_:)), for: .touchUpInside)

        self.topButtonStackView.spacing = 12
        self.topButtonStackView.alignment = .center
        self.topButtonStackView.axis = .horizontal
        self.topButtonStackView.addArrangedSubview(self.closeButton)
        self.topButtonStackView.addArrangedSubview(self.topButtonSpacerView)
        self.topButtonStackView.addArrangedSubview(self.pictureInPictureButton)
        self.topButtonStackView.addArrangedSubview(self.airplayButton)
        self.topButtonStackView.addArrangedSubview(self.castButton)
        self.topButtonStackView.addArrangedSubview(self.settingsButton)

        // MARK: Center Row Buttons

        self.previousEpisodeButton.setImage(UIImage(systemName: "backward.end.fill"), for: .normal)
        self.previousEpisodeButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 25), forImageIn: .normal)
        self.previousEpisodeButton.tintColor = .white
        self.previousEpisodeButton.addTarget(self, action: #selector(previousEpisodeButtonPressed(_:)), for: .touchUpInside)
        self.previousEpisodeButton.isHidden = self.simplePlayer

        self.skipBackwardButton.setImage(UIImage(systemName: "gobackward.10"), for: .normal)
        self.skipBackwardButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 25), forImageIn: .normal)
        self.skipBackwardButton.tintColor = .white
        self.skipBackwardButton.addTarget(self, action: #selector(skipBackwardButtonPressed(_:)), for: .touchUpInside)
        self.skipBackwardButton.isHidden = self.simplePlayer

        self.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        self.playPauseButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 50, weight: .bold), forImageIn: .normal)
        self.playPauseButton.tintColor = .white
        self.playPauseButton.addTarget(self, action: #selector(playPauseButtonPressed(_:)), for: .touchUpInside)

        self.skipForwardButton.setImage(UIImage(systemName: "goforward.10"), for: .normal)
        self.skipForwardButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 25), forImageIn: .normal)
        self.skipForwardButton.tintColor = .white
        self.skipForwardButton.addTarget(self, action: #selector(skipForwardButtonPressed(_:)), for: .touchUpInside)
        self.skipForwardButton.isHidden = self.simplePlayer

        self.nextEpisodeButton.setImage(UIImage(systemName: "forward.end.fill"), for: .normal)
        self.nextEpisodeButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 25), forImageIn: .normal)
        self.nextEpisodeButton.tintColor = .white
        self.nextEpisodeButton.addTarget(self, action: #selector(nextEpisodeButtonPressed(_:)), for: .touchUpInside)
        self.nextEpisodeButton.isHidden = self.simplePlayer

        self.centerButtonStackView.spacing = 24
        self.centerButtonStackView.alignment = .center
        self.centerButtonStackView.axis = .horizontal
        self.centerButtonStackView.addArrangedSubview(self.previousEpisodeButton)
        self.centerButtonStackView.addArrangedSubview(self.skipBackwardButton)
        self.centerButtonStackView.addArrangedSubview(self.playPauseButton)
        self.centerButtonStackView.addArrangedSubview(self.skipForwardButton)
        self.centerButtonStackView.addArrangedSubview(self.nextEpisodeButton)

        // MARK: Bottom Row Items

        self.titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        self.titleLabel.textColor = .white

        self.subtitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        self.subtitleLabel.textColor = .white
        self.subtitleLabel.isHidden = self.simplePlayer

        self.titleStackView.axis = .vertical
        self.titleStackView.alignment = .leading
        self.titleStackView.addArrangedSubview(self.subtitleLabel)
        self.titleStackView.addArrangedSubview(self.titleLabel)

        self.captionsButton.setImage(UIImage(systemName: "captions.bubble"), for: .normal)
        self.captionsButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        self.captionsButton.tintColor = .white
        self.captionsButton.addTarget(self, action: #selector(captionsButtonPressed(_:)), for: .touchUpInside)

        self.rateButton.setImage(UIImage(systemName: "speedometer"), for: .normal)
        self.rateButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        self.rateButton.tintColor = .white
        self.rateButton.showsMenuAsPrimaryAction = true
        self.rateButton.onOpenMenu = { [weak self] in
            self?.controlsHideTask?.cancel()
        }
        self.rateButton.onCloseMenu = { [weak self] in
            self?.resetControlsHideTimer()
        }
        updateRateButtonMenu()

        self.providerButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        self.providerButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        self.providerButton.tintColor = .white
        self.providerButton.showsMenuAsPrimaryAction = true
        self.providerButton.onOpenMenu = { [weak self] in
            self?.controlsHideTask?.cancel()
        }
        self.providerButton.onCloseMenu = { [weak self] in
            self?.resetControlsHideTimer()
        }

        self.bottomButtonStackView.axis = .horizontal
        self.bottomButtonStackView.spacing = 12
        self.bottomButtonStackView.addArrangedSubview(self.captionsButton)
        self.bottomButtonStackView.addArrangedSubview(self.rateButton)
        self.bottomButtonStackView.addArrangedSubview(self.providerButton)

        self.bottomButtonTitleStackView.axis = .horizontal
        self.bottomButtonTitleStackView.alignment = .bottom
        self.bottomButtonTitleStackView.addArrangedSubview(self.titleStackView)
        self.bottomButtonTitleStackView.addArrangedSubview(self.bottomButtonTitleSpacerView)
        self.bottomButtonTitleStackView.addArrangedSubview(self.bottomButtonStackView)

        self.seekSliderBackgroundView.backgroundColor = UIColor(white: 0.75, alpha: 0.8)
        self.seekSliderBackgroundView.layer.cornerRadius = 5
        self.seekSliderBackgroundView.clipsToBounds = true

        self.seekSliderForegroundView.backgroundColor = .white

        self.seekSliderForegroundView.translatesAutoresizingMaskIntoConstraints = false
        self.seekSliderBackgroundView.addSubview(self.seekSliderForegroundView)

        self.leftTimeLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        self.leftTimeLabel.textColor = .white
        self.leftTimeLabel.text = "--:--"

        self.rightTimeLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        self.rightTimeLabel.textColor = .lightGray
        self.rightTimeLabel.text = "--:--"

        self.timeStackView.axis = .horizontal
        self.timeStackView.addArrangedSubview(self.leftTimeLabel)
        self.timeStackView.addArrangedSubview(self.timeSpacerView)
        self.timeStackView.addArrangedSubview(self.rightTimeLabel)

        self.bottomStackView.axis = .vertical
        self.bottomStackView.spacing = 4
        self.bottomStackView.addArrangedSubview(self.bottomButtonTitleStackView)
        self.bottomStackView.addArrangedSubview(self.seekSliderBackgroundView)
        self.bottomStackView.addArrangedSubview(self.timeStackView)

        // MARK: Brightness and Volume

        self.brightnessSliderBackgroundView.backgroundColor = UIColor(white: 0.75, alpha: 0.8)
        self.brightnessSliderBackgroundView.layer.cornerRadius = 3
        self.brightnessSliderBackgroundView.clipsToBounds = true

        self.brightnessSliderForegroundView.backgroundColor = .white

        self.brightnessSliderForegroundView.translatesAutoresizingMaskIntoConstraints = false
        self.brightnessSliderBackgroundView.addSubview(self.brightnessSliderForegroundView)

        self.brightnessImageView.tintColor = .white
        updateBrightnessImage()

        self.brightnessStackView.axis = .vertical
        self.brightnessStackView.spacing = 8
        self.brightnessStackView.alignment = .center
        self.brightnessStackView.addArrangedSubview(self.brightnessSliderBackgroundView)
        self.brightnessStackView.addArrangedSubview(self.brightnessImageView)
        self.brightnessStackView.isHidden = self.simplePlayer

        self.volumeSliderBackgroundView.backgroundColor = UIColor(white: 0.75, alpha: 0.8)
        self.volumeSliderBackgroundView.layer.cornerRadius = 3
        self.volumeSliderBackgroundView.clipsToBounds = true

        self.volumeSliderForegroundView.backgroundColor = .white

        self.volumeSliderForegroundView.translatesAutoresizingMaskIntoConstraints = false
        self.volumeSliderBackgroundView.addSubview(self.volumeSliderForegroundView)

        self.volumeImageView.tintColor = .white
        updateVolumeImage()

        self.volumeStackView.axis = .vertical
        self.volumeStackView.spacing = 8
        self.volumeStackView.alignment = .center
        self.volumeStackView.addArrangedSubview(self.volumeSliderBackgroundView)
        self.volumeStackView.addArrangedSubview(self.volumeImageView)
        self.volumeStackView.isHidden = self.simplePlayer

        // MARK: Miscellaneous

        var configuration = UIButton.Configuration.plain()
        configuration.imagePadding = 4
        configuration.contentInsets = .zero
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15)
        configuration.imagePlacement = .trailing
        self.skipButton.configuration = configuration
        self.skipButton.tintColor = .white
        self.skipButton.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        self.skipButton.isHidden = true
        self.skipButton.addTarget(self, action: #selector(skipButtonPressed(_:)), for: .touchUpInside)

        self.chapterLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        self.chapterLabel.textColor = .white
        self.chapterLabel.isHidden = true

        // MARK: General

        self.topButtonStackView.translatesAutoresizingMaskIntoConstraints = false
        self.controlsView.addSubview(self.topButtonStackView)

        self.centerButtonStackView.translatesAutoresizingMaskIntoConstraints = false
        self.controlsView.addSubview(self.centerButtonStackView)

        self.bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        self.controlsView.addSubview(self.bottomStackView)

        self.brightnessStackView.translatesAutoresizingMaskIntoConstraints = false
        self.controlsView.addSubview(self.brightnessStackView)

        self.volumeStackView.translatesAutoresizingMaskIntoConstraints = false
        self.controlsView.addSubview(self.volumeStackView)

        self.skipButton.translatesAutoresizingMaskIntoConstraints = false
        self.controlsView.addSubview(self.skipButton)

        self.chapterLabel.translatesAutoresizingMaskIntoConstraints = false
        self.controlsView.addSubview(self.chapterLabel)

        self.controlsView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.controlsView)

        self.tapGestureRecognizer.addTarget(self, action: #selector(tapGesture(_:)))
        self.view.addGestureRecognizer(self.tapGestureRecognizer)

        self.panGestureRecognizer.addTarget(self, action: #selector(panGesture(_:)))
        self.view.addGestureRecognizer(self.panGestureRecognizer)
    }

    override func applyConstraints() {
        self.seekSliderForegroundViewWidthConstraint = self.seekSliderForegroundView.widthAnchor.constraint(equalToConstant: 0)
        self.brightnessSliderForegroundViewHeightConstraint = self.brightnessSliderForegroundView.heightAnchor.constraint(equalToConstant: 0)
        self.volumeSliderForegroundViewHeightConstraint = self.volumeSliderForegroundView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            self.controlsView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.controlsView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.controlsView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.controlsView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),

            self.castLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.castLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),

            self.castButton.widthAnchor.constraint(equalToConstant: 25),

            self.topButtonStackView.topAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.topAnchor, constant: 16),
            self.topButtonStackView.leadingAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            self.topButtonStackView.trailingAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            self.centerButtonStackView.centerXAnchor.constraint(equalTo: self.controlsView.centerXAnchor),
            self.centerButtonStackView.centerYAnchor.constraint(equalTo: self.controlsView.centerYAnchor),

            self.seekSliderBackgroundView.heightAnchor.constraint(equalToConstant: 10),

            self.seekSliderForegroundView.topAnchor.constraint(equalTo: self.seekSliderBackgroundView.topAnchor),
            self.seekSliderForegroundView.leadingAnchor.constraint(equalTo: self.seekSliderBackgroundView.leadingAnchor),
            self.seekSliderForegroundView.bottomAnchor.constraint(equalTo: self.seekSliderBackgroundView.bottomAnchor),
            self.seekSliderForegroundViewWidthConstraint,

            self.bottomStackView.leadingAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            self.bottomStackView.trailingAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            self.bottomStackView.bottomAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.bottomAnchor),

            self.skipButton.bottomAnchor.constraint(equalTo: self.bottomStackView.topAnchor),
            self.skipButton.trailingAnchor.constraint(equalTo: self.bottomStackView.trailingAnchor),

            self.chapterLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.bottomStackView.leadingAnchor),
            self.chapterLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.bottomStackView.trailingAnchor),
            self.chapterLabel.bottomAnchor.constraint(equalTo: self.seekSliderBackgroundView.topAnchor, constant: -8),
            self.chapterLabel.centerXAnchor.constraint(equalTo: self.seekSliderForegroundView.trailingAnchor).withPriority(.defaultLow),

            self.brightnessSliderBackgroundView.widthAnchor.constraint(equalToConstant: 6),
            self.brightnessSliderBackgroundView.heightAnchor.constraint(equalToConstant: 120),

            self.brightnessSliderForegroundView.leadingAnchor.constraint(equalTo: self.brightnessSliderBackgroundView.leadingAnchor),
            self.brightnessSliderForegroundView.trailingAnchor.constraint(equalTo: self.brightnessSliderBackgroundView.trailingAnchor),
            self.brightnessSliderForegroundView.bottomAnchor.constraint(equalTo: self.brightnessSliderBackgroundView.bottomAnchor),
            self.brightnessSliderForegroundViewHeightConstraint,

            self.brightnessStackView.centerXAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            self.brightnessStackView.centerYAnchor.constraint(equalTo: self.controlsView.centerYAnchor),

            self.volumeSliderBackgroundView.widthAnchor.constraint(equalToConstant: 6),
            self.volumeSliderBackgroundView.heightAnchor.constraint(equalToConstant: 120),

            self.volumeSliderForegroundView.leadingAnchor.constraint(equalTo: self.volumeSliderBackgroundView.leadingAnchor),
            self.volumeSliderForegroundView.trailingAnchor.constraint(equalTo: self.volumeSliderBackgroundView.trailingAnchor),
            self.volumeSliderForegroundView.bottomAnchor.constraint(equalTo: self.volumeSliderBackgroundView.bottomAnchor),
            self.volumeSliderForegroundViewHeightConstraint,

            self.volumeStackView.centerXAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            self.volumeStackView.centerYAnchor.constraint(equalTo: self.controlsView.centerYAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.brightnessSliderForegroundViewHeightConstraint.constant = self.brightnessSliderBackgroundView.frame.height * self.brightness
        updateBrightnessImage()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            self.playerLayer.frame = self.view.bounds
            self.controlsGradientLayer.frame = self.view.bounds
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.hidesBackButton = true
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        GCKCastContext.sharedInstance().sessionManager.endSession()
        self.castUpdateTimer?.invalidate()

        self.navigationItem.hidesBackButton = false
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

// MARK: - Player Functions

extension VideoPlayerViewController {
    func setEpisode(toIndex index: Int) async {
        guard self.episodes.indices.contains(index) else { return }

        if index == self.episodeIndex - 1 { // Move to next episode
            // Update trackers to current episode
            if let entry = self.entry, let history = self.history {
                Task {
                    await TrackerManager.shared.setHistory(entry: entry, history: history)
                }
            }

            self.previousDetails = self.currentDetails
            self.currentDetails = self.nextDetails

            self.episodeIndex = index

            if let nextEpisode = self.nextEpisode {
                Task {
                    self.nextDetails = await self.source.getEpisodeDetails(id: nextEpisode.id, entryId: nextEpisode.entryId)
                }
            }
        } else if index == self.episodeIndex + 1 { // Move to previous episode
            self.nextDetails = self.currentDetails
            self.currentDetails = self.previousDetails

            self.episodeIndex = index

            if let previousEpisode = self.previousEpisode {
                Task {
                    self.previousDetails = await self.source.getEpisodeDetails(id: previousEpisode.id, entryId: previousEpisode.entryId)
                }
            }
        } else { // Episode is somewhere random, so we need to wait to get the current details
            let newEpisode = self.episodes[index]
            self.currentDetails = await self.source.getEpisodeDetails(id: newEpisode.id, entryId: newEpisode.entryId)

            if index == self.episodeIndex - 2 { // The current nextDetails are the new previousDetails
                self.previousDetails = self.nextDetails
                if let nextEpisode = self.episodes[safe: index - 1] {
                    Task {
                        self.nextDetails = await self.source.getEpisodeDetails(id: nextEpisode.id, entryId: nextEpisode.entryId)
                    }
                }
            } else if index == self.episodeIndex + 2 { // The current previousDetails are the new nextDetails
                self.nextDetails = self.previousDetails
                if let previousEpisode = self.episodes[safe: index + 1] {
                    Task {
                        self.previousDetails = await self.source.getEpisodeDetails(id: previousEpisode.id, entryId: previousEpisode.entryId)
                    }
                }
            } else { // We cannot salvage any data that is already loaded
                if let previousEpisode = self.episodes[safe: index + 1] {
                    Task {
                        self.previousDetails = await self.source.getEpisodeDetails(id: previousEpisode.id, entryId: previousEpisode.entryId)
                    }
                }

                if let nextEpisode = self.episodes[safe: index - 1] {
                    Task {
                        self.nextDetails = await self.source.getEpisodeDetails(id: nextEpisode.id, entryId: nextEpisode.entryId)
                    }
                }
            }

            self.episodeIndex = index
            self.hasCrossedEndThreshold = false
        }

        if let currentDetails = self.currentDetails, let url = currentDetails.providers.first?.urls.first.flatMap({ URL(string: $0.url) }) {
            await setUrl(to: url)
        }

        updateEpisodeMetadata()
        updateProviderButtonMenu()
    }

    func setUrl(to url: URL, persistTimestamp: Bool = false) async {
        let cachedTime: Double?
        if let session = self.castSession {
            cachedTime = session.remoteMediaClient?.mediaStatus?.streamPosition
        } else {
            cachedTime = self.playerLayer.player?.currentTime().seconds
        }

        stopPlayback()

        let request = await self.source.modifyVideoRequest(
            request: URLRequest(url: url)
        )

        let item = AVPlayerItem(
            asset: AVURLAsset(
                url: request?.url ?? url,
                options: [ "AVURLAssetHTTPHeaderFieldsKey": request?.allHTTPHeaderFields ?? [:] ]
            )
        )

        let player = AVPlayer(playerItem: item)
        setupPlayer(player: player)

        if let session = self.castSession {
            let metadata = GCKMediaMetadata()
            if let episode = self.currentEpisode {
                metadata.setString(episode.toListString(), forKey: kGCKMetadataKeyTitle)
                if let entry = self.entry {
                    metadata.setString(entry.title, forKey: kGCKMetadataKeySubtitle)
                }
                if let thumbnail = episode.thumbnail.flatMap({ URL(string: $0) }) {
                    metadata.addImage(GCKImage(url: thumbnail, width: 1280, height: 720))
                }
            }

            let builder = GCKMediaInformationBuilder(contentURL: url)
            builder.streamType = .none
            builder.metadata = metadata
            let info = builder.build()

            let options = GCKMediaLoadOptions()
            if let time = self.playerLayer.player?.currentTime().seconds {
                options.playPosition = TimeInterval(floatLiteral: time)
            }

            session.remoteMediaClient?.loadMedia(info, with: options)
        }

        self.playerLayer.player = player

        if let session = self.castSession {
            player.volume = session.currentDeviceVolume
        }

        self.volumeSliderForegroundViewHeightConstraint.constant = self.volumeSliderBackgroundView.frame.height * self.volume
        updateVolumeImage()

        self.currentUrl = url

        if persistTimestamp, let cachedTime {
            if let session = self.castSession {
                let options = GCKMediaSeekOptions()
                options.interval = cachedTime
                session.remoteMediaClient?.seek(with: options)
            } else {
                await player.seek(to: CMTime(seconds: Double(cachedTime), preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            }
        } else if history?.episode == self.currentEpisode?.episode, let timestamp = self.history?.timestamp {
            if let session = self.castSession {
                let options = GCKMediaSeekOptions()
                options.interval = TimeInterval(timestamp)
                session.remoteMediaClient?.seek(with: options)
            } else {
                await player.seek(to: CMTime(seconds: Double(timestamp), preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            }
        }

        if self.autoPlay {
            play()
        }
    }

    func stopPlayback() {
        guard let player = self.playerLayer.player else { return }
        player.pause()
        player.currentItem?.asset.cancelLoading()
        player.replaceCurrentItem(with: nil)

        for observer in self.timeObservers {
            player.removeTimeObserver(observer)
        }
        self.timeObservers = []

        for observer in self.keyValueObservers {
            observer.invalidate()
        }
        self.keyValueObservers = []

        self.leftTimeLabel.text = "--:--"
        self.rightTimeLabel.text = "--:--"
        self.seekSliderForegroundViewWidthConstraint.constant = 0
    }

    func setupPlayer(player: AVPlayer) {
        self.timeObservers.append( // Seek bar and skip time time observer
            player.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                queue: .global(qos: .utility)
            ) { [weak self] time in
                guard let self,
                      self.panType != .seek,
                      let item = self.playerLayer.player?.currentItem,
                      time.seconds.isFinite,
                      item.duration.seconds.isFinite else { return }
                Task { @MainActor in
                    self.leftTimeLabel.text = Int(time.seconds).toMinuteSecondString()
                    self.rightTimeLabel.text = "-" + Int(item.duration.seconds - time.seconds).toMinuteSecondString()
                    let percentComplete = time.seconds / item.duration.seconds
                    self.seekSliderForegroundViewWidthConstraint.constant = self.seekSliderBackgroundView.frame.width * percentComplete
                }
                if self.currentSkipItem == nil
                    || time.seconds < self.currentSkipItem!.start
                    || time.seconds >= (self.currentSkipItem!.end ?? item.duration.seconds) - 2 { // Two-second threshold for overlaps
                    if let newSkipItem = self.skipTimes.first(where: {
                        time.seconds >= $0.start && time.seconds < ($0.end ?? item.duration.seconds) - 2 && $0.type.shouldSkip()
                    }) {
                        self.currentSkipItem = newSkipItem
                    } else {
                        self.currentSkipItem = nil
                    }

                    Task { @MainActor in
                        self.updateSkipButton()
                    }
                }
            }
        )

        self.timeObservers.append( // History update time observer
            player.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 15, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                queue: .global(qos: .utility)
            ) { [weak self] time in
                guard let self else { return }

                if let duration = self.playerLayer.player?.currentItem?.duration.seconds,
                   time.seconds < duration - Double(self.endThreshold),
                   let currentEpisode = self.currentEpisode {
                    Task {
                        await self.setHistory(to: currentEpisode, time: Int(time.seconds))
                    }
                } else if !self.hasCrossedEndThreshold {
                    // Update trackers to current episode
                    if let entry = self.entry, let history = self.history {
                        Task {
                            await TrackerManager.shared.setHistory(entry: entry, history: history)
                        }
                    }
                    // Update API to the start of the next episode
                    if let nextEpisode = self.nextEpisode {
                        Task {
                            await self.setHistory(to: nextEpisode)
                        }
                    }

                    self.hasCrossedEndThreshold = true
                }
            }
        )

        if let item = player.currentItem {
            NotificationCenter.default.addObserver(self, selector: #selector(videoFinished), name: .AVPlayerItemDidPlayToEndTime, object: item)
        }

        self.keyValueObservers.append(
            player.observe(\.rate) { [weak self] _, _ in
                self?.updatePlayPauseImage()
            }
        )
    }

    @objc func videoFinished() {
        if self.autoNextEpisode {
            Task {
                await self.setEpisode(toIndex: self.episodeIndex - 1)
            }
        }
    }

    func setHistory(to episode: VideoSourceEpisode, time: Int = 0) async {
        guard let entry = self.entry else { return }

        await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [
            .timestamp(time),
            .episode(episode.episode)
        ])
        if let history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get() {
            self.history = history
        }
    }
}

// MARK: - View Updaters

extension VideoPlayerViewController {
    func setControlsVisibility(_ visible: Bool) {
        if visible, self.controlsView.isHidden {
            self.controlsView.isHidden = false
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                self.controlsView.alpha = 1
            }
        } else if !visible, !self.controlsView.isHidden {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                self.controlsView.alpha = 0
            } completion: { _ in
                self.controlsView.isHidden = true
            }
        }
    }

    func resetControlsHideTimer() {
        self.controlsHideTask?.cancel()
        self.controlsHideTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                self?.setControlsVisibility(false)
            } catch {}
        }
    }

    func updateBrightnessImage() {
        if self.brightness <= 0.5 {
            self.brightnessImageView.image = UIImage(systemName: "sun.min.fill")
        } else {
            self.brightnessImageView.image = UIImage(systemName: "sun.max.fill")
        }
    }

    func updateVolumeImage() {
        let volume = self.volume
        if volume == 0 {
            self.volumeImageView.image = UIImage(systemName: "speaker.slash.fill")
        } else if volume <= 0.25 {
            self.volumeImageView.image = UIImage(systemName: "speaker.fill")
        } else if volume <= 0.5 {
            self.volumeImageView.image = UIImage(systemName: "speaker.wave.1.fill")
        } else if volume <= 0.75 {
            self.volumeImageView.image = UIImage(systemName: "speaker.wave.2.fill")
        } else {
            self.volumeImageView.image = UIImage(systemName: "speaker.wave.3.fill")
        }
    }

    func updateRateButtonMenu() {
        self.rateButton.menu = UIMenu(
            children: ([3, 2, 1.5, 1.25, 1, 0.5, 0.25] as [Double]).map({ rate in
                UIAction(
                    title: rate.toTruncatedString() + "×",
                    image: self.playbackRate == rate ? UIImage(systemName: "checkmark") : nil,
                    handler: { [weak self] _ in
                        self?.playbackRate = rate
                        self?.updateRateButtonMenu()
                        if let session = self?.castSession {
                            session.remoteMediaClient?.setPlaybackRate(Float(rate))
                        } else if let player = self?.playerLayer.player, player.rate != 0 { // Only change rate when playing
                            player.rate = Float(rate)
                        }
                    }
                )
            })
        )
    }

    func updateProviderButtonMenu() {
        guard let currentDetails = self.currentDetails else { return }
        self.providerButton.menu = UIMenu(
            children: currentDetails.providers.reversed().map({ provider in // Menus are upside down for some reason so we must reverse
                UIMenu(
                    title: provider.name,
                    children: provider.urls.sorted(by: { $0.quality ?? -1 < $1.quality ?? -1 }).compactMap({ urlObject in
                        guard let url = URL(string: urlObject.url) else { return nil }
                        return UIAction(
                            title: urlObject.quality.flatMap({ $0.toTruncatedString() + "p" }) ?? "Unknown",
                            image: self.currentUrl == url ? UIImage(systemName: "checkmark") : nil,
                            handler: { [weak self] _ in
                                guard let self else { return }
                                Task {
                                    await self.setUrl(to: url, persistTimestamp: self.persistTimestamp)
                                    self.updateProviderButtonMenu()
                                }
                            }
                        )
                    })
                )
            })
        )
    }

    func updateEpisodeMetadata() {
        guard let currentEpisode = self.currentEpisode else { return }

        self.titleLabel.text = currentEpisode.toListString()

        if let entry = self.entry {
            self.subtitleLabel.text = entry.title
        } else {
            self.subtitleLabel.text = ""
        }

        if let item = self.playerLayer.player?.currentItem {
            item.externalMetadata = []

            let titleMetadata = AVMutableMetadataItem()
            titleMetadata.identifier = .commonIdentifierTitle
            titleMetadata.value = currentEpisode.toListString() as any NSCopying & NSObjectProtocol
            if let copy = titleMetadata.copy() as? AVMetadataItem {
                item.externalMetadata.append(copy)
            }

            if let entry = self.entry {
                let subtitleMetadata = AVMutableMetadataItem()
                subtitleMetadata.identifier = .iTunesMetadataTrackSubTitle
                subtitleMetadata.value = entry.title as any NSCopying & NSObjectProtocol
                if let copy = subtitleMetadata.copy() as? AVMetadataItem {
                    item.externalMetadata.append(copy)
                }
            }
        }
    }

    func updatePlayPauseImage() {
        if let session = self.castSession {
            if session.remoteMediaClient?.mediaStatus?.playerState == .paused {
                self.playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            } else {
                self.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            }
        } else {
            if self.playerLayer.player?.rate == 0 {
                self.playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            } else {
                self.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            }
        }
    }

    func pause() {
        if let session = self.castSession {
            session.remoteMediaClient?.pause()
        } else {
            self.playerLayer.player?.pause()
        }
    }

    func play() {
        if let session = self.castSession {
            session.remoteMediaClient?.play()
        } else {
            self.playerLayer.player?.rate = Float(self.playbackRate)
        }
    }

    func updateSkipButton() {
        if let currentSkipItem = self.currentSkipItem {
            self.skipButton.isHidden = false

            self.skipButton.setAttributedTitle(
                NSAttributedString(
                    string: "Skip \(currentSkipItem.type.rawValue)",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 15, weight: .bold)
                    ]
                ),
                for: .normal
            )
        } else {
            self.skipButton.isHidden = true
        }
    }

    func setChapterLabelVisibility(_ visible: Bool) {
        if visible {
            self.chapterLabel.isHidden = false
            self.bottomButtonTitleStackView.isHidden = true
            self.skipButton.isHidden = true
        } else {
            self.chapterLabel.isHidden = true
            self.bottomButtonTitleStackView.isHidden = false
            updateSkipButton() // Only show the skip button if necessary
        }
    }

    func updateChapterLabel() {
        guard let item = self.playerLayer.player?.currentItem else { return }

        let percentComplete = self.seekSliderForegroundViewWidthConstraint.constant / self.seekSliderBackgroundView.frame.width
        let timeComplete = item.duration.seconds * percentComplete

        if let skipItem = skipTimes.first(where: {
            timeComplete >= $0.start && timeComplete < ($0.end ?? item.duration.seconds)
        }) {
            self.chapterLabel.text = skipItem.type.rawValue
        } else {
            self.chapterLabel.text = nil
        }
    }
}
// MARK: - Button Handlers

extension VideoPlayerViewController {
    @objc func closeButtonPressed(_ sender: UIButton? = nil) {
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }

        stopPlayback()
        self.navigationController?.popViewController(animated: true)
    }

    @objc func pictureInPictureButtonPressed(_ sender: UIButton? = nil) {
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }

        guard self.castSession == nil, let pictureInPictureController = self.pictureInPictureController else { return }

        if pictureInPictureController.isPictureInPictureActive {
            pictureInPictureController.stopPictureInPicture()
        } else {
            pictureInPictureController.startPictureInPicture()
        }
    }

    @objc func airplayButtonPressed(_ sender: UIButton? = nil) {
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }

        if self.castSession == nil, let button = self._airplayButton.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.sendActions(for: .touchUpInside)
        }
    }

    @objc func settingsButtonPressed(_ sender: UIButton? = nil) {
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }

        pause()

        self.navigationController?.pushViewController(self.settingsViewController, animated: true)
    }

    @objc func previousEpisodeButtonPressed(_ sender: UIButton? = nil) {
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }

        Task {
            await self.setEpisode(toIndex: self.episodeIndex + 1)
        }
    }

    @objc func nextEpisodeButtonPressed(_ sender: UIButton? = nil) {
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }

        Task {
            await self.setEpisode(toIndex: self.episodeIndex - 1)
        }
    }

    @objc func skipBackwardButtonPressed(_ sender: UIButton? = nil) {
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }

        if let session = self.castSession {
            let options = GCKMediaSeekOptions()
            options.interval = TimeInterval(integerLiteral: -10)
            options.relative = true
            session.remoteMediaClient?.seek(with: options)
        } else if let player = self.playerLayer.player {
            Task {
                await player.seek(to: CMTime(seconds: player.currentTime().seconds - 10, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            }
        }
    }

    @objc func skipForwardButtonPressed(_ sender: UIButton? = nil) {
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }

        if let session = self.castSession {
            let options = GCKMediaSeekOptions()
            options.interval = TimeInterval(integerLiteral: 10)
            options.relative = true
            session.remoteMediaClient?.seek(with: options)
        } else if let player = self.playerLayer.player {
            Task {
                await player.seek(to: CMTime(seconds: player.currentTime().seconds + 10, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            }
        }
    }

    @objc func playPauseButtonPressed(_ sender: UIButton? = nil) {
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }

        if let session = self.castSession {
            if session.remoteMediaClient?.mediaStatus?.playerState == .paused {
                play()
            } else {
                pause()
            }
        } else {
            if self.playerLayer.player?.rate == 0 {
                play()
            } else {
                pause()
            }
        }
    }

    @objc func captionsButtonPressed(_ sender: UIButton? = nil) { // TODO: Implement for soft subtitles
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }
    }

    @objc func skipButtonPressed(_ sender: UIButton? = nil) {
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }

        if let currentSkipItem = self.currentSkipItem, let player = self.playerLayer.player, let item = player.currentItem {
            if let session = self.castSession {
                let options = GCKMediaSeekOptions()
                options.interval = TimeInterval(floatLiteral: min(currentSkipItem.end ?? .infinity, item.duration.seconds) - 2)
                session.remoteMediaClient?.seek(with: options)
            } else {
                Task {
                    await player.seek(to: CMTime(
                        seconds: min(currentSkipItem.end ?? .infinity, item.duration.seconds) - 2,
                        preferredTimescale: CMTimeScale(NSEC_PER_SEC)
                    ))
                }
            }
        }
    }
}

// MARK: - Gesture Handlers

extension VideoPlayerViewController {
    @objc func tapGesture(_ sender: UITapGestureRecognizer? = nil) {
        self.controlsHideTask?.cancel()
        if self.controlsView.isHidden {
            setControlsVisibility(true)
            resetControlsHideTimer()
        } else if sender != nil { // This tap was not sent by a button
            setControlsVisibility(false)
        }

        if let sender {
            if CGRect(
                x: self.view.center.x - 100,
                y: self.view.center.y - 100,
                width: 200,
                height: 200
            ).contains(sender.location(in: self.view)) {
                playPauseButtonPressed()
            }
        }
    }

    @objc func panGesture(_ sender: UIPanGestureRecognizer) {
        setControlsVisibility(true)

        if sender.state == .ended || sender.state == .cancelled {
            resetControlsHideTimer()

            if self.panType == .seek, let player = self.playerLayer.player, let item = player.currentItem {
                setChapterLabelVisibility(false)

                Task {
                    let barPercentage = self.seekSliderForegroundView.frame.width / self.seekSliderBackgroundView.frame.width

                    if let session = self.castSession {
                        let options = GCKMediaSeekOptions()
                        options.interval = TimeInterval(floatLiteral: item.duration.seconds * barPercentage)
                        session.remoteMediaClient?.seek(with: options)
                    } else {
                        await player.seek(to: CMTime(
                            seconds: item.duration.seconds * barPercentage,
                            preferredTimescale: CMTimeScale(NSEC_PER_SEC)
                        ))
                    }

                    play()

                    self.panType = nil
                }
            } else {
                self.panType = nil
            }
            return
        }
        let initialLocation = sender.location(ofTouch: 0, in: nil)
        let offset = sender.translation(in: nil)
        let velocity = sender.velocity(in: nil)
        if sender.state == .began {
            if abs(velocity.x) > abs(velocity.y) { // Horizontal movement
                self.panType = .seek
                self.initialBarSize = self.seekSliderForegroundView.frame.width
                pause()
                setChapterLabelVisibility(true)
            } else {
                if !self.simplePlayer,
                   self.view.frame.divided(atDistance: self.view.frame.width / 4, from: .minXEdge).slice.contains(initialLocation) {
                    self.initialBarSize = self.brightnessSliderForegroundView.frame.height
                    self.panType = .brightness
                } else if !self.simplePlayer,
                          self.view.frame.divided(atDistance: self.view.frame.width / 4, from: .maxXEdge).slice.contains(initialLocation) {
                    self.initialBarSize = self.volumeSliderForegroundView.frame.height
                    self.panType = .volume
                } else {
                    self.panType = nil
                }
            }
        }
        if self.panType == .seek {
            self.seekSliderForegroundViewWidthConstraint.constant = (self.initialBarSize + offset.x).clamped(
                to: 0...self.seekSliderBackgroundView.frame.width
            )

            if let totalTime = self.playerLayer.player?.currentItem?.duration.seconds {
                let barPercentage = self.seekSliderForegroundView.frame.width / self.seekSliderBackgroundView.frame.width
                self.leftTimeLabel.text = Int(totalTime * barPercentage).toMinuteSecondString()
                self.rightTimeLabel.text = "-" + Int(totalTime - totalTime * barPercentage).toMinuteSecondString()

                updateChapterLabel()
            }
        } else if self.panType == .brightness {
            self.brightnessSliderForegroundViewHeightConstraint.constant = (self.initialBarSize - offset.y / 2).clamped(
                to: 0...self.brightnessSliderBackgroundView.frame.height
            )
            self.brightness = ((self.initialBarSize - offset.y / 2) / self.brightnessSliderBackgroundView.frame.height).clamped(to: 0...1)
            updateBrightnessImage()
        } else if self.panType == .volume {
            self.volumeSliderForegroundViewHeightConstraint.constant = (self.initialBarSize - offset.y / 2).clamped(
                to: 0...self.volumeSliderBackgroundView.frame.height
            )
            self.volume = ((self.initialBarSize - offset.y / 2) / self.volumeSliderBackgroundView.frame.height).clamped(to: 0...1)
            updateVolumeImage()

            if let session = self.castSession {
                session.setDeviceVolume(Float(self.volume))
            }
        }
    }
}

// MARK: - VideoPlayerViewController.PanType

extension VideoPlayerViewController {
    enum PanType {
        case seek
        case brightness
        case volume
    }
}

// MARK: - VideoPlayerViewController + GCKSessionManagerListener

extension VideoPlayerViewController: GCKSessionManagerListener {
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        if let url = self.currentUrl, let episode = self.currentEpisode {
            let metadata = GCKMediaMetadata()
            metadata.setString(episode.toListString(), forKey: kGCKMetadataKeyTitle)
            if let entry = self.entry {
                metadata.setString(entry.title, forKey: kGCKMetadataKeySubtitle)
            }
            if let thumbnail = episode.thumbnail.flatMap({ URL(string: $0) }) {
                metadata.addImage(GCKImage(url: thumbnail, width: 1280, height: 720))
            }

            let builder = GCKMediaInformationBuilder(contentURL: url)
            builder.streamType = .none
            builder.metadata = metadata
            let info = builder.build()

            let options = GCKMediaLoadOptions()
            if let time = self.playerLayer.player?.currentTime().seconds {
                options.playPosition = TimeInterval(floatLiteral: time)
            }

            session.remoteMediaClient?.loadMedia(info, with: options)
        }

        pause()

        self.castSession = session

        self.playerLayer.isHidden = true
        self.castLabel.isHidden = false

        self.castUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if let request = session.remoteMediaClient?.requestStatus() {
                request.delegate = self
            }
        }
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        self.castSession = nil
        self.playerLayer.isHidden = false
        self.castLabel.isHidden = true

        if let time = session.remoteMediaClient?.mediaStatus?.streamPosition {
            Task {
                await self.playerLayer.player?.seek(to: CMTime(
                    seconds: time,
                    preferredTimescale: CMTimeScale(NSEC_PER_SEC)
                ))
            }
        }

        self.castUpdateTimer?.invalidate()
        self.castUpdateTimer = nil
    }

    func sessionManager(
        _ sessionManager: GCKSessionManager,
        castSession session: GCKCastSession,
        didReceiveDeviceVolume volume: Float,
        muted: Bool
    ) {
        guard !volume.isNaN else { return }
        self.volumeSliderForegroundViewHeightConstraint.constant = self.volumeSliderBackgroundView.frame.height * CGFloat(volume)
        self.volume = Double(volume)
        updateVolumeImage()
    }
}

// MARK: - VideoPlayerViewController + GCKRequestDelegate

extension VideoPlayerViewController: GCKRequestDelegate {
    func requestDidComplete(_ request: GCKRequest) {
        if let status = self.castSession?.remoteMediaClient?.mediaStatus {
            self.castingBegan = true
            if let totalTime = self.playerLayer.player?.currentItem?.duration.seconds, self.panType != .seek {
                let playbackPercent = (status.streamPosition / totalTime).clamped(to: 0...1)
                if !playbackPercent.isNaN {
                    self.seekSliderForegroundViewWidthConstraint.constant = self.seekSliderBackgroundView.frame.width * playbackPercent
                    self.leftTimeLabel.text = Int(totalTime * playbackPercent).toMinuteSecondString()
                    self.rightTimeLabel.text = "-" + Int(totalTime - totalTime * playbackPercent).toMinuteSecondString()

                    updateChapterLabel()
                }
            }

            if status.playerState == .paused, !self.isPaused {
                self.updatePlayPauseImage()
                self.isPaused = true
            } else if status.playerState == .playing, self.isPaused {
                self.updatePlayPauseImage()
                self.isPaused = false
            }
        } else if self.castingBegan, self.autoNextEpisode { // ensure that the video was playing before, and now it isn't
            self.castingBegan = false
            Task {
                await self.setEpisode(toIndex: self.episodeIndex - 1)
            }
        }
    }
}
