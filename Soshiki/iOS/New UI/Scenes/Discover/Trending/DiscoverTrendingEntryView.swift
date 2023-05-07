//
//  DiscoverTrendingEntryView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/9/23.
//

import UIKit
import Nuke

class DiscoverTrendingEntryView: UICollectionViewCell {
    var entry: SourceEntry!

    let coverImageView: UIImageView

    let titleLabel: UILabel
    let subtitleLabel: UILabel
    let descriptionLabel: UILabel

    let contentStackView: UIStackView

    override init(frame: CGRect) {
        self.coverImageView = UIImageView()

        self.titleLabel = UILabel()
        self.subtitleLabel = UILabel()
        self.descriptionLabel = UILabel()

        self.contentStackView = UIStackView()

        super.init(frame: frame)

        configureSubviews()
        activateConstraints()
    }

    func setEntry(to entry: SourceEntry) {
        self.entry = entry
        reloadView()
    }

    func reloadView() {
        if let cover = URL(string: self.entry.cover) {
            ImagePipeline.shared.loadImage(with: cover) { [weak self] result in
                if case .success(let response) = result {
                    self?.coverImageView.image = response.image
                }
            }
        } else {
            self.coverImageView.image = nil
        }

        self.titleLabel.text = self.entry.title

        var subtitleComponents: [String] = []
        if let season = self.entry.season, let year = self.entry.year {
            subtitleComponents.append("\(season.rawValue.capitalized) \(year)")
        }
        if let items = self.entry.items {
            subtitleComponents.append("\(items) \(LibraryManager.shared.mediaType == .video ? "Episode" : "Chapter")\(items == 1 ? "" : "s")")
        }
        self.subtitleLabel.text = subtitleComponents.joined(separator: "  •  ")

        self.descriptionLabel.attributedText = NSAttributedString.html(self.entry.description, font: .systemFont(ofSize: 12), color: .label)
    }

    func configureSubviews() {
        self.coverImageView.contentMode = .scaleAspectFill
        self.coverImageView.clipsToBounds = true

        self.titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        self.titleLabel.textColor = .label
        self.titleLabel.numberOfLines = 2

        self.subtitleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        self.subtitleLabel.textColor = .secondaryLabel
        self.subtitleLabel.numberOfLines = 1

        self.descriptionLabel.numberOfLines = 0
        self.descriptionLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        self.contentStackView.axis = .vertical
        self.contentStackView.alignment = .top
        self.contentStackView.spacing = 4
        self.contentStackView.addArrangedSubview(self.titleLabel)
        self.contentStackView.addArrangedSubview(self.subtitleLabel)
        self.contentStackView.addArrangedSubview(self.descriptionLabel)

        self.contentView.backgroundColor = .tertiarySystemBackground
        self.contentView.layer.cornerRadius = 10
        self.contentView.clipsToBounds = true

        self.layer.shadowColor = UIColor(named: "DiscoverTrendingShadowColor")!.cgColor
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 0.4

        self.coverImageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.coverImageView)
        self.contentStackView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.contentStackView)
    }

    func activateConstraints() {
        NSLayoutConstraint.activate([
            self.coverImageView.topAnchor.constraint(equalTo: self.topAnchor),
            self.coverImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.coverImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.coverImageView.widthAnchor.constraint(equalTo: self.coverImageView.heightAnchor, multiplier: 2/3),

            self.contentStackView.leadingAnchor.constraint(equalTo: self.coverImageView.trailingAnchor, constant: 12),
            self.contentStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            self.contentStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
            self.contentStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
