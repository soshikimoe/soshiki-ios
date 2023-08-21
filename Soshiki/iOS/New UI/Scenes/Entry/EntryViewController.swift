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
    var entry: any Entry

    var libraryItem: LibraryItem? {
        didSet {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: buildMoreMenu())
        }
    }

    var history: (any History)? {
        didSet {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: buildMoreMenu())
            updateStartButton()
            self.tableView.reloadData()
        }
    }

    var mediaType: MediaType {
        self.source is any TextSource ? .text : self.source is any ImageSource ? .image : .video
    }

    var source: any Source

    var textChapters: [TextSourceChapter]
    var imageChapters: [ImageSourceChapter]
    var videoEpisodes: [VideoSourceEpisode]

    var itemPage: Int
    var hasMore: Bool

    var itemLoadTask: Task<Void, Never>?

    // MARK: Views
    let headerView: EntryHeaderView

    let wrapperView: UIView

    let tableView: UITableView

    let sourceTitleLabel: UILabel
    let sourceStackSpacerView: UIView
    let itemCountLabel: UILabel
    let sourceStackView: UIStackView

    // MARK: Miscellaneous

    var isLandscape: Bool {
        self.view.frame.width > self.view.frame.height
    }

    override var prefersStatusBarHidden: Bool { true }

    init(entry: any Entry, source: any Source, libraryItem: LibraryItem? = nil) {
        self.entry = entry
        self.source = source
        self.libraryItem = libraryItem

        self.headerView = EntryHeaderView()

        self.wrapperView = UIView()

        self.tableView = UITableView(frame: .zero, style: .plain)

        self.textChapters = []
        self.imageChapters = []
        self.videoEpisodes = []

        self.itemPage = 1
        self.hasMore = false

        self.sourceTitleLabel = UILabel()
        self.sourceStackSpacerView = UIView()
        self.itemCountLabel = UILabel()
        self.sourceStackView = UIStackView()

        super.init()

        self.history = DataManager.shared.getHistory(self.entry)

        self.headerView.setEntry(to: entry)

        reloadEntry()
        reloadItems()

        self.libraryItem = DataManager.shared.getLibraryItems(ofType: self.mediaType).first(where: {
            $0.sourceId == self.entry.sourceId && $0.id == self.entry.id
        })
        if self.libraryItem != nil {
            self.headerView.libraryButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
        } else {
            self.headerView.libraryButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        }

        super.addObserver(LibraryManager.Keys.libraries) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.libraryItem = DataManager.shared.getLibraryItems(ofType: self.mediaType).first(where: {
                    $0.sourceId == self.entry.sourceId && $0.id == self.entry.id
                })
                if self.libraryItem != nil {
                    self.headerView.libraryButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
                } else {
                    self.headerView.libraryButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
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

    override func configureViews() {
        self.navigationItem.largeTitleDisplayMode = .never

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(EntryItemTableViewCell.self, forCellReuseIdentifier: "EntryItemTableViewCell")
        self.tableView.contentInset = UIEdgeInsets(all: 16)
        self.tableView.separatorStyle = .none

        self.headerView.delegate = self
        self.headerView.translatesAutoresizingMaskIntoConstraints = false
        self.wrapperView.addSubview(self.headerView)

        self.sourceTitleLabel.text = self.source.name
        self.sourceTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)

        self.itemCountLabel.text = "0 \(self.mediaType == .video ? "Episodes" : "Chapters")"
        self.itemCountLabel.font = .systemFont(ofSize: 17, weight: .semibold)

        self.sourceStackView.axis = .horizontal
        self.sourceStackView.isLayoutMarginsRelativeArrangement = true
        self.sourceStackView.layoutMargins = UIEdgeInsets(horizontal: 16)
        self.sourceStackView.addArrangedSubview(self.sourceTitleLabel)
        self.sourceStackView.addArrangedSubview(self.sourceStackSpacerView)
        self.sourceStackView.addArrangedSubview(self.itemCountLabel)

        self.sourceStackView.translatesAutoresizingMaskIntoConstraints = false
        self.wrapperView.addSubview(self.sourceStackView)

        self.wrapperView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.tableHeaderView = self.wrapperView

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: buildMoreMenu())
    }

    override func applyConstraints() {
        NSLayoutConstraint.activate([
            self.headerView.heightAnchor.constraint(equalTo: self.headerView.widthAnchor, multiplier: 1.5),
            self.headerView.topAnchor.constraint(equalTo: self.wrapperView.topAnchor),
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

    func reloadEntry() {
        Task {
            if let entry = await source.getEntry(id: entry.id) {
                self.entry = entry
                self.headerView.setEntry(to: entry)
            }
        }
    }

    func reloadItems() {
        self.itemLoadTask?.cancel()
        self.textChapters = []
        self.imageChapters = []
        self.videoEpisodes = []
        loadItems(page: 1)
    }

    func updateStartButton() {
        Task { @MainActor in
            self.headerView.startButton.setImage(
                UIImage(systemName: self.mediaType == .video ? "play.fill" : "book.fill"),
                for: .normal
            )
            let type = self.mediaType == .video ? "Episode" : "Chapter"
            if let episode = (self.history as? VideoHistory)?.episode {
                self.headerView.startButton.setAttributedTitle(
                    NSAttributedString(
                        string: "Continue \(type) \(episode.toTruncatedString())",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                            .foregroundColor: UIColor.systemBackground
                        ]
                    ),
                    for: .normal
                )
            } else if let chapter = (self.history as? TextHistory)?.chapter ?? (self.history as? ImageHistory)?.chapter {
                self.headerView.startButton.setAttributedTitle(
                    NSAttributedString(
                        string: "Continue \(type) \(chapter.toTruncatedString())",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                            .foregroundColor: UIColor.systemBackground
                        ]
                    ),
                    for: .normal
                )
            } else if let bottom = self.mediaType == .text
                        ? self.textChapters.last?.chapter
                        : self.mediaType == .image ? self.imageChapters.last?.chapter : self.videoEpisodes.last?.episode {
                self.headerView.startButton.setAttributedTitle(
                    NSAttributedString(
                        string: "Start \(type) \(bottom.toTruncatedString())",
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                            .foregroundColor: UIColor.systemBackground
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
                            .foregroundColor: UIColor.systemBackground
                        ]
                    ),
                    for: .normal
                )
            }
        }
    }

    func buildMoreMenu() -> UIMenu {
        var actions: [UIMenuElement] = [
            UIAction(title: "Settings", image: UIImage(systemName: "gear")) { [weak self] _ in
                guard let self else { return }
                self.navigationController?.pushViewController(EntrySettingsViewController(entry: self.entry), animated: true)
            }
        ]
        if let libraryItem = self.libraryItem {
            actions.append(contentsOf: [
                UIMenu(
                    title: "Add to Category",
                    image: UIImage(systemName: "folder.badge.plus"),
                    children: DataManager.shared.getLibraryCategories(ofType: self.mediaType).filter({ category in
                        !libraryItem.categories.contains(category.id)
                    }).map({ category in
                        UIAction(title: category.name) { [weak self] _ in
                            guard let self else { return }
                            DataManager.shared.addLibraryItems([ self.entry ], ofType: self.mediaType, to: category.id)
                        }
                    })
                ),
                UIMenu(
                    title: "Remove from Category",
                    image: UIImage(systemName: "folder.badge.minus"),
                    children: DataManager.shared.getLibraryCategories(ofType: self.mediaType).filter({ category in
                        libraryItem.categories.contains(category.id)
                    }).map({ category in
                        UIAction(title: category.name) { [weak self] _ in
                            guard let self else { return }
                            DataManager.shared.removeLibraryItems([ self.entry ], ofType: self.mediaType, from: category.id)
                        }
                    })
                ),
                UIAction(
                    title: "Remove from Library",
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive
                ) { [weak self] _ in
                    guard let self else { return }
                    DataManager.shared.removeLibraryItems([ self.entry ], ofType: self.mediaType)
                    switch self.entry {
                    case let entry as TextEntry: DataManager.shared.removeEntries([ entry ])
                    case let entry as ImageEntry: DataManager.shared.removeEntries([ entry ])
                    case let entry as VideoEntry: DataManager.shared.removeEntries([ entry ])
                    default: break
                    }
                    NotificationCenter.default.post(name: .init(LibraryManager.Keys.libraries), object: nil)
                }
            ])
        } else {
            actions.append(contentsOf: [
                UIAction(
                    title: "Add to Library",
                    image: UIImage(systemName: "bookmark")
                ) { [weak self] _ in
                    guard let self else { return }
                    DataManager.shared.addLibraryItems([ self.entry ], ofType: self.mediaType)
                    switch self.entry {
                    case let entry as TextEntry: DataManager.shared.addEntries([ entry ])
                    case let entry as ImageEntry: DataManager.shared.addEntries([ entry ])
                    case let entry as VideoEntry: DataManager.shared.addEntries([ entry ])
                    default: break
                    }
                    NotificationCenter.default.post(name: .init(LibraryManager.Keys.libraries), object: nil)
                }
            ])
        }

        if let history = self.history {
            actions.append(contentsOf: [
                UIMenu(title: "Status", image: UIImage(systemName: "ellipsis"), children: HistoryStatus.allCases.map({ status in
                    UIAction(
                        title: status.prettyName,
                        image: history.status == status ? UIImage(systemName: "checkmark") : nil
                    ) { [weak self] _ in
                        guard var history = self?.history else { return }
                        history.status = status
                        DataManager.shared.setHistory(history)
                    }
                })),
                UIMenu(title: "Score", image: UIImage(systemName: "star"), children: stride(from: 0, through: 10, by: 0.5).map({ score in
                    UIAction(
                        title: score.toTruncatedString(),
                        image: history.score == score ? UIImage(systemName: "checkmark") : nil
                    ) { [weak self] _ in
                        guard var history = self?.history else { return }
                        history.score = score
                        DataManager.shared.setHistory(history)
                    }
                }))
            ])
        }
        actions.append(
            UIAction(title: "Save Cover Image", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] _ in
                guard let url = self?.entry.cover.flatMap({ URL(string: $0) }) else { return }
                ImagePipeline.shared.loadImage(with: url) { result in
                    if case .success(let response) = result {
                        UIImageWriteToSavedPhotosAlbum(response.image, nil, nil, nil)
                    }
                }
            }
        )
        return UIMenu(children: actions)
    }

    func loadItems(page: Int) {
        self.itemLoadTask = Task {
            let itemCount: Int
            switch source {
            case let textSource as any TextSource:
                if let results = await textSource.getChapters(id: self.entry.id, page: page) {
                    self.itemPage = results.page
                    self.hasMore = results.hasMore
                    self.textChapters.append(contentsOf: results.results)
                } else {
                    self.hasMore = false
                }
                itemCount = self.textChapters.count
            case let imageSource as any ImageSource:
                if let results = await imageSource.getChapters(id: self.entry.id, page: page) {
                    self.itemPage = results.page
                    self.hasMore = results.hasMore
                    self.imageChapters.append(contentsOf: results.results)
                } else {
                    self.hasMore = false
                }
                itemCount = self.imageChapters.count
            case let videoSource as any VideoSource:
                if let results = await videoSource.getEpisodes(id: self.entry.id, page: page) {
                    self.itemPage = results.page
                    self.hasMore = results.hasMore
                    self.videoEpisodes.append(contentsOf: results.results)
                } else {
                    self.hasMore = false
                }
                itemCount = self.videoEpisodes.count
            default:
                itemCount = 0
            }

            self.tableView.reloadData()
            updateStartButton()
            self.itemCountLabel.text = "\(itemCount) \(self.mediaType == .video ? "Episodes" : "Chapters")"
            self.itemLoadTask = nil
        }
    }
}

// MARK: - EntryViewController + UITableViewDelegate

extension EntryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let number: Double
        let thumbnail: String?
        let name: String?
        let timestamp: Double?
        let info: String?

        if self.mediaType == .text {
            number = self.textChapters[indexPath.item].chapter
            thumbnail = self.textChapters[indexPath.item].thumbnail
            name = self.textChapters[indexPath.item].name
            timestamp = self.textChapters[indexPath.item].timestamp
            info = self.textChapters[indexPath.item].translator
        } else if self.mediaType == .image {
            number = self.imageChapters[indexPath.item].chapter
            thumbnail = self.imageChapters[indexPath.item].thumbnail
            name = self.imageChapters[indexPath.item].name
            timestamp = self.imageChapters[indexPath.item].timestamp
            info = self.imageChapters[indexPath.item].translator
        } else {
            number = self.videoEpisodes[indexPath.item].episode
            thumbnail = self.videoEpisodes[indexPath.item].thumbnail
            name = self.videoEpisodes[indexPath.item].name
            timestamp = self.videoEpisodes[indexPath.item].timestamp
            info = self.videoEpisodes[indexPath.item].type.rawValue.capitalized
        }

        let shouldDisplayHistory: Bool
        if let history = self.history,
           let historyNumber = (history as? TextHistory)?.chapter
                ?? (history as? ImageHistory)?.chapter
                ?? (history as? VideoHistory)?.episode,
           number == historyNumber,
           (
                (history as? TextHistory)?.percent
                ?? (history as? ImageHistory).flatMap({ Double($0.page) })
                ?? (history as? VideoHistory)?.timestamp
           ) != nil {
            shouldDisplayHistory = true
        } else {
            shouldDisplayHistory = false
        }
        if thumbnail.flatMap({ URL(string: $0) }) != nil {
            return 90 + 16
        } else if name == nil {
            if timestamp == nil, !shouldDisplayHistory {
                return info == nil ? 42 + 16 : 60 + 16
            } else {
                return info == nil ? 60 + 16 : 78 + 16
            }
        } else {
            return (timestamp == nil && !shouldDisplayHistory) ? 60 + 16 : 78 + 16
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.source {
        case let textSource as any TextSource:
            guard let entry = self.entry as? TextEntry else { break }
            self.navigationController?.pushViewController(
                TextReaderViewController(
                    source: textSource,
                    entry: entry,
                    chapters: self.textChapters,
                    chapter: indexPath.item,
                    history: self.history as? TextHistory
                ),
                animated: true
            )
        case let imageSource as any ImageSource:
            guard let entry = self.entry as? ImageEntry else { break }
            self.navigationController?.pushViewController(
                ImageReaderViewController(
                    source: imageSource,
                    entry: entry,
                    chapters: self.imageChapters,
                    chapterIndex: indexPath.item,
                    history: self.history as? ImageHistory
                ),
                animated: true
            )
        case let videoSource as any VideoSource:
            guard let entry = self.entry as? VideoEntry else { break }
            self.navigationController?.pushViewController(
                VideoPlayerViewController(
                    source: videoSource,
                    entry: entry,
                    episodes: self.videoEpisodes,
                    episodeIndex: indexPath.item,
                    history: self.history as? VideoHistory
                ),
                animated: true
            )
        default: break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.hasMore, self.itemLoadTask == nil, scrollView.contentSize.height - view.bounds.height - scrollView.contentOffset.y < 500 {
            loadItems(page: itemPage + 1)
        }
    }
}

// MARK: - EntryViewController + UITableViewDataSource

extension EntryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.mediaType == .text ? self.textChapters.count : self.mediaType == .image ? self.imageChapters.count : self.videoEpisodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EntryItemTableViewCell", for: indexPath)
        if let cell = cell as? EntryItemTableViewCell {
            if self.mediaType == .text, let item = self.textChapters[safe: indexPath.item] {
                if let history = self.history as? TextHistory {
                    if item.chapter == history.chapter {
                        cell.setItem(to: item, status: .inProgress(Int(history.percent)))
                    } else if let index = self.textChapters.firstIndex(where: { $0.chapter == history.chapter }), indexPath.item > index {
                        cell.setItem(to: item, status: .seen)
                    } else {
                        cell.setItem(to: item, status: .unseen)
                    }
                } else {
                    cell.setItem(to: item)
                }
            }
            if self.mediaType == .image, let item = self.imageChapters[safe: indexPath.item] {
                if let history = self.history as? ImageHistory {
                    if item.chapter == history.chapter {
                        cell.setItem(to: item, status: .inProgress(history.page))
                    } else if let index = self.imageChapters.firstIndex(where: { $0.chapter == history.chapter }), indexPath.item > index {
                        cell.setItem(to: item, status: .seen)
                    } else {
                        cell.setItem(to: item, status: .unseen)
                    }
                } else {
                    cell.setItem(to: item)
                }
            }
            if self.mediaType == .video, let item = self.videoEpisodes[safe: indexPath.item] {
                if let history = self.history as? VideoHistory {
                    if item.episode == history.episode {
                        cell.setItem(to: item, status: .inProgress(Int(history.timestamp)))
                    } else if let index = self.videoEpisodes.firstIndex(where: { $0.episode == history.episode }), indexPath.item > index {
                        cell.setItem(to: item, status: .seen)
                    } else {
                        cell.setItem(to: item, status: .unseen)
                    }
                } else {
                    cell.setItem(to: item)
                }
            }
        }
        return cell
    }
}

// MARK: - EntryViewController + EntryHeaderViewDelegate

extension EntryViewController: EntryHeaderViewDelegate {
    func startButtonPressed() {
        switch self.source {
        case let textSource as any TextSource:
            guard !self.textChapters.isEmpty, let entry = self.entry as? TextEntry else { return }
            self.navigationController?.pushViewController(
                TextReaderViewController(
                    source: textSource,
                    entry: entry,
                    chapters: self.textChapters,
                    chapter: (self.history as? TextHistory).flatMap({ history in
                        self.textChapters.firstIndex(where: { $0.chapter == history.chapter })
                    }) ?? self.textChapters.count - 1,
                    history: self.history as? TextHistory
                ),
                animated: true
            )
        case let imageSource as any ImageSource:
            guard !self.imageChapters.isEmpty, let entry = self.entry as? ImageEntry else { return }
            self.navigationController?.pushViewController(
                ImageReaderViewController(
                    source: imageSource,
                    entry: entry,
                    chapters: self.imageChapters,
                    chapterIndex: (self.history as? ImageHistory).flatMap({ history in
                        self.imageChapters.firstIndex(where: { $0.chapter == history.chapter })
                    }) ?? self.imageChapters.count - 1,
                    history: self.history as? ImageHistory
                ),
                animated: true
            )
        case let videoSource as any VideoSource:
            guard !self.videoEpisodes.isEmpty, let entry = self.entry as? VideoEntry else { return }
            self.navigationController?.pushViewController(
                VideoPlayerViewController(
                    source: videoSource,
                    entry: entry,
                    episodes: self.videoEpisodes,
                    episodeIndex: (self.history as? VideoHistory).flatMap({ history in
                        self.videoEpisodes.firstIndex(where: { $0.episode == history.episode })
                    }) ?? self.videoEpisodes.count - 1,
                    history: self.history as? VideoHistory
                ),
                animated: true
            )
        default: break
        }
    }

    func libraryButtonPressed() {
        if self.libraryItem != nil {
            DataManager.shared.removeLibraryItems([ self.entry ], ofType: self.mediaType)
            switch self.entry {
            case let entry as TextEntry: DataManager.shared.removeEntries([ entry ])
            case let entry as ImageEntry: DataManager.shared.removeEntries([ entry ])
            case let entry as VideoEntry: DataManager.shared.removeEntries([ entry ])
            default: break
            }
        } else {
            DataManager.shared.addLibraryItems([ self.entry ], ofType: self.mediaType)
            switch self.entry {
            case let entry as TextEntry: DataManager.shared.addEntries([ entry ])
            case let entry as ImageEntry: DataManager.shared.addEntries([ entry ])
            case let entry as VideoEntry: DataManager.shared.addEntries([ entry ])
            default: break
            }
        }
        NotificationCenter.default.post(name: .init(LibraryManager.Keys.libraries), object: nil)
    }

    func webviewButtonPressed() {
        if let url = self.entry.links.first.flatMap({ URL(string: $0) }) {
            self.present(SFSafariViewController(url: url), animated: true)
        }
    }

    func trackerButtonPressed() {
//        if let entry = self.entry {
//            self.navigationController?.pushViewController(EntryTrackersViewController(entry: entry), animated: true)
//        }
    }
}
