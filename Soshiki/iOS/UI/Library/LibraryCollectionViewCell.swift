//
//  LibraryCollectionViewCell.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/25/23.
//

import UIKit
import Nuke

class LibraryCollectionViewCell: EntryCollectionViewCell {
    var history: History?

    var entry: Entry!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addInteraction(UIContextMenuInteraction(delegate: self))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setEntry(entry: Entry) {
        self.entry = entry
        super.setEntry(entry: entry.toLocalEntry())
        Task {
            if let history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get() {
                self.history = history
            }
        }
    }
}

extension LibraryCollectionViewCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(actionProvider: { [weak self] _ -> UIMenu? in
            guard let self else { return nil }
            var actions: [UIMenuElement] = [
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
        })
    }
}
