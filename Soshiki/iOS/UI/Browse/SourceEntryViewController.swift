//
//  SourceEntryViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/28/23.
//

import UIKit
import SafariServices

class SourceEntryViewController: UITableViewController {
    var observers: [NSObjectProtocol] = []

    let sourceShortEntry: SourceShortEntry
    let source: any Source
    var sourceEntry: SourceEntry?
    var entry: Entry?
    var history: History?

    let entryHeaderView: EntryHeaderView

    var textChapters: [TextSourceChapter] = []
    var imageChapters: [ImageSourceChapter] = []
    var videoEpisodes: [VideoSourceEpisode] = []

    init(sourceShortEntry: SourceShortEntry, source: any Source) {
        self.sourceShortEntry = sourceShortEntry
        self.source = source
        self.entryHeaderView = EntryHeaderView(mediaType: source is any TextSource ? .text : source is any ImageSource ? .image : .video)
        self.entryHeaderView.setEntry(to: sourceShortEntry.toLocalEntry())
        super.init(style: .plain)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "UITableViewHeaderFooterView")

        self.navigationItem.largeTitleDisplayMode = .never

        Task {
            switch source {
            case let source as any TextSource:
                self.textChapters = await source.getChapters(id: sourceShortEntry.id)
            case let source as any ImageSource:
                self.imageChapters = await source.getChapters(id: sourceShortEntry.id)
            case let source as any VideoSource:
                self.videoEpisodes = await source.getEpisodes(id: sourceShortEntry.id)
            default: break
            }
            self.tableView.reloadData()
        }

        self.entryHeaderView.delegate = self

        observers.append(
            NotificationCenter.default.addObserver(forName: .init("app.link.update"), object: nil, queue: nil) { [weak self] notification in
                guard let self, let id = notification.object as? String, sourceShortEntry.id == id else { return }
                Task {
                    self.entry = (try? await SoshikiAPI.shared.getLink(
                        mediaType: self.source is any TextSource ? .text : self.source is any ImageSource ? .image : .video,
                        platformId: "soshiki",
                        sourceId: self.source.id,
                        entryId: self.sourceShortEntry.id
                    ).get())?.first
                    if let sourceEntry = self.sourceEntry, let entry = self.entry {
                        self.entryHeaderView.setEntry(to: sourceEntry.toLocalEntry(), with: entry)
                    }
                }
            }
        )

        Task {
            self.sourceEntry = await source.getEntry(id: sourceShortEntry.id)
            guard let sourceEntry else { return }
            self.entry = (try? await SoshikiAPI.shared.getLink(
                mediaType: source is any TextSource ? .text : source is any ImageSource ? .image : .video,
                platformId: "soshiki",
                sourceId: source.id,
                entryId: sourceEntry.id
            ).get())?.first
            if let entry {
                self.history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get()
                if let currentItem = source is any VideoSource ? history?.episode : history?.chapter {
                    self.entryHeaderView.setContinueButtonText(
                        to: "Continue \(source is any VideoSource ? "Episode" : "Chapter") \(currentItem.toTruncatedString())"
                    )
                }
                self.tableView.reloadData()
            }
            self.entryHeaderView.setEntry(to: sourceEntry.toLocalEntry(), with: self.entry, history: self.history)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.tableHeaderView = headerView

        entryHeaderView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(entryHeaderView)
        entryHeaderView.widthAnchor.constraint(equalTo: self.tableView.widthAnchor).isActive = true

        headerView.widthAnchor.constraint(equalTo: self.tableView.widthAnchor).isActive = true
        headerView.heightAnchor.constraint(equalTo: entryHeaderView.heightAnchor).isActive = true
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

extension SourceEntryViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        source is any TextSource ? textChapters.count : source is any ImageSource ? imageChapters.count : videoEpisodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        var seen = false
        switch source {
        case is any TextSource:
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
        case is any ImageSource:
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
        case is any VideoSource:
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
        default: break
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
        switch source {
        case is any TextSource:
            content.text = "\(textChapters.count) Chapters"
        case is any ImageSource:
            content.text = "\(imageChapters.count) Chapters"
        case is any VideoSource:
            content.text = "\(videoEpisodes.count) Episodes"
        default:
            return nil
        }
        content.textProperties.font = .systemFont(ofSize: 17, weight: .bold)
        content.textProperties.color = .label
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.openViewer(to: indexPath.item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SourceEntryViewController: EntryHeaderViewDelegate {
    func bookmarkButtonPressed() {
        guard let entry else { return }
        if LibraryManager.shared.library(forMediaType: entry.mediaType)?.all.ids.contains(entry._id) == true {
            Task {
                await LibraryManager.shared.remove(entry: entry)
            }
        } else {
            Task {
                await LibraryManager.shared.add(entry: entry)
            }
        }
    }

    func linkButtonPressed() {
        if let sourceEntry {
            self.navigationController?.pushViewController(LinkViewController(source: source, entry: sourceEntry), animated: true)
        }
    }

    func webViewButtonPressed() {
        if let url = sourceEntry.flatMap({ URL(string: $0.url) }) {
            self.present(SFSafariViewController(url: url), animated: true)
        }
    }

    func continueButtonPressed() {
        switch self.source {
        case is any TextSource:
            if let history = self.history,
               let index = self.textChapters.firstIndex(where: { $0.chapter == history.chapter && $0.volume == history.volume }) {
                self.openViewer(to: index)
            } else if !self.textChapters.isEmpty {
                self.openViewer(to: self.textChapters.count - 1)
            }
        case is any ImageSource:
            if let history = self.history,
               let index = self.imageChapters.firstIndex(where: { $0.chapter == history.chapter && $0.volume == history.volume }) {
                self.openViewer(to: index)
            } else if !self.imageChapters.isEmpty {
                self.openViewer(to: self.imageChapters.count - 1)
            }
        case is any VideoSource:
            if let history = self.history,
               let index = self.videoEpisodes.firstIndex(where: { $0.episode == history.episode }) {
                self.openViewer(to: index)
            } else if !self.videoEpisodes.isEmpty {
                self.openViewer(to: self.videoEpisodes.count - 1)
            }
        default:
            break
        }
    }

    func sizeDidChange() {
        if self.tableView.tableHeaderView?.subviews.first is EntryHeaderView {
            self.tableView.tableHeaderView?.layoutIfNeeded()
            self.tableView.tableHeaderView = self.tableView.tableHeaderView
        }
    }
}
