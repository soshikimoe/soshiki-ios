//
//  EntryItemTableViewCell.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/30/23.
//

import UIKit
import Nuke

class EntryItemTableViewCell: UITableViewCell {
    let coverImageView: UIImageView
    let titleLabel: UILabel
    let subtitle1Label: UILabel
    let subtitle2Label: UILabel
    let titleStackView: UIStackView
    let contentStackView: UIStackView

    var coverImageViewHeightConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.coverImageView = UIImageView()
        self.titleLabel = UILabel()
        self.subtitle1Label = UILabel()
        self.subtitle2Label = UILabel()
        self.titleStackView = UIStackView()
        self.contentStackView = UIStackView()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureSubviews()
        applyConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureSubviews() {
        self.coverImageView.contentMode = .scaleAspectFill

        self.titleLabel.font = .systemFont(ofSize: 18, weight: .bold)

        self.subtitle1Label.font = .systemFont(ofSize: 15, weight: .semibold)
        self.subtitle1Label.textColor = .secondaryLabel

        self.subtitle2Label.font = .systemFont(ofSize: 15, weight: .semibold)
        self.subtitle2Label.textColor = .secondaryLabel

        self.titleStackView.axis = .vertical
        self.titleStackView.spacing = 2
        self.titleStackView.alignment = .leading
        self.titleStackView.isLayoutMarginsRelativeArrangement = true
        self.titleStackView.layoutMargins = UIEdgeInsets(all: 8)
        self.titleStackView.addArrangedSubview(self.titleLabel)
        self.titleStackView.addArrangedSubview(self.subtitle1Label)
        self.titleStackView.addArrangedSubview(self.subtitle2Label)

        self.contentStackView.backgroundColor = .secondarySystemBackground
        self.contentStackView.layer.cornerRadius = 10
        self.contentStackView.clipsToBounds = true
        self.contentStackView.axis = .horizontal
        self.contentStackView.spacing = 8
        self.contentStackView.alignment = .top
        self.contentStackView.addArrangedSubview(self.coverImageView)
        self.contentStackView.addArrangedSubview(self.titleStackView)

        self.contentStackView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.contentStackView)
    }

    func applyConstraints() {
        self.coverImageViewHeightConstraint = self.coverImageView.heightAnchor.constraint(equalToConstant: 90)
        NSLayoutConstraint.activate([
            self.coverImageViewHeightConstraint,
            self.coverImageView.widthAnchor.constraint(equalTo: self.coverImageView.heightAnchor, multiplier: CGFloat(16)/CGFloat(9)),

            self.contentView.topAnchor.constraint(equalTo: self.contentStackView.topAnchor, constant: -8),
            self.contentView.leadingAnchor.constraint(equalTo: self.contentStackView.leadingAnchor, constant: -16),
            self.contentView.trailingAnchor.constraint(equalTo: self.contentStackView.trailingAnchor, constant: 16),
            self.contentView.bottomAnchor.constraint(equalTo: self.contentStackView.bottomAnchor, constant: 8),

            self.contentView.heightAnchor.constraint(equalTo: self.contentStackView.heightAnchor, constant: 16)
        ])
    }

    func setItem(to chapter: TextSourceChapter, status: ItemStatus = .unseen) {
        setItem(
            number: chapter.chapter,
            group: chapter.volume,
            title: chapter.name,
            thumbnail: chapter.thumbnail,
            info: chapter.translator,
            timestamp: chapter.timestamp,
            status: status,
            mediaType: .text
        )
    }

    func setItem(to chapter: ImageSourceChapter, status: ItemStatus = .unseen) {
        setItem(
            number: chapter.chapter,
            group: chapter.volume,
            title: chapter.name,
            thumbnail: chapter.thumbnail,
            info: chapter.translator,
            timestamp: chapter.timestamp,
            status: status,
            mediaType: .image
        )
    }

    func setItem(to episode: VideoSourceEpisode, status: ItemStatus = .unseen) {
        setItem(
            number: episode.episode,
            group: episode.season,
            title: episode.name,
            thumbnail: episode.thumbnail,
            info: episode.type.rawValue.capitalized,
            timestamp: episode.timestamp,
            status: status,
            mediaType: .video
        )
    }

    private func setItem(
        number: Double,
        group: Double?,
        title: String?,
        thumbnail: String?,
        info: String?,
        timestamp: Double?,
        status: ItemStatus,
        mediaType: MediaType
    ) {
        let numberString: String
        let groupString: String?

        let statusString = status.progress.flatMap({ progress in
            switch mediaType {
            case .text: return "\(progress) percent read"
            case .image: return "\(progress) pages read"
            case .video: return "\(progress.toMinuteSecondString()) watched"
            }
        })

        if case .seen = status {
            self.titleLabel.textColor = .secondaryLabel
        } else {
            self.titleLabel.textColor = .label
        }

        switch mediaType {
        case .text, .image:
            numberString = "Chapter \(number.toTruncatedString())"
            groupString = group.flatMap({ "Volume \($0.toTruncatedString())" })
        case .video:
            numberString = "Episode \(number.toTruncatedString())"
            groupString = group.flatMap({ "Season \($0.toTruncatedString())" })
        }
        if let title, !title.isEmpty {
            setItem(
                image: thumbnail,
                title: title,
                subtitle1: ([
                    [ groupString, numberString ].compactMap({ $0 }).joined(separator: " "),
                    info
                ].compactMap({ $0 }) as [String]).joined(separator: " • "),
                subtitle2: [
                    timestamp.flatMap({
                        RelativeDateTimeFormatter().localizedString(for: Date(timeIntervalSince1970: $0), relativeTo: Date.now)
                    }),
                    statusString
                ].compactMap({ $0 }).joined(separator: " • ")
            )
        } else {
            setItem(
                image: thumbnail,
                title: [ groupString, numberString ].compactMap({ $0 }).joined(separator: " "),
                subtitle1: info,
                subtitle2: [
                    timestamp.flatMap({
                        RelativeDateTimeFormatter().localizedString(for: Date(timeIntervalSince1970: $0), relativeTo: Date.now)
                    }),
                    statusString
                ].compactMap({ $0 }).joined(separator: " • ")
            )
        }
    }

    private func setItem(image: String?, title: String, subtitle1: String?, subtitle2: String?) {
        self.coverImageView.image = nil
        self.coverImageViewHeightConstraint.constant = 0
        if let image, let url = URL(string: image) {
            ImagePipeline.shared.loadImage(with: url) { [weak self] result in
                if case let .success(response) = result {
                    self?.coverImageView.image = response.image
                    self?.coverImageViewHeightConstraint.constant = 90
                }
            }
        }

        self.titleLabel.text = title

        if let subtitle1, !subtitle1.isEmpty {
            if self.subtitle1Label.superview == nil {
                self.titleStackView.insertArrangedSubview(self.subtitle1Label, at: 1)
            }
            self.subtitle1Label.text = subtitle1
        } else if self.subtitle1Label.superview != nil {
            self.subtitle1Label.removeFromSuperview()
        }

        if let subtitle2, !subtitle2.isEmpty {
            if self.subtitle2Label.superview == nil {
                self.titleStackView.addArrangedSubview(self.subtitle2Label)
            }
            self.subtitle2Label.text = subtitle2
        } else if self.subtitle2Label.superview != nil {
            self.subtitle2Label.removeFromSuperview()
        }
    }
}

enum ItemStatus {
    case seen
    case inProgress(Int)
    case unseen

    var progress: Int? {
        if case .inProgress(let progress) = self {
            return progress
        } else {
            return nil
        }
    }
}
