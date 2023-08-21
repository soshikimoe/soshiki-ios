//
//  ImageReaderViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/17/23.
//

import AsyncDisplayKit
import UIKit

class ImageReaderViewController: BaseViewController {
    let collectionNode: ASCollectionNode

    let settingsViewController: ImageReaderSettingsViewController

    // MARK: Controls
    let controlsView: BackgroundView
    let controlsGradientLayer: CAGradientLayer

    let topButtonStackView: UIStackView
    let closeButton: UIButton
    let topButtonSpacerView: UIView
    let rotationLockButton: UIButton
    let settingsButton: UIButton

    let bottomStackView: UIStackView
    let bottomTitleStackView: UIStackView
    let titleLabel: UILabel
    let subtitleLabel: UILabel
    let seekSliderBackgroundView: ExpandedEventView
    let seekSliderForegroundView: UIView
    var seekSliderForegroundViewWidthConstraint: NSLayoutConstraint!
    let bottomPageStackView: UIStackView
    let leftPageLabel: UILabel
    let bottomPageSpacerView: UIView
    let rightPageLabel: UILabel

    // MARK: Gesture Recognizers
    let tapGestureRecognizer: UITapGestureRecognizer
    let panGestureRecognizer: UIPanGestureRecognizer

    // MARK: Miscellaneous
    var controlsHideTask: Task<Void, Never>?

    var readingMode = (UserDefaults.standard.object(forKey: "settings.image.readingMode") as? String).flatMap({
        ImageReaderViewController.ReadingMode(rawValue: $0)
    }) ?? .rightToLeftPaged {
        didSet {
            guard let currentIndexPath = self.currentIndexPath else { return }

            updateCollectionViewLayout()
            self.collectionNode.reloadData()

            if self.readingMode.isReversed != oldValue.isReversed, let details = self.details[safe: currentIndexPath.section] {
                if let frame = self.collectionNode.collectionViewLayout.layoutAttributesForItem(
                    at: IndexPath(item: details.pages.count - currentIndexPath.item - 1, section: currentIndexPath.section)
                )?.frame {
                    self.collectionNode.setContentOffset(
                        CGPoint(
                            x: frame.midX - UIScreen.main.bounds.width / 2,
                            y: frame.midY - UIScreen.main.bounds.height / 2
                        ),
                        animated: false
                    )

                    self.seekSliderForegroundViewEdgeConstraint.isActive = false
                    if self.readingMode.isReversed {
                        self.seekSliderForegroundViewEdgeConstraint = self.seekSliderForegroundView.trailingAnchor.constraint(
                            equalTo: self.seekSliderBackgroundView.trailingAnchor
                        )
                    } else {
                        self.seekSliderForegroundViewEdgeConstraint = self.seekSliderForegroundView.leadingAnchor.constraint(
                            equalTo: self.seekSliderBackgroundView.leadingAnchor
                        )
                    }
                    self.seekSliderForegroundViewEdgeConstraint.isActive = true
                }
            }
        }
    }

    var initialBarSize: CGFloat

    var isLoaded: Bool

    var cachedIndexPath: IndexPath?

    var seekSliderForegroundViewEdgeConstraint: NSLayoutConstraint!

    // MARK: Entry
    var source: any ImageSource
    var chapters: [ImageSourceChapter]
    var chapterIndex: Int

    var details: [ImageSourceChapterDetails]

    var currentPageIndex: Int

    var entry: ImageEntry
    var history: ImageHistory

    var currentIndexPath: IndexPath? {
        let centerPoint = CGPoint(
            x: self.collectionNode.frame.midX + self.collectionNode.contentOffset.x,
            y: self.collectionNode.frame.midY + self.collectionNode.contentOffset.y
        )

        return self.collectionNode.indexPathForItem(at: centerPoint)
    }

    var currentItem: ASCellNode? {
        if let indexPath = self.currentIndexPath {
            return self.collectionNode.nodeForItem(at: indexPath)
        }
        return nil
    }

    var fetchTask: Task<Void, Never>?

    init(source: any ImageSource, entry: ImageEntry, chapters: [ImageSourceChapter], chapterIndex: Int, history: ImageHistory? = nil) {
        self.collectionNode = ASCollectionNode(collectionViewLayout: UICollectionViewLayout())

        self.settingsViewController = ImageReaderSettingsViewController()

        self.controlsView = BackgroundView()
        self.controlsGradientLayer = CAGradientLayer()

        self.topButtonStackView = UIStackView()
        self.closeButton = UIButton(type: .roundedRect)
        self.topButtonSpacerView = UIView()
        self.rotationLockButton = UIButton(type: .roundedRect)
        self.settingsButton = UIButton(type: .roundedRect)

        self.bottomStackView = UIStackView()
        self.bottomTitleStackView = UIStackView()
        self.titleLabel = UILabel()
        self.subtitleLabel = UILabel()
        self.seekSliderBackgroundView = ExpandedEventView()
        self.seekSliderForegroundView = UIView()
        self.bottomPageStackView = UIStackView()
        self.leftPageLabel = UILabel()
        self.bottomPageSpacerView = UIView()
        self.rightPageLabel = UILabel()

        self.tapGestureRecognizer = UITapGestureRecognizer()
        self.panGestureRecognizer = UIPanGestureRecognizer()

        self.initialBarSize = 0

        self.isLoaded = false

        self.source = source
        self.chapters = chapters
        self.chapterIndex = chapterIndex

        self.details = []

        self.entry = entry
        if let history {
            self.history = history
        } else if let history = DataManager.shared.getHistory(entry) {
            self.history = history
        } else {
            let history = ImageHistory(id: entry.id, sourceId: entry.sourceId)
            DataManager.shared.addHistory(history)
            self.history = history
        }

        self.currentPageIndex = 0

        super.init()

        self.hidesBottomBarWhenPushed = true

        resetControlsHideTimer()

        self.collectionNode.dataSource = self
        self.collectionNode.delegate = self

        self.collectionNode.shouldAnimateSizeChanges = false
        self.collectionNode.showsVerticalScrollIndicator = false
        self.collectionNode.showsHorizontalScrollIndicator = false

        self.collectionNode.setTuningParameters(
            ASRangeTuningParameters(
                leadingBufferScreenfuls: 3,
                trailingBufferScreenfuls: 3
            ),
            for: .display
        )

        super.addObserver("settings.image.readingMode") { [weak self] _ in
            self?.readingMode = (UserDefaults.standard.object(forKey: "settings.image.readingMode") as? String).flatMap({
                ImageReaderViewController.ReadingMode(rawValue: $0)
            }) ?? .rightToLeftPaged
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        updateCollectionViewLayout()

        Task {
            self.collectionNode.isUserInteractionEnabled = false

            await loadChapter(at: self.chapterIndex, insertToTop: false)
            if self.readingMode.isReversed {
                await loadChapter(at: self.chapterIndex - 1, insertToTop: true) // Load the next chapter first because it is closest
                await loadChapter(at: self.chapterIndex + 1, insertToTop: false)
            } else {
                await loadChapter(at: self.chapterIndex + 1, insertToTop: true) // Load the previous chapter first because it is closest
                await loadChapter(at: self.chapterIndex - 1, insertToTop: false)
            }

            if self.readingMode.isReversed,
               let chapter = self.chapters[safe: self.chapterIndex],
               let details = self.details.first(where: { $0.id == chapter.id }) {
                Task { @MainActor in
                    self.collectionNode.setContentOffset(
                        CGPoint(
                            x: self.collectionNode.contentOffset.x + UIScreen.main.bounds.width * CGFloat(details.pages.count - 1),
                            y: self.collectionNode.contentOffset.y
                        ),
                        animated: false
                    )
                }
            }

            if let chapter = self.chapters[safe: chapterIndex] {
                self.setChapter(to: chapter)
            }

            if self.history.chapter == self.chapters[safe: self.chapterIndex]?.chapter,
               self.history.volume == self.chapters[safe: self.chapterIndex]?.volume,
               let chapter = self.chapters[safe: self.chapterIndex],
               let details = self.details.first(where: { $0.id == chapter.id }) {
                self.collectionNode.scrollToItem(
                    at: IndexPath(
                        item: self.readingMode.isReversed ? details.pages.count - 1 - self.history.page : self.history.page,
                        section: self.currentIndexPath?.section ?? 0
                    ),
                    at: self.readingMode.scrollDirection == .vertical ? .centeredVertically : .centeredHorizontally,
                    animated: false
                )
            }

            self.collectionNode.isUserInteractionEnabled = true
            self.isLoaded = true
        }
    }

    override func configureViews() {
        self.view.backgroundColor = .black

        self.collectionNode.view.backgroundColor = .systemBackground
        self.collectionNode.shouldAnimateSizeChanges = false

        self.collectionNode.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.collectionNode.view)

        self.controlsGradientLayer.colors = [
            UIColor(white: 0, alpha: 0.6).cgColor,
            UIColor(white: 0, alpha: 0.3).cgColor,
            UIColor(white: 0, alpha: 0.6).cgColor
        ]
        self.controlsGradientLayer.locations = [ 0, 0.5, 1 ]
        self.controlsGradientLayer.frame = self.view.bounds
        self.controlsGradientLayer.needsDisplayOnBoundsChange = true
        self.controlsView.layer.insertSublayer(self.controlsGradientLayer, at: 0)

        self.closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        self.closeButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        self.closeButton.tintColor = .white
        self.closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)

        self.settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
        self.settingsButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20), forImageIn: .normal)
        self.settingsButton.tintColor = .white
        self.settingsButton.addTarget(self, action: #selector(settingsButtonPressed(_:)), for: .touchUpInside)

        self.topButtonStackView.spacing = 12
        self.topButtonStackView.alignment = .center
        self.topButtonStackView.axis = .horizontal
        self.topButtonStackView.addArrangedSubview(self.closeButton)
        self.topButtonStackView.addArrangedSubview(self.topButtonSpacerView)
        self.topButtonStackView.addArrangedSubview(self.rotationLockButton)
        self.topButtonStackView.addArrangedSubview(self.settingsButton)

        self.titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        self.titleLabel.textColor = .white

        self.subtitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        self.subtitleLabel.textColor = .white

        self.bottomTitleStackView.axis = .vertical
        self.bottomTitleStackView.alignment = .leading
        self.bottomTitleStackView.isUserInteractionEnabled = false
        self.bottomTitleStackView.addArrangedSubview(self.subtitleLabel)
        self.bottomTitleStackView.addArrangedSubview(self.titleLabel)

        self.seekSliderBackgroundView.backgroundColor = UIColor(white: 0.75, alpha: 0.8)
        self.seekSliderBackgroundView.layer.cornerRadius = 5
        self.seekSliderBackgroundView.clipsToBounds = true
        self.seekSliderBackgroundView.eventEdgeInsets = UIEdgeInsets(all: 50)

        self.seekSliderForegroundView.backgroundColor = .white
        self.seekSliderForegroundView.isUserInteractionEnabled = false

        self.leftPageLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        self.leftPageLabel.textColor = .white
        self.leftPageLabel.text = "Page -"

        self.rightPageLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        self.rightPageLabel.textColor = .lightGray
        self.rightPageLabel.text = "- Pages"

        self.bottomPageStackView.axis = .horizontal
        self.bottomPageStackView.isUserInteractionEnabled = false
        self.bottomPageStackView.addArrangedSubview(self.leftPageLabel)
        self.bottomPageStackView.addArrangedSubview(self.bottomPageSpacerView)
        self.bottomPageStackView.addArrangedSubview(self.rightPageLabel)

        self.seekSliderForegroundView.translatesAutoresizingMaskIntoConstraints = false
        self.seekSliderBackgroundView.addSubview(self.seekSliderForegroundView)

        self.bottomStackView.axis = .vertical
        self.bottomStackView.spacing = 4
        self.bottomStackView.addArrangedSubview(self.bottomTitleStackView)
        self.bottomStackView.addArrangedSubview(self.seekSliderBackgroundView)
        self.bottomStackView.addArrangedSubview(self.bottomPageStackView)

        self.topButtonStackView.translatesAutoresizingMaskIntoConstraints = false
        self.controlsView.addSubview(self.topButtonStackView)

        self.bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        self.controlsView.addSubview(self.bottomStackView)

        self.controlsView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.controlsView)

        self.tapGestureRecognizer.addTarget(self, action: #selector(tapGesture(_:)))
        self.view.addGestureRecognizer(self.tapGestureRecognizer)

        self.panGestureRecognizer.addTarget(self, action: #selector(panGesture(_:)))
        self.seekSliderBackgroundView.addGestureRecognizer(self.panGestureRecognizer)
    }

    override func applyConstraints() {
        self.seekSliderForegroundViewWidthConstraint = self.seekSliderForegroundView.widthAnchor.constraint(equalToConstant: 0)

        if self.readingMode.isReversed {
            self.seekSliderForegroundViewEdgeConstraint = self.seekSliderForegroundView.trailingAnchor.constraint(
                equalTo: self.seekSliderBackgroundView.trailingAnchor
            )
        } else {
            self.seekSliderForegroundViewEdgeConstraint = self.seekSliderForegroundView.leadingAnchor.constraint(
                equalTo: self.seekSliderBackgroundView.leadingAnchor
            )
        }

        NSLayoutConstraint.activate([
            self.collectionNode.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.collectionNode.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.collectionNode.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.collectionNode.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),

            self.controlsView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.controlsView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.controlsView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.controlsView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),

            self.topButtonStackView.topAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.topAnchor, constant: 16),
            self.topButtonStackView.leadingAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            self.topButtonStackView.trailingAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            self.seekSliderBackgroundView.heightAnchor.constraint(equalToConstant: 10),

            self.seekSliderForegroundViewEdgeConstraint,
            self.seekSliderForegroundView.heightAnchor.constraint(equalTo: self.seekSliderBackgroundView.heightAnchor),
            self.seekSliderForegroundView.centerYAnchor.constraint(equalTo: self.seekSliderBackgroundView.centerYAnchor),
            self.seekSliderForegroundViewWidthConstraint,

            self.bottomStackView.leadingAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            self.bottomStackView.trailingAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            self.bottomStackView.bottomAnchor.constraint(equalTo: self.controlsView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.hidesBackButton = true
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.navigationItem.hidesBackButton = false
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.cachedIndexPath = self.currentIndexPath

        coordinator.animate { [weak self] _ in
            guard let self, let currentIndexPath = self.currentIndexPath else { return }
            var offset: CGPoint = .zero
            if self.readingMode.scrollDirection == .vertical {
                for section in 0..<(currentIndexPath.section) {
                    if let details = self.details[safe: section] {
                        offset.y += CGFloat(details.pages.count + 1) * size.height
                    }
                }
                offset.y += CGFloat(currentIndexPath.item) * size.height / CGFloat(self.readingMode.isPaged ? 1 : 2)
            } else {
                for section in 0..<(currentIndexPath.section) {
                    if let details = self.details[safe: section] {
                        offset.x += CGFloat(details.pages.count + 1) * size.width
                    }
                }
                offset.x += CGFloat(currentIndexPath.item) * size.width
            }
            self.collectionNode.reloadData {
                self.collectionNode.setContentOffset(offset, animated: false)
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        CATransaction.setDisableActions(true)
        self.controlsGradientLayer.frame = self.view.bounds
        CATransaction.commit()
    }

    func updateCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = self.readingMode.scrollDirection

        self.collectionNode.collectionViewLayout = layout

        self.collectionNode.isPagingEnabled = self.readingMode.isPaged
    }
}

// MARK: - Reader Functions

extension ImageReaderViewController {
    func loadChapter(at chapterIndex: Int, insertToTop: Bool) async {
        guard let chapter = self.chapters[safe: chapterIndex],
              !self.details.contains(where: { $0.id == chapter.id }) else { return }

        if let details = await self.source.getChapterDetails(id: chapter.id, entryId: chapter.entryId) {
            if insertToTop {
                self.details.insert(details, at: 0)

                let indexPaths = details.pages.indices.map({
                    IndexPath(item: $0, section: 0)
                }) + [ IndexPath(item: details.pages.count, section: 0) ] // Info page

                let oldCollectionNodeContentSize = self.collectionNode.view.contentSize

                CATransaction.begin()
                CATransaction.setDisableActions(true)
                CATransaction.setAnimationDuration(0)
                await self.collectionNode.performBatch(animated: false) {
                    self.collectionNode.insertSections(IndexSet(integer: 0))
                    self.collectionNode.insertItems(at: indexPaths)
                }

                let newCollectionNodeContentSize = self.collectionNode.view.contentSize
                let horizontalDifference = newCollectionNodeContentSize.width - oldCollectionNodeContentSize.width
                let verticalDifference = newCollectionNodeContentSize.height - oldCollectionNodeContentSize.height
                Task { @MainActor in
                    self.collectionNode.setContentOffset(
                        CGPoint(
                            x: self.collectionNode.contentOffset.x + horizontalDifference,
                            y: self.collectionNode.contentOffset.y + verticalDifference
                        ),
                        animated: false
                    )

                    CATransaction.commit()
                }
            } else {
                self.details.append(details)

                let indexPaths = details.pages.indices.map({ IndexPath(item: $0, section: self.details.count - 1) })

                CATransaction.begin()
                CATransaction.setDisableActions(true)
                CATransaction.setAnimationDuration(0)
                await self.collectionNode.performBatch(animated: false) {
                    self.collectionNode.insertSections(IndexSet(integer: self.details.count - 1))
                    self.collectionNode.insertItems(at: indexPaths)

                    if self.details.count > 1, let previousDetails = self.details[safe: self.details.count - 2] {
                        self.collectionNode.insertItems(at: [
                            IndexPath(item: previousDetails.pages.count, section: self.details.count - 2)
                        ]) // Insert an info page to the (previously) last chapter
                    }
                }
                CATransaction.commit()
            }
        }
    }

    func setChapter(to chapter: ImageSourceChapter) {
        self.titleLabel.text = chapter.toListString()
        self.subtitleLabel.text = self.entry.title

        if let currentIndexPath = self.currentIndexPath,
           let chapter = self.chapters.first(where: { $0.id == self.details[safe: currentIndexPath.section]?.id }) {
            self.history.chapter = chapter.chapter
            self.history.volume = chapter.volume
            DataManager.shared.setHistory(self.history)
        }
    }

    func shouldAttemptPreloading() -> Bool {
        if self.isLoaded,
           self.collectionNode.numberOfSections > 0,
           let currentIndexPath = self.currentIndexPath {
            if self.collectionNode.scrollDirection == .right || self.collectionNode.scrollDirection == .down { // Forwards
                return currentIndexPath.section == self.collectionNode.numberOfSections - 1 // In the last section, load more
            } else { // Backwards
                return currentIndexPath.section == 0 // In the first section, load more
            }
        }
        return false
    }

    func attemptPreloading() {
        guard self.fetchTask == nil, let currentIndexPath = self.currentIndexPath else { return }

        self.fetchTask = Task {
            if self.readingMode.isReversed {
                if currentIndexPath.section == 0,
                   let firstDetails = self.details.first,
                   let chapterIndex = self.chapters.firstIndex(where: { $0.id == firstDetails.id }) { // Next chapter
                    await loadChapter(at: chapterIndex - 1, insertToTop: true)
                } else if currentIndexPath.section == self.details.count - 1,
                          let lastDetails = self.details.last,
                          let chapterIndex = self.chapters.firstIndex(where: { $0.id == lastDetails.id }) { // Previous chapter
                    await loadChapter(at: chapterIndex + 1, insertToTop: false)
                }
            } else {
                if currentIndexPath.section == 0,
                   let firstDetails = self.details.first,
                   let chapterIndex = self.chapters.firstIndex(where: { $0.id == firstDetails.id }) { // Previous chapter
                    await loadChapter(at: chapterIndex + 1, insertToTop: true)
                } else if currentIndexPath.section == self.details.count - 1,
                          let lastDetails = self.details.last,
                          let chapterIndex = self.chapters.firstIndex(where: { $0.id == lastDetails.id }) { // Next chapter
                    await loadChapter(at: chapterIndex - 1, insertToTop: false)
                }
            }

            self.fetchTask = nil
        }
    }
}

// MARK: - ImageReaderViewController + ASCollectionDataSource

extension ImageReaderViewController: ASCollectionDataSource {
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        self.details.count
    }

    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        if section == self.details.count - 1 {
            return self.details[safe: section]?.pages.count ?? 0
        } else {
            return (self.details[safe: section]?.pages.count ?? 0) + 1 // Info page
        }
    }

    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        guard let details = self.details[safe: indexPath.section],
              let chapterIndex = self.chapters.firstIndex(where: { $0.id == details.id }) else { return ASCellNode() }

        if indexPath.item == details.pages.count { // This must be an info page
            if self.readingMode.isReversed {
                return ImageReaderInfoCellNode(
                    previous: self.chapters[safe: chapterIndex + 1],
                    next: self.chapters[safe: chapterIndex],
                    readingMode: self.readingMode
                )
            } else {
                return ImageReaderInfoCellNode(
                    previous: self.chapters[safe: chapterIndex],
                    next: self.chapters[safe: chapterIndex - 1],
                    readingMode: self.readingMode
                )
            }
        } else { // This is an image page
            let index = self.readingMode.isReversed ? details.pages.count - indexPath.item - 1 : indexPath.item
            let imageCellNode = ImageReaderImageCellNode(source: self.source, pageIndex: index, readingMode: self.readingMode)
            imageCellNode.delegate = self
            imageCellNode.resizeDelegate = self
            if let imageUrl = details.pages[safe: index]?.url.flatMap({ URL(string: $0) }) {
                imageCellNode.setImage(to: imageUrl)
            }
            return imageCellNode
        }
    }
}

// MARK: - ImageReaderViewController + ASCollectionDelegate

extension ImageReaderViewController: ASCollectionDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSeekSliderPosition()
        updatePage()

        if let currentIndexPath = self.currentIndexPath,
           let currentDetails = self.details[safe: currentIndexPath.section],
           let currentChapterIndex = self.chapters.firstIndex(where: { $0.id == currentDetails.id }),
           self.chapterIndex != currentChapterIndex,
           let chapter = self.chapters[safe: currentChapterIndex] {
            self.chapterIndex = currentChapterIndex
            setChapter(to: chapter)
        }
    }
}

// MARK: - View Updaters

extension ImageReaderViewController {
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

    func updateSeekSliderPosition() {
        guard let currentIndexPath = self.currentIndexPath,
              let currentDetails = self.details[safe: currentIndexPath.section] else { return }

        if self.readingMode.isPaged {
            let index = self.readingMode.isReversed ? currentDetails.pages.count - currentIndexPath.item - 1 : currentIndexPath.item
            let percent = (Double(index) / Double(currentDetails.pages.count - 1)).clamped(to: 0...1) // We want the percent to be from 0 to 1
            self.seekSliderForegroundViewWidthConstraint.constant = self.seekSliderBackgroundView.frame.width * CGFloat(percent)
        } else {
            let minY = self.collectionNode.collectionViewLayout.layoutAttributesForItem(
                at: IndexPath(item: 0, section: currentIndexPath.section)
            )?.frame.minY ?? 0
            let maxY = self.collectionNode.collectionViewLayout.layoutAttributesForItem(
                at: IndexPath(item: currentDetails.pages.count - 1, section: currentIndexPath.section)
            )?.frame.maxY ?? 0
            let centerPosition = self.collectionNode.contentOffset.y + self.collectionNode.frame.height / 2
            let percent = (Double(centerPosition - minY) / Double(maxY - minY)).clamped(to: 0...1)
            self.seekSliderForegroundViewWidthConstraint.constant = self.seekSliderBackgroundView.frame.width * CGFloat(percent)
        }
    }

    func updatePage() {
        guard let currentIndexPath = self.currentIndexPath,
              let currentDetails = self.details[safe: currentIndexPath.section] else { return }

        let previousPageIndex = self.currentPageIndex

        if self.readingMode.isReversed {
            self.currentPageIndex = currentDetails.pages.count - currentIndexPath.item.clamped(to: 0..<currentDetails.pages.count) - 1
        } else {
            self.currentPageIndex = currentIndexPath.item.clamped(to: 0..<currentDetails.pages.count)
        }

        if previousPageIndex != self.currentPageIndex { // Do image preloading
            for offset in -3...3 {
                if let node = self.collectionNode.nodeForItem(
                    at: IndexPath(
                        item: (currentIndexPath.item + offset).clamped(to: 0..<currentDetails.pages.count),
                        section: currentIndexPath.section
                    )
                ) as? ImageReaderImageCellNode, node.imageNode.image == nil, node.imageTask == nil {
                    node.loadImage()
                }
            }

            self.history.page = self.currentPageIndex + 1
            DataManager.shared.setHistory(self.history)

            Task { @MainActor in
                self.leftPageLabel.text = "Page \(self.currentPageIndex + 1)"
                self.rightPageLabel.text = "\(currentDetails.pages.count) Pages"
            }
        }
    }
}

// MARK: - Button Handlers

extension ImageReaderViewController {
    @objc func closeButtonPressed(_ sender: UIButton? = nil) {
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }

        self.navigationController?.popViewController(animated: true)
    }

    @objc func settingsButtonPressed(_ sender: UIButton? = nil) {
        if sender != nil { // Ensure that a button sent the gesture
            self.tapGesture()
        }

        self.navigationController?.pushViewController(self.settingsViewController, animated: true)
    }
}

// MARK: - Gesture Handlers

extension ImageReaderViewController {
    @objc func tapGesture(_ sender: UITapGestureRecognizer? = nil) {
        self.controlsHideTask?.cancel()
        if self.controlsView.isHidden {
            setControlsVisibility(true)
            resetControlsHideTimer()
        } else if sender != nil { // This tap was not sent by a button
            setControlsVisibility(false)
        }
    }

    @objc func panGesture(_ sender: UIPanGestureRecognizer) {
        setControlsVisibility(true)

        if sender.state == .ended || sender.state == .cancelled {
            resetControlsHideTimer()

            if self.readingMode.isPaged,
               let currentIndexPath = self.currentIndexPath,
               let frame = self.collectionNode.collectionViewLayout.layoutAttributesForItem(at: currentIndexPath)?.frame {
                self.collectionNode.setContentOffset(
                    CGPoint(
                        x: frame.midX - UIScreen.main.bounds.width / 2,
                        y: frame.midY - UIScreen.main.bounds.height / 2
                    ),
                    animated: true
                )
            }
        }

        if sender.state == .began {
            self.initialBarSize = self.seekSliderForegroundViewWidthConstraint.constant
        }

        guard let currentIndexPath = self.currentIndexPath,
              let currentDetails = self.details[safe: currentIndexPath.section] else { return }

        let offset = sender.translation(in: self.view)
        let constant = (self.initialBarSize + offset.x * (self.readingMode.isReversed ? -1 : 1)).clamped(
            to: 0...self.seekSliderBackgroundView.frame.width
        )

        if self.readingMode.isPaged {
            let segmentSize = self.seekSliderBackgroundView.frame.width / CGFloat(currentDetails.pages.count - 1)
            self.seekSliderForegroundViewWidthConstraint.constant = round(constant / segmentSize) * segmentSize
        } else {
            self.seekSliderForegroundViewWidthConstraint.constant = constant
        }

        if self.readingMode.scrollDirection == .vertical {
            let minY = self.collectionNode.collectionViewLayout.layoutAttributesForItem(
                at: IndexPath(item: 0, section: currentIndexPath.section)
            )?.frame.minY ?? 0
            let maxY = self.collectionNode.collectionViewLayout.layoutAttributesForItem(
                at: IndexPath(item: currentDetails.pages.count - 1, section: currentIndexPath.section)
            )?.frame.maxY ?? 0
            let multiplier = (maxY - minY) / self.seekSliderBackgroundView.frame.width
            self.collectionNode.setContentOffset(
                CGPoint(
                    x: self.collectionNode.contentOffset.x,
                    y: minY + constant * multiplier
                ),
                animated: false
            )
        } else {
            let minX = self.collectionNode.collectionViewLayout.layoutAttributesForItem(
                at: IndexPath(item: 0, section: currentIndexPath.section)
            )?.frame.minX ?? 0
            let maxX = self.collectionNode.collectionViewLayout.layoutAttributesForItem(
                at: IndexPath(item: currentDetails.pages.count - 1, section: currentIndexPath.section)
            )?.frame.maxX ?? 0
            let multiplier = (maxX - minX) / self.seekSliderBackgroundView.frame.width
            if self.readingMode.isReversed {
                self.collectionNode.setContentOffset(
                    CGPoint(
                        x: maxX - constant * multiplier,
                        y: self.collectionNode.contentOffset.y
                    ),
                    animated: false
                )
            } else {
                self.collectionNode.setContentOffset(
                    CGPoint(
                        x: minX + constant * multiplier,
                        y: self.collectionNode.contentOffset.y
                    ),
                    animated: false
                )
            }
        }
    }
}

// MARK: - ImageReaderViewController + ImageReaderCellNodeDelegate

extension ImageReaderViewController: ImageReaderCellNodeDelegate {
    func didEnterVisibleState(at indexPath: IndexPath) {
        if shouldAttemptPreloading() {
            attemptPreloading() // Run this here to ensure it isn't spammed
        }
    }
}

// MARK: - ImageReaderViewController + ImageCellNodeResizeDelegate

extension ImageReaderViewController: ImageCellNodeResizeDelegate {
    func willResize(from currentSize: CGSize, to newSize: CGSize, at indexPath: IndexPath) {
        guard !self.readingMode.isPaged, let currentIndexPath = self.currentIndexPath else { return }

        if indexPath < currentIndexPath
            || (indexPath == currentIndexPath && self.collectionNode.scrollDirection == .up) {
            let difference = newSize.height - currentSize.height
            self.collectionNode.setContentOffset(
                CGPoint(
                    x: self.collectionNode.contentOffset.x,
                    y: self.collectionNode.contentOffset.y + difference
                ),
                animated: false
            )
        }
    }
}

// MARK: - ImageReaderViewController.ReadingMode

extension ImageReaderViewController {
    enum ReadingMode: String, CaseIterable {
        case leftToRightPaged = "Left to Right"
        case rightToLeftPaged = "Right to Left"
        case verticalPaged = "Vertical Paged"
        case verticalScroll = "Vertical Scroll"

        var scrollDirection: UICollectionView.ScrollDirection {
            switch self {
            case .leftToRightPaged, .rightToLeftPaged: return .horizontal
            case .verticalPaged, .verticalScroll: return .vertical
            }
        }

        var isPaged: Bool {
            self != .verticalScroll
        }

        var isReversed: Bool {
            self == .rightToLeftPaged
        }
    }
}
