//
//  EntryViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/29/23.
//

import UIKit
import Nuke
import SafariServices

class EntryViewController: BaseViewController {
    var entry: Entry? {
        didSet {
            self.headerView.updateMoreButtonState()

            if self.entry == nil {
                self.headerView.libraryButton.setImage(UIImage(systemName: "link.badge.plus"), for: .normal)
            } else if self.isInLibrary {
                self.headerView.libraryButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
            } else {
                self.headerView.libraryButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
            }
        }
    }

    var isInLibrary: Bool {
        LibraryManager.shared.library(forMediaType: self.mediaType)?.all.ids.contains(where: { $0 == entry?._id }) == true
    }

    var libraryAddTask: Task<Void, Never>?

    var history: History? {
        didSet {
            updateStartButton()
            self.tableView.reloadData()
        }
    }

    var mediaType: MediaType {
        self.source?.source is any TextSource
            ? .text
            : self.source?.source is any ImageSource
                ? .image
                : self.source?.source is any VideoSource ? .video : LibraryManager.shared.mediaType
    }

    var sourceEntry: SourceEntry? {
        didSet {
            if let sourceEntry = self.sourceEntry {
                self.headerView.setEntry(to: sourceEntry)
            }
        }
    }
    var source: (source: any Source, id: String)? {
        didSet {
            if self.source?.source.id != oldValue?.source.id || self.source?.id != oldValue?.id {
                self.sourceSelectButton.setAttributedTitle(
                    NSAttributedString(
                        string: self.source?.source.name ?? "None",
                        attributes: [ .font: UIFont.systemFont(ofSize: 17, weight: .semibold) ]
                    ),
                    for: .normal
                )
                self.sourceSelectButton.menu = UIMenu(children: self.sourceActions)

                reloadItems()
            }
        }
    }
    var tracker: Tracker?

    var textChapters: [TextSourceChapter]
    var imageChapters: [ImageSourceChapter]
    var videoEpisodes: [VideoSourceEpisode]

    var items: [SourceItem] {
        didSet {
            self.tableView.reloadData()

            let type = self.mediaType == .video ? "Episode" : "Chapter"
            self.itemCountLabel.text = "\(self.items.count) \(type)\(self.items.count == 1 ? "" : "s")"
        }
    }
    var itemLoadTask: Task<Void, Never>?

    var sources: [(source: any Source, id: String)] {
        didSet {
            self.sourceSelectButton.menu = UIMenu(children: self.sourceActions)
        }
    }

    var sourceActions: [UIAction] {
        self.sources.map({ source in
            UIAction(
                title: source.source.name,
                image: self.source?.source.id == source.source.id && self.source?.id == source.id ? UIImage(systemName: "checkmark") : nil
            ) { [weak self] _ in
                self?.source = source
            }
        })
    }

    // MARK: Views
    let headerView: EntryHeaderView

    var headerViewHeightConstraint: NSLayoutConstraint!
    var headerViewTopConstraint: NSLayoutConstraint!

    let wrapperView: UIView

    let tableView: UITableView

    let sourceTitleLabel: UILabel
    let sourceSelectButton: UIButton
    let sourceStackSpacerView: UIView
    let itemCountLabel: UILabel
    let sourceStackView: UIStackView

    // MARK: Miscellaneous

    var isLandscape: Bool {
        self.view.frame.width > self.view.frame.height
    }

    convenience init(sourceEntry: SourceEntry, source: any Source) {
        self.init(sourceEntry: sourceEntry, source: source, tracker: nil, entry: nil)

        Task {
            if let entry = try? await SoshikiAPI.shared.getLink(
                mediaType: self.mediaType,
                platformId: "soshiki",
                sourceId: source.id,
                entryId: sourceEntry.id
            ).get().first {
                self.entry = entry

                self.history = try? await SoshikiAPI.shared.getHistory(mediaType: self.mediaType, id: entry._id).get()

                self.sources = entry.platforms.first(where: { $0.id == "soshiki" })?.sources.compactMap({ source in
                    SourceManager.shared.sources.first(where: { $0.id == source.id }).flatMap({ (source: $0, id: source.entryId) })
                }) ?? []

                reloadItems()
            } else {
                self.source = (source: source, id: sourceEntry.id)
                self.sources = [(source: source, id: sourceEntry.id)]
            }
        }
    }

    convenience init(sourceEntry: SourceEntry, tracker: Tracker) {
        self.init(sourceEntry: sourceEntry, source: nil, tracker: tracker, entry: nil)

        Task {
            if let entry = try? await SoshikiAPI.shared.getLink(
                mediaType: self.mediaType,
                trackerId: tracker.id,
                entryId: sourceEntry.id
            ).get().first {
                self.entry = entry

                self.history = try? await SoshikiAPI.shared.getHistory(mediaType: self.mediaType, id: entry._id).get()

                self.sources = entry.platforms.first(where: { $0.id == "soshiki" })?.sources.compactMap({ source in
                    SourceManager.shared.sources.first(where: { $0.id == source.id }).flatMap({ (source: $0, id: source.entryId) })
                }) ?? []

                self.source = self.sources.first

                reloadItems()
            }
        }
    }

    convenience init(entry: Entry) {
        self.init(sourceEntry: entry.toSourceEntry(), source: nil, tracker: nil, entry: entry)

        Task {
            self.history = try? await SoshikiAPI.shared.getHistory(mediaType: self.mediaType, id: entry._id).get()

            self.sources = entry.platforms.first(where: { $0.id == "soshiki" })?.sources.compactMap({ source in
                SourceManager.shared.sources.first(where: { $0.id == source.id }).flatMap({ (source: $0, id: source.entryId) })
            }) ?? []

            if let source = self.sources.first {
                self.source = source
            }

            reloadItems()
        }
    }

    convenience init(sourceShortEntry: SourceShortEntry, source: any Source) {
        self.init(sourceEntry: nil, source: source, tracker: nil, entry: nil)

        self.source = (source: source, id: sourceShortEntry.id)

        Task {
            if let sourceEntry = await source.getEntry(id: sourceShortEntry.id) {
                self.sourceEntry = sourceEntry
                if let entry = try? await SoshikiAPI.shared.getLink(
                    mediaType: self.mediaType,
                    platformId: "soshiki",
                    sourceId: source.id,
                    entryId: sourceEntry.id
                ).get().first {
                    self.entry = entry

                    self.history = try? await SoshikiAPI.shared.getHistory(mediaType: self.mediaType, id: entry._id).get()

                    self.sources = entry.platforms.first(where: { $0.id == "soshiki" })?.sources.compactMap({ source in
                        SourceManager.shared.sources.first(where: { $0.id == source.id }).flatMap({ (source: $0, id: source.entryId) })
                    }) ?? []

                    reloadItems()
                } else {
                    self.source = (source: source, id: sourceEntry.id)
                    self.sources = [(source: source, id: sourceEntry.id)]
                }
            }
        }
    }

    private init(sourceEntry: SourceEntry?, source: (any Source)?, tracker: Tracker?, entry: Entry?) {
        self.sourceEntry = nil
        self.source = nil
        defer { // calls the didSet
            self.sourceEntry = sourceEntry
            self.source = sourceEntry.flatMap({ sourceEntry in source.flatMap({ (source: $0, id: sourceEntry.id) }) })
        }
        self.tracker = tracker
        self.entry = entry

        self.headerView = EntryHeaderView()

        self.wrapperView = UIView()

        self.tableView = UITableView(frame: .zero, style: .plain)

        self.textChapters = []
        self.imageChapters = []
        self.videoEpisodes = []

        self.items = []

        self.sources = []

        self.sourceTitleLabel = UILabel()
        self.sourceSelectButton = UIButton(type: .roundedRect)
        self.sourceStackSpacerView = UIView()
        self.itemCountLabel = UILabel()
        self.sourceStackView = UIStackView()

        super.init()

        if self.entry == nil {
            self.headerView.libraryButton.setImage(UIImage(systemName: "link.badge.plus"), for: .normal)
        } else if self.isInLibrary {
            self.headerView.libraryButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
        } else {
            self.headerView.libraryButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        }

        super.addObserver(LibraryManager.Keys.libraries) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if self.isInLibrary {
                    self.headerView.libraryButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
                } else {
                    self.headerView.libraryButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
                }
            }
        }

        super.addObserver("app.link.update") { [weak self] notification in
            guard let self, let source = self.source, let id = notification.object as? String, source.id == id else { return }
            Task {
                self.entry = (try? await SoshikiAPI.shared.getLink(
                    mediaType: self.mediaType,
                    platformId: "soshiki",
                    sourceId: source.source.id,
                    entryId: source.id
                ).get())?.first
                if let entry = self.entry {
                    self.headerView.setEntry(to: entry.toSourceEntry())

                    self.sources = entry.platforms.first(where: { $0.id == "soshiki" })?.sources.compactMap({ source in
                        SourceManager.shared.sources.first(where: { $0.id == source.id }).flatMap({ (source: $0, id: source.entryId) })
                    }) ?? []

                    self.reloadItems()
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = self.tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        self.navigationItem.standardAppearance = appearance
        self.navigationItem.scrollEdgeAppearance = appearance
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func configureViews() {
        self.tableView.backgroundColor = .systemBackground
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(EntryItemTableViewCell.self, forCellReuseIdentifier: "EntryItemTableViewCell")
        self.tableView.contentInset = UIEdgeInsets(all: 16)
        self.tableView.separatorStyle = .none

        self.headerView.delegate = self
        self.headerView.updateMoreButtonState()
        self.headerView.translatesAutoresizingMaskIntoConstraints = false
        self.wrapperView.addSubview(self.headerView)

        self.sourceTitleLabel.text = "Source"
        self.sourceTitleLabel.font = .systemFont(ofSize: 17)
        self.sourceTitleLabel.textColor = .secondaryLabel

        var configuration = UIButton.Configuration.plain()
        configuration.imagePadding = 4
        configuration.imagePlacement = .trailing
        self.sourceSelectButton.configuration = configuration
        self.sourceSelectButton.setAttributedTitle(
            NSAttributedString(
                string: self.source?.source.name ?? "None",
                attributes: [ .font: UIFont.systemFont(ofSize: 17, weight: .semibold) ]
            ),
            for: .normal
        )
        self.sourceSelectButton.setImage(UIImage(systemName: "chevron.up.chevron.down"), for: .normal)
        self.sourceSelectButton.tintColor = .label
        self.sourceSelectButton.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold),
            forImageIn: .normal
        )
        self.sourceSelectButton.showsMenuAsPrimaryAction = true
        self.sourceSelectButton.menu = UIMenu(children: self.sourceActions)

        self.itemCountLabel.text = "0 \(self.mediaType == .video ? "Episodes" : "Chapters")"
        self.itemCountLabel.font = .systemFont(ofSize: 17, weight: .semibold)

        self.sourceStackView.axis = .horizontal
        self.sourceStackView.isLayoutMarginsRelativeArrangement = true
        self.sourceStackView.layoutMargins = UIEdgeInsets(horizontal: 16)
        self.sourceStackView.addArrangedSubview(self.sourceTitleLabel)
        self.sourceStackView.addArrangedSubview(self.sourceSelectButton)
        self.sourceStackView.addArrangedSubview(self.sourceStackSpacerView)
        self.sourceStackView.addArrangedSubview(self.itemCountLabel)

        self.sourceStackView.translatesAutoresizingMaskIntoConstraints = false
        self.wrapperView.addSubview(self.sourceStackView)

        self.wrapperView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.tableHeaderView = self.wrapperView
    }

    override func applyConstraints() {
        self.headerViewHeightConstraint = self.headerView.heightAnchor.constraint(
            equalTo: self.headerView.widthAnchor,
            multiplier: 1.5,
            constant: 100
        )
        self.headerViewTopConstraint = self.headerView.topAnchor.constraint(equalTo: self.wrapperView.topAnchor)
        NSLayoutConstraint.activate([
            self.headerViewHeightConstraint,
            self.headerViewTopConstraint,
            self.headerView.leadingAnchor.constraint(equalTo: self.tableView.leadingAnchor),
            self.headerView.trailingAnchor.constraint(equalTo: self.tableView.trailingAnchor),
            self.headerView.widthAnchor.constraint(equalTo: self.tableView.widthAnchor),

            self.sourceStackView.topAnchor.constraint(equalTo: self.headerView.bottomAnchor),
            self.sourceStackView.leadingAnchor.constraint(equalTo: self.tableView.leadingAnchor),
            self.sourceStackView.trailingAnchor.constraint(equalTo: self.tableView.trailingAnchor),
            self.sourceStackView.widthAnchor.constraint(equalTo: self.tableView.widthAnchor),
            self.sourceStackView.bottomAnchor.constraint(equalTo: self.wrapperView.bottomAnchor),

            self.wrapperView.leadingAnchor.constraint(equalTo: self.tableView.leadingAnchor),
            self.wrapperView.trailingAnchor.constraint(equalTo: self.tableView.trailingAnchor)
        ])
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        var safeAreaInsets = self.view.safeAreaInsets
        safeAreaInsets.top = 0
        self.tableView.contentInset = safeAreaInsets
    }

    func reloadItems() {
        self.itemLoadTask?.cancel()
        self.itemLoadTask = Task {
            if let source = self.source, let sourceEntry = self.sourceEntry {
                var items: [SourceItem] = []
                switch source.source {
                case let textSource as any TextSource:
                    self.textChapters = await textSource.getChapters(id: source.id)
                    items = self.textChapters.map({ $0.toSourceItem() })
                case let imageSource as any ImageSource:
                    self.imageChapters = await imageSource.getChapters(id: source.id)
                    items = self.imageChapters.map({ $0.toSourceItem() })
                case let videoSource as any VideoSource:
                    self.videoEpisodes = await videoSource.getEpisodes(id: source.id)
                    items = self.videoEpisodes.map({ $0.toSourceItem() })
                default: break
                }

                if let tracker = self.tracker {
                    let trackerItems = await tracker.getItems(mediaType: self.mediaType, id: sourceEntry.id)

                    for trackerItem in trackerItems {
                        if let itemIndex = items.firstIndex(where: { $0.number == trackerItem.number }) {
                            items[itemIndex] = SourceItem(
                                id: items[itemIndex].id,
                                group: items[itemIndex].group,
                                number: items[itemIndex].number,
                                name: items[itemIndex].name ?? trackerItem.name,
                                info: items[itemIndex].info,
                                thumbnail: items[itemIndex].thumbnail ?? trackerItem.thumbnail,
                                timestamp: items[itemIndex].timestamp ?? trackerItem.timestamp,
                                mediaType: items[itemIndex].mediaType
                            )
                        }
                    }
                }

                self.items = items

                updateStartButton()
            }
        }
    }

    func updateStartButton() {
        Task { @MainActor in
            self.headerView.startButton.setImage(
                UIImage(systemName: self.mediaType == .video ? "play.fill" : "book.fill"),
                for: .normal
            )
            let type = self.mediaType == .video ? "Episode" : "Chapter"
            if self.mediaType == .video, let episode = self.history?.episode {
                self.headerView.startButton.setAttributedTitle(
                    NSAttributedString(
                        string: "Continue \(type) \(episode.toTruncatedString())",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                            .foregroundColor: UIColor.black
                        ]
                    ),
                    for: .normal
                )
            } else if self.mediaType != .video, let chapter = self.history?.chapter {
                self.headerView.startButton.setAttributedTitle(
                    NSAttributedString(
                        string: "Continue \(type) \(chapter.toTruncatedString())",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                            .foregroundColor: UIColor.black
                        ]
                    ),
                    for: .normal
                )
            } else if let bottom = self.items.last {
                self.headerView.startButton.setAttributedTitle(
                    NSAttributedString(
                        string: "Start \(type) \(bottom.number.toTruncatedString())",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                            .foregroundColor: UIColor.black
                        ]
                    ),
                    for: .normal
                )
            } else {
                self.headerView.startButton.setAttributedTitle(
                    NSAttributedString(
                        string: "No Content Available",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                            .foregroundColor: UIColor.black
                        ]
                    ),
                    for: .normal
                )
            }
        }
    }
}

// MARK: - EntryViewController + UITableViewDelegate

extension EntryViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.headerView.scrollViewDidScroll(scrollView)

        if tableView.contentOffset.y <= 0 {
            self.headerViewTopConstraint.constant = scrollView.contentOffset.y
            self.headerViewHeightConstraint.constant = 100 - scrollView.contentOffset.y
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let item = self.items[safe: indexPath.item] {
            let shouldDisplayHistory: Bool
            if let history = self.history,
               let number = self.mediaType == .video ? history.episode : history.chapter,
               item.number == number,
               (
                    self.mediaType == .text
                       ? history.percent.flatMap({ Int($0) })
                       : self.mediaType == .image ? history.page : history.timestamp
               ) != nil {
                shouldDisplayHistory = true
            } else {
                shouldDisplayHistory = false
            }
            if item.thumbnail.flatMap({ URL(string: $0) }) != nil {
                return 90 + 16
            } else if item.name == nil {
                if item.timestamp == nil, !shouldDisplayHistory {
                    return item.info == nil ? 42 + 16 : 60 + 16
                } else {
                    return item.info == nil ? 60 + 16 : 78 + 16
                }
            } else {
                return (item.timestamp == nil && !shouldDisplayHistory) ? 60 + 16 : 78 + 16
            }
        } else {
            return 60 + 16
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.source?.source {
        case let textSource as any TextSource:
            self.navigationController?.pushViewController(
                TextReaderViewController(
                    chapters: self.textChapters,
                    chapter: indexPath.item,
                    source: textSource,
                    entry: self.entry,
                    history: self.history
                ),
                animated: true
            )
        case let imageSource as any ImageSource:
            self.navigationController?.pushViewController(
                ImageReaderViewController(
                    source: imageSource,
                    chapters: self.imageChapters,
                    chapterIndex: indexPath.item,
                    entry: self.entry,
                    history: self.history
                ),
                animated: true
            )
        case let videoSource as any VideoSource:
            self.navigationController?.pushViewController(
                VideoPlayerViewController(
                    source: videoSource,
                    episodes: self.videoEpisodes,
                    episodeIndex: indexPath.item,
                    entry: self.entry,
                    history: self.history
                ),
                animated: true
            )
        default: break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - EntryViewController + UITableViewDataSource

extension EntryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EntryItemTableViewCell", for: indexPath)
        if let cell = cell as? EntryItemTableViewCell, let item = self.items[safe: indexPath.item] {
            if let history = self.history, let number = self.mediaType == .video ? history.episode : history.chapter {
                if item.number == number,
                   let progress = (self.mediaType == .text
                                   ? history.percent.flatMap({ Int($0) })
                                   : self.mediaType == .image ? history.page : history.timestamp
                   ) {
                    cell.setItem(to: item, status: .inProgress(progress), mediaType: self.mediaType)
                } else if let index = self.items.firstIndex(where: { $0.number == number }), indexPath.item > index {
                    cell.setItem(to: item, status: .seen, mediaType: self.mediaType)
                } else {
                    cell.setItem(to: item, status: .unseen, mediaType: self.mediaType)
                }
            } else {
                cell.setItem(to: item, mediaType: self.mediaType)
            }
        }
        return cell
    }
}

// MARK: - EntryViewController + EntryHeaderViewDelegate

extension EntryViewController: EntryHeaderViewDelegate {
    var moreButtonMenu: UIMenu? {
        if let entry = self.entry {
            var actions: [UIMenuElement] = [
                UIAction(title: "Settings", image: UIImage(systemName: "gear")) { [weak self] _ in
                    guard let self else { return }
                    self.navigationController?.pushViewController(EntrySettingsViewController(entry: entry), animated: true)
                },
                UIMenu(title: "Status", image: UIImage(systemName: "ellipsis"), children: History.Status.allCases.map({ status in
                    UIAction(
                        title: status.prettyName,
                        image: self.history?.status == status ? UIImage(systemName: "checkmark") : nil
                    ) { [weak self] _ in
                        guard let self else { return }
                        Task {
                            await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [ .status(status) ])
                            if let history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get() {
                                self.history = history
                                await TrackerManager.shared.setHistory(entry: entry, history: history)
                            }
                        }
                    }
                })),
                UIMenu(title: "Score", image: UIImage(systemName: "star"), children: stride(from: 0, through: 10, by: 0.5).map({ score in
                    UIAction(
                        title: score.toTruncatedString(),
                        image: self.history?.score == score ? UIImage(systemName: "checkmark") : nil
                    ) { [weak self] _ in
                        guard let self else { return }
                        Task {
                            await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [ .score(score) ])
                            if let history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get() {
                                self.history = history
                                await TrackerManager.shared.setHistory(entry: entry, history: history)
                            }
                        }
                    }
                })),
                UIMenu(
                    title: "Add to Category",
                    image: UIImage(systemName: "folder.badge.plus"),
                    children: LibraryManager.shared.library(forMediaType: entry.mediaType)?.categories.filter({ category in
                        !category.ids.contains(entry._id)
                    }).map({ category in
                        UIAction(
                            title: category.name,
                            image: LibraryManager.shared.category?.id == category.id ? UIImage(systemName: "checkmark") : nil
                        ) { _ in
                            Task {
                                await SoshikiAPI.shared.addEntryToLibraryCategory(
                                    mediaType: entry.mediaType,
                                    id: category.id,
                                    entryId: entry._id
                                )
                                await LibraryManager.shared.refreshLibraries()
                            }
                        }
                    }) ?? []
                )
            ]
            if let category = LibraryManager.shared.category {
                actions.append(
                    UIAction(
                        title: "Remove from Category",
                        image: UIImage(systemName: "folder.badge.minus"),
                        attributes: .destructive
                    ) { _ in
                        Task {
                            await SoshikiAPI.shared.deleteEntryFromLibraryCategory(
                                mediaType: entry.mediaType,
                                id: category.id,
                                entryId: entry._id
                            )
                            await LibraryManager.shared.refreshLibraries()
                        }
                    }
                )
            }
            actions.append(
                UIAction(title: "Save Cover Image", image: UIImage(systemName: "square.and.arrow.down")) { _ in
                    guard let url = entry.covers.first.flatMap({ URL(string: $0.image) }) else { return }
                    ImagePipeline.shared.loadImage(with: url) { result in
                        if case .success(let response) = result {
                            UIImageWriteToSavedPhotosAlbum(response.image, nil, nil, nil)
                        }
                    }
                }
            )
            return UIMenu(children: actions)
        } else {
            return nil
        }
    }

    func startButtonPressed() {
        guard !self.items.isEmpty else { return }

        switch self.source?.source {
        case let textSource as any TextSource:
            self.navigationController?.pushViewController(
                TextReaderViewController(
                    chapters: self.textChapters,
                    chapter: self.history?.chapter.flatMap({ chapter in
                        self.textChapters.firstIndex(where: { $0.chapter == chapter })
                    }) ?? self.textChapters.count - 1,
                    source: textSource,
                    entry: self.entry,
                    history: self.history
                ),
                animated: true
            )
        case let imageSource as any ImageSource:
            self.navigationController?.pushViewController(
                ImageReaderViewController(
                    source: imageSource,
                    chapters: self.imageChapters,
                    chapterIndex: self.history?.chapter.flatMap({ chapter in
                        self.imageChapters.firstIndex(where: { $0.chapter == chapter })
                    }) ?? self.imageChapters.count - 1,
                    entry: self.entry,
                    history: self.history
                ),
                animated: true
            )
        case let videoSource as any VideoSource:
            self.navigationController?.pushViewController(
                VideoPlayerViewController(
                    source: videoSource,
                    episodes: self.videoEpisodes,
                    episodeIndex: self.history?.episode.flatMap({ episode in
                        self.videoEpisodes.firstIndex(where: { $0.episode == episode })
                    }) ?? self.videoEpisodes.count - 1,
                    entry: self.entry,
                    history: self.history
                ),
                animated: true
            )
        default: break
        }
    }

    func closeButtonPressed() {
        self.navigationController?.popViewController(animated: true)
    }

    func libraryButtonPressed() {
        if let entry = self.entry {
            if self.libraryAddTask == nil {
                self.libraryAddTask = Task {
                    if self.isInLibrary {
                        await LibraryManager.shared.remove(entry: entry)
                    } else {
                        await LibraryManager.shared.add(entry: entry)
                    }
                    self.libraryAddTask = nil
                }
            }
        } else if let source = self.source?.source, let entry = self.sourceEntry { // must be a link press
            self.navigationController?.pushViewController(
                LinkViewController(source: source, entry: entry),
                animated: true
            )
        }
    }

    func webviewButtonPressed() {
        if let url = (self.sourceEntry?.url).flatMap({ URL(string: $0) }) {
            self.present(SFSafariViewController(url: url), animated: true)
        }
    }

    func trackerButtonPressed() {
        if let entry = self.entry {
            self.navigationController?.pushViewController(EntryTrackersViewController(entry: entry), animated: true)
        }
    }
}
