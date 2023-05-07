//
//  DiscoverTopEntryView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/10/23.
//

import UIKit
import Nuke

class DiscoverTopEntryView: UICollectionViewCell {
    var entry: SourceEntry!
    var number: Int!

    let coverImageView: UIImageView

    let titleLabel: UILabel
    let subtitleLabel: UILabel
    let numberLabel: UILabel

    let titleStackView: UIStackView
    let contentStackView: UIStackView

    override init(frame: CGRect) {
        self.coverImageView = UIImageView()

        self.titleLabel = UILabel()
        self.subtitleLabel = UILabel()
        self.numberLabel = UILabel()

        self.titleStackView = UIStackView()
        self.contentStackView = UIStackView()

        super.init(frame: frame)

        configureSubviews()
        activateConstraints()
    }

    func setEntry(to entry: SourceEntry, number: Int) {
        self.entry = entry
        self.number = number
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

        self.numberLabel.text = "\(number!)"
    }

    func configureSubviews() {
        self.coverImageView.contentMode = .scaleAspectFill
        self.coverImageView.layer.cornerRadius = 10
        self.coverImageView.clipsToBounds = true

        self.titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        self.titleLabel.textColor = .label
        self.titleLabel.numberOfLines = 2

        self.subtitleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        self.subtitleLabel.textColor = .secondaryLabel
        self.subtitleLabel.numberOfLines = 1

        self.numberLabel.font = .systemFont(ofSize: 20, weight: .bold)
        self.numberLabel.textAlignment = .center

        self.titleStackView.axis = .vertical
        self.titleStackView.alignment = .leading
        self.titleStackView.spacing = 4
        self.titleStackView.addArrangedSubview(self.titleLabel)
        self.titleStackView.addArrangedSubview(self.subtitleLabel)

        self.contentStackView.axis = .horizontal
        self.contentStackView.alignment = .center
        self.contentStackView.spacing = 16
        self.contentStackView.addArrangedSubview(self.coverImageView)
        self.contentStackView.addArrangedSubview(self.numberLabel)
        self.contentStackView.addArrangedSubview(self.titleStackView)

        self.contentStackView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.contentStackView)
    }

    func activateConstraints() {
        NSLayoutConstraint.activate([
            self.contentStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            self.contentStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            self.contentStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
            self.contentStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),

            self.numberLabel.widthAnchor.constraint(equalToConstant: 30),

            self.coverImageView.widthAnchor.constraint(equalTo: self.coverImageView.heightAnchor, multiplier: 2/3)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
