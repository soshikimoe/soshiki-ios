//
//  EntryCollectionViewCell.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/11/23.
//

import UIKit
import Nuke

class SourceEntryCollectionViewCell: UICollectionViewCell {
    var entry: SourceShortEntry!

    let coverImageView: UIImageView

    let titleLabel: UILabel

    let stackView: UIStackView

    override init(frame: CGRect) {
        self.coverImageView = UIImageView()

        self.titleLabel = UILabel()

        self.stackView = UIStackView()

        super.init(frame: frame)

        configureSubviews()
        activateConstraints()
    }

    func setEntry(to entry: SourceEntry) {
        self.entry = SourceShortEntry(id: entry.id, title: entry.title, subtitle: "", cover: entry.cover)
        reloadView()
    }

    func setEntry(to entry: SourceShortEntry) {
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

        self.titleLabel.sizeToFit()
    }

    func configureSubviews() {
        self.coverImageView.contentMode = .scaleAspectFill
        self.coverImageView.layer.cornerRadius = 10
        self.coverImageView.clipsToBounds = true

        self.titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        self.titleLabel.textColor = .label
        self.titleLabel.numberOfLines = 2
        self.titleLabel.textAlignment = .left

        self.layer.shadowColor = UIColor(named: "DiscoverTrendingShadowColor")!.cgColor
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 0.4

        self.stackView.axis = .vertical
        self.stackView.alignment = .leading
        self.stackView.spacing = 4
        self.stackView.addArrangedSubview(self.coverImageView)
        self.stackView.addArrangedSubview(self.titleLabel)

        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.stackView)
    }

    func activateConstraints() {
        NSLayoutConstraint.activate([
            self.coverImageView.heightAnchor.constraint(equalTo: self.coverImageView.widthAnchor, multiplier: 3/2),
            self.coverImageView.widthAnchor.constraint(equalTo: self.contentView.widthAnchor),

            self.titleLabel.widthAnchor.constraint(lessThanOrEqualTo: self.coverImageView.widthAnchor),

            self.stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.stackView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.stackView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.stackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),

            self.contentView.heightAnchor.constraint(equalTo: self.stackView.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
