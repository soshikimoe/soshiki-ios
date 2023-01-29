//
//  EntryViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/26/23.
//

import UIKit
import Nuke

class EntryViewController: UITableViewController {
    let entry: Entry
    let sources: [any Source]
    var source: (any Source)?
    var history: History?

    let entryHeaderView: EntryHeaderView

    var textChapters: [TextSourceChapter] = []
    var imageChapters: [ImageSourceChapter] = []
    var videoEpisodes: [VideoSourceEpisode] = []

    lazy var settingsMenu = {
        var actions: [UIMenuElement] = [
            UIAction(title: "Trackers", image: UIImage(systemName: "location.fill")) { [weak self] _ in
                guard let self else { return }
                self.navigationController?.pushViewController(EntryTrackersViewController(entry: self.entry), animated: true)
            },
            UIMenu(title: "Status", image: UIImage(systemName: "ellipsis"), children: History.Status.allCases.map({ status in
                UIAction(
                    title: status.prettyName,
                    image: self.history?.status == status ? UIImage(systemName: "checkmark") : nil
                ) { [weak self] _ in
                    guard let self else { return }
                    Task {
                        await SoshikiAPI.shared.setHistory(mediaType: self.entry.mediaType, id: self.entry._id, query: [ .status(status) ])
                        if let history = try? await SoshikiAPI.shared.getHistory(mediaType: self.entry.mediaType, id: self.entry._id).get() {
                            self.history = history
                            await TrackerManager.shared.setHistory(entry: self.entry, history: history)
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
                        await SoshikiAPI.shared.setHistory(mediaType: self.entry.mediaType, id: self.entry._id, query: [ .score(score) ])
                        if let history = try? await SoshikiAPI.shared.getHistory(mediaType: self.entry.mediaType, id: self.entry._id).get() {
                            self.history = history
                            await TrackerManager.shared.setHistory(entry: self.entry, history: history)
                        }
                    }
                }
            })),
            UIMenu(
                title: "Add to Category",
                image: UIImage(systemName: "folder.badge.plus"),
                children: LibraryManager.shared.library(forMediaType: self.entry.mediaType)?.categories.filter({ category in
                    !category.ids.contains(self.entry._id)
                }).map({ category in
                    UIAction(
                        title: category.name,
                        image: LibraryManager.shared.category?.id == category.id ? UIImage(systemName: "checkmark") : nil
                    ) { [weak self] _ in
                        guard let self else { return }
                        Task {
                            await SoshikiAPI.shared.addEntryToLibraryCategory(
                                mediaType: self.entry.mediaType,
                                id: category.id,
                                entryId: self.entry._id
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
                ) { [weak self] _ in
                    guard let self else { return }
                    Task {
                        await SoshikiAPI.shared.deleteEntryFromLibraryCategory(
                            mediaType: self.entry.mediaType,
                            id: category.id,
                            entryId: self.entry._id
                        )
                        await LibraryManager.shared.refreshLibraries()
                    }
                }
            )
        }
        actions.append(contentsOf: [
            UIAction(title: "Save Cover Image", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] _ in
                guard let self, let url = self.entry.covers.first.flatMap({ URL(string: $0.image) }) else { return }
                ImagePipeline.shared.loadImage(with: url) { result in
                    if case .success(let response) = result {
                        UIImageWriteToSavedPhotosAlbum(response.image, nil, nil, nil)
                    }
                }
            },
            UIAction(title: "Remove from Library", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                guard let self else { return }
                Task {
                    await SoshikiAPI.shared.deleteEntryFromLibrary(mediaType: self.entry.mediaType, entryId: self.entry._id)
                    await LibraryManager.shared.refresh()
                }
            }
        ])
        return UIMenu(children: actions)
    }()

    init(entry: Entry) {
        self.entry = entry
        self.entryHeaderView = EntryHeaderView(mediaType: entry.mediaType)
        self.entryHeaderView.setEntry(to: entry.toLocalEntry(), with: entry)

        switch entry.mediaType {
        case .text:
            self.sources = entry.platforms.first(where: { $0.id == "soshiki" })?.sources.compactMap({ source in
                SourceManager.shared.textSources.first(where: { $0.id == source.id })
            }) ?? []
        case .image:
            self.sources = entry.platforms.first(where: { $0.id == "soshiki" })?.sources.compactMap({ source in
                SourceManager.shared.imageSources.first(where: { $0.id == source.id })
            }) ?? []
        case .video:
            self.sources = entry.platforms.first(where: { $0.id == "soshiki" })?.sources.compactMap({ source in
                SourceManager.shared.videoSources.first(where: { $0.id == source.id })
            }) ?? []
        }
        self.source = sources.first

        super.init(style: .plain)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "UITableViewHeaderFooterView")

        self.navigationItem.largeTitleDisplayMode = .never

        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.tableHeaderView = headerView

        entryHeaderView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(entryHeaderView)
        entryHeaderView.widthAnchor.constraint(equalTo: self.tableView.widthAnchor).isActive = true

        headerView.widthAnchor.constraint(equalTo: self.tableView.widthAnchor).isActive = true
        headerView.heightAnchor.constraint(equalTo: entryHeaderView.heightAnchor).isActive = true

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        self.tableView.refreshControl = refreshControl

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), menu: settingsMenu)

        self.entryHeaderView.continueAction = { [weak self] in
            if let history = self?.history {
                switch self?.source {
                case is any TextSource:
                    if let index = self?.textChapters.firstIndex(where: { $0.chapter == history.chapter && $0.volume == history.volume }) {
                        self?.openViewer(to: index)
                    }
                case is any ImageSource:
                    if let index = self?.imageChapters.firstIndex(where: { $0.chapter == history.chapter && $0.volume == history.volume }) {
                        self?.openViewer(to: index)
                    }
                case is any TextSource:
                    if let index = self?.videoEpisodes.firstIndex(where: { $0.episode == history.episode }) {
                        self?.openViewer(to: index)
                    }
                default:
                    break
                }
            }
        }
        self.entryHeaderView.linkUrl = (self.entry.links.first?.url).flatMap({ URL(string: $0) })

        Task {
            self.history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get()
            self.entryHeaderView.canContinue = entry.mediaType == .video ? history?.episode != nil : history?.chapter != nil
            self.tableView.reloadData()
        }

        self.refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func refresh(_ sender: UIRefreshControl? = nil) {
        Task {
            guard let source else { return }
            if let id = entry.platforms.first(where: { $0.id == "soshiki" })?.sources.first(where: { $0.id == source.id })?.entryId {
                switch source {
                case let source as any TextSource:
                    self.textChapters = await source.getChapters(id: id)
                case let source as any ImageSource:
                    self.imageChapters = await source.getChapters(id: id)
                case let source as any VideoSource:
                    self.videoEpisodes = await source.getEpisodes(id: id)
                default: break
                }
                self.history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get()
                self.entryHeaderView.canContinue = entry.mediaType == .video ? history?.episode != nil : history?.chapter != nil
                self.tableView.reloadData()
            }
            sender?.endRefreshing()
        }
    }

    func openViewer(to index: Int) {
        switch source {
        case let source as any TextSource:
            if textChapters.indices.contains(index) {
                navigationController?.pushViewController(
                    TextReaderViewController(
                        chapters: textChapters,
                        chapter: index,
                        source: source,
                        entry: entry,
                        history: history),
                    animated: true
                )
            }
        case let source as any ImageSource:
            if imageChapters.indices.contains(index) {
                navigationController?.pushViewController(
                    ImageReaderViewController(
                        chapters: imageChapters,
                        chapter: index,
                        source: source,
                        entry: entry,
                        history: history
                    ),
                    animated: true
                )
            }
        case let source as any VideoSource:
            if videoEpisodes.indices.contains(index) {
                navigationController?.pushViewController(
                    VideoPlayerViewController(
                        episodes: videoEpisodes,
                        episode: index,
                        source: source,
                        entry: entry,
                        history: history
                    ),
                    animated: true
                )
            }
        default:
            break
        }
    }
}

extension EntryViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entry.mediaType == .text ? textChapters.count : entry.mediaType == .image ? imageChapters.count : videoEpisodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        var seen = false
        switch entry.mediaType {
        case .text:
            if let chapter = textChapters[safe: indexPath.item] {
                content.text = chapter.toListString()
                var components: [String] = []
                if let translator = chapter.translator {
                    components.append(translator)
                }
                if history?.chapter ?? -1 > chapter.chapter && history?.volume ?? -1 > chapter.volume ?? -1 {
                    seen = true
                } else if history?.chapter == chapter.chapter && history?.volume == chapter.volume {
                    if let percent = history?.percent {
                        components.append("\(percent.toTruncatedString()) percent read")
                    } else {
                        seen = true
                    }
                }
                content.secondaryText = components.joined(separator: " • ")
            }
        case .image:
            if let chapter = imageChapters[safe: indexPath.item] {
                content.text = chapter.toListString()
                var components: [String] = []
                if let translator = chapter.translator {
                    components.append(translator)
                }
                if history?.chapter ?? -1 > chapter.chapter && history?.volume ?? -1 > chapter.volume ?? -1 {
                    seen = true
                } else if history?.chapter == chapter.chapter && history?.volume == chapter.volume {
                    if let page = history?.page {
                        components.append("\(page) pages read")
                    } else {
                        seen = true
                    }
                }
                content.secondaryText = components.joined(separator: " • ")
            }
        case .video:
            if let episode = videoEpisodes[safe: indexPath.item] {
                content.text = episode.toListString()
                var components: [String] = [episode.type.rawValue.capitalized]
                if history?.episode ?? -1 > episode.episode {
                    seen = true
                } else if history?.episode == episode.episode {
                    if let timestamp = history?.timestamp {
                        components.append("\(timestamp.toMinuteSecondString()) watched")
                    } else {
                        seen = true
                    }
                }
                content.secondaryText = components.joined(separator: " • ")
            }
        }
        content.textProperties.font = .systemFont(ofSize: 17, weight: .bold)
        if seen {
            content.textProperties.color = .secondaryLabel
        }
        content.secondaryTextProperties.font = .systemFont(ofSize: 15)
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView") else { return nil }
        var content = cell.defaultContentConfiguration()
        switch entry.mediaType {
        case .text:
            content.text = "\(textChapters.count) Chapters"
        case .image:
            content.text = "\(imageChapters.count) Chapters"
        case .video:
            content.text = "\(videoEpisodes.count) Episodes"
        }
        content.textProperties.font = .systemFont(ofSize: 17, weight: .bold)
        content.textProperties.color = .label

        let actions = sources.map({ source in
            UIAction(title: source.name, image: self.source?.id == source.id ? UIImage(systemName: "checkmark") : nil) { [weak self] _ in
                self?.source = source
                self?.refresh()
            }
        })
        let titleLabel = UILabel()
        titleLabel.text = "Source"
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let sourceLabel = UILabel()
        sourceLabel.text = self.source?.name ?? "None"
        sourceLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        let sourceButton = UIButton()
        sourceButton.setImage(UIImage(systemName: "chevron.up.chevron.down"), for: .normal)
        sourceButton.showsMenuAsPrimaryAction = true
        sourceButton.menu = UIMenu(children: actions)
        sourceButton.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(titleLabel)
        cell.contentView.addSubview(sourceLabel)
        cell.contentView.addSubview(sourceButton)
        sourceButton.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        sourceButton.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor).isActive = true
        sourceLabel.trailingAnchor.constraint(equalTo: sourceButton.leadingAnchor, constant: -5).isActive = true
        sourceLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: sourceLabel.leadingAnchor, constant: -5).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor).isActive = true

        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.openViewer(to: indexPath.item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
