//
//  DiscoverFeaturedEntryView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/7/23.
//

import UIKit
import Nuke

class DiscoverFeaturedEntryView<EntryType: Entry>: UICollectionViewCell {
    var entry: EntryType!

    let coverImageView: UIImageView
    let coverImageViewGradientLayer = CAGradientLayer()

    let titleLabel: UILabel
    let subtitleLabel: UILabel
    let genreLabel: UILabel
    let descriptionLabel: UILabel
    let openEntryButton: UIButton

    let contentStackView: UIStackView

    weak var delegate: (any DiscoverViewControllerChildDelegate<EntryType>)?

    override var bounds: CGRect {
        didSet {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0)
            self.coverImageViewGradientLayer.frame = self.bounds
            CATransaction.commit()
        }
    }

    var image: URL? {
        if self.frame.width > self.frame.height {
            return self.entry.banner.flatMap({ URL(string: $0) }) ?? URL(string: self.entry.cover ?? "")
        } else {
            return URL(string: self.entry.cover ?? "")
        }
    }

    override init(frame: CGRect) {
        self.coverImageView = ResizeListeningImageView()

        self.titleLabel = UILabel()
        self.subtitleLabel = UILabel()
        self.genreLabel = UILabel()
        self.descriptionLabel = UILabel()
        self.openEntryButton = UIButton(type: .roundedRect)

        self.contentStackView = UIStackView()

        super.init(frame: frame)

        configureSubviews()
        activateConstraints()
    }

    func setEntry(to entry: EntryType) {
        self.entry = entry
        reloadView()
    }

    func reloadView() {
        self.coverImageView.alpha = 0
        if let image = self.image {
            ImagePipeline.shared.loadImage(with: image) { [weak self] result in
                if case .success(let response) = result {
                    self?.coverImageView.alpha = 1
                    self?.coverImageView.image = response.image
                }
            }
        } else {
            self.coverImageView.image = nil
        }

        self.titleLabel.text = self.entry.title

        var subtitleComponents: [String] = []
        if let entry = self.entry as? VideoEntry, entry.season != .unknown, let year = entry.year {
            subtitleComponents.append("\(entry.season.rawValue.capitalized) \(year)")
        } else if let year = self.entry.year {
            subtitleComponents.append("\(year)")
        }

        if let entry = self.entry as? VideoEntry, let episodes = entry.episodes, !episodes.isNaN {
            subtitleComponents.append("\(episodes.toTruncatedString()) Episodes")
        } else if let entry = self.entry as? ImageEntry, let chapters = entry.chapters, !chapters.isNaN {
            subtitleComponents.append("\(chapters.toTruncatedString()) Chapters")
        } else if let entry = self.entry as? TextEntry, let chapters = entry.chapters, !chapters.isNaN {
            subtitleComponents.append("\(chapters.toTruncatedString()) Chapters")
        }

        self.subtitleLabel.text = subtitleComponents.joined(separator: "  •  ")

        self.genreLabel.text = self.entry.tags.prefix(3).map({ $0.uppercased() }).joined(separator: "  •  ")

        self.descriptionLabel.attributedText = NSAttributedString.html(self.entry.synopsis ?? "", font: .systemFont(ofSize: 12), color: .label)
    }

    func configureSubviews() {
        self.coverImageView.contentMode = .scaleAspectFill
        self.coverImageView.clipsToBounds = true
        self.coverImageView.alpha = 0

        self.coverImageViewGradientLayer.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.systemBackground.withAlphaComponent(0.6).cgColor,
            UIColor.clear.cgColor,
            UIColor.systemBackground.withAlphaComponent(0.8).cgColor,
            UIColor.systemBackground.cgColor
        ]
        self.coverImageViewGradientLayer.locations = [ 0, 0.1, 0.3, 0.6, 0.8 ]
        self.coverImageViewGradientLayer.frame = self.coverImageView.bounds
        self.coverImageViewGradientLayer.needsDisplayOnBoundsChange = true

        self.coverImageView.layer.insertSublayer(self.coverImageViewGradientLayer, at: 0)

        self.titleLabel.font = .systemFont(ofSize: 35, weight: .bold)
        self.titleLabel.textColor = .label
        self.titleLabel.numberOfLines = 2

        self.subtitleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        self.subtitleLabel.textColor = .secondaryLabel

        self.genreLabel.font = .systemFont(ofSize: 12, weight: .heavy)
        self.genreLabel.textColor = .secondaryLabel

        self.descriptionLabel.numberOfLines = 3

        self.contentStackView.axis = .vertical
        self.contentStackView.spacing = 4
        self.contentStackView.addArrangedSubview(self.titleLabel)
        self.contentStackView.addArrangedSubview(self.subtitleLabel)
        self.contentStackView.addArrangedSubview(self.genreLabel)
        self.contentStackView.addArrangedSubview(self.descriptionLabel)

        self.openEntryButton.tintColor = .systemBackground
        self.openEntryButton.backgroundColor = .label
        self.openEntryButton.setAttributedTitle(
            NSAttributedString(
                string: "See More",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                    .foregroundColor: UIColor.systemBackground
                ]
            ),
            for: .normal
        )
        self.openEntryButton.layer.cornerRadius = 10
        self.openEntryButton.clipsToBounds = true
        self.openEntryButton.addTarget(self, action: #selector(openEntryButtonPressed(_:)), for: .touchUpInside)

        self.coverImageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.coverImageView)
        self.contentStackView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.contentStackView)
        self.openEntryButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.openEntryButton)
    }

    func activateConstraints() {
        NSLayoutConstraint.activate([
            self.coverImageView.topAnchor.constraint(equalTo: self.topAnchor),
            self.coverImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.coverImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.coverImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            self.openEntryButton.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
            self.openEntryButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -16),
            self.openEntryButton.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, constant: -16 * 2),
            self.openEntryButton.heightAnchor.constraint(equalToConstant: 40),

            self.contentStackView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
            self.contentStackView.bottomAnchor.constraint(equalTo: self.openEntryButton.topAnchor, constant: -8),
            self.contentStackView.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, constant: -16 * 2)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func openEntryButtonPressed(_ sender: UIButton) {
        self.delegate?.didSelect(entry: self.entry)
    }
}
