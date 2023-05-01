//
//  DiscoverFeaturedEntryView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/7/23.
//

import UIKit
import Nuke

class DiscoverFeaturedEntryView: UICollectionViewCell {
    var entry: SourceEntry!

    let coverImageView: ResizeListeningImageView
    let coverImageViewGradientLayer = CAGradientLayer()

    let titleLabel: UILabel
    let subtitleLabel: UILabel
    let genreLabel: UILabel
    let descriptionLabel: UILabel
    let openEntryButton: UIButton

    let contentStackView: UIStackView

    weak var delegate: DiscoverViewControllerChildDelegate?

    var image: URL? {
        if self.frame.width > self.frame.height {
            return self.entry.banner.flatMap({ URL(string: $0) }) ?? URL(string: self.entry.cover)
        } else {
            return URL(string: self.entry.cover)
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

    func setEntry(to entry: SourceEntry) {
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
        if let season = self.entry.season, let year = self.entry.year {
            subtitleComponents.append("\(season.rawValue.capitalized) \(year)")
        }
        if let items = self.entry.items {
            subtitleComponents.append("\(items) \(LibraryManager.shared.mediaType == .video ? "Episode" : "Chapter")\(items == 1 ? "" : "s")")
        }
        self.subtitleLabel.text = subtitleComponents.joined(separator: "  •  ")

        self.genreLabel.text = self.entry.tags.prefix(3).map({ $0.uppercased() }).joined(separator: "  •  ")

        self.descriptionLabel.attributedText = NSAttributedString.html(self.entry.description, font: .systemFont(ofSize: 12), color: .white)
    }

    func configureSubviews() {
        self.coverImageView.delegate = self
        self.coverImageView.contentMode = .scaleAspectFill
        self.coverImageView.clipsToBounds = true
        self.coverImageView.alpha = 0

        self.coverImageViewGradientLayer.colors = [
            UIColor(white: 0, alpha: 0.6).cgColor,
            UIColor.clear.cgColor,
            UIColor(white: 0, alpha: 0.8).cgColor,
            UIColor.black.cgColor
        ]
        self.coverImageViewGradientLayer.locations = [ 0, 0.3, 0.6, 0.8 ]
        self.coverImageViewGradientLayer.frame = self.coverImageView.bounds
        self.coverImageViewGradientLayer.needsDisplayOnBoundsChange = true

        self.coverImageView.layer.insertSublayer(self.coverImageViewGradientLayer, at: 0)

        self.titleLabel.font = .systemFont(ofSize: 35, weight: .bold)
        self.titleLabel.textColor = .white
        self.titleLabel.numberOfLines = 2

        self.subtitleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        self.subtitleLabel.textColor = .lightGray

        self.genreLabel.font = .systemFont(ofSize: 12, weight: .heavy)
        self.genreLabel.textColor = .lightGray

        self.descriptionLabel.numberOfLines = 3

        self.contentStackView.axis = .vertical
        self.contentStackView.spacing = 4
        self.contentStackView.addArrangedSubview(self.titleLabel)
        self.contentStackView.addArrangedSubview(self.subtitleLabel)
        self.contentStackView.addArrangedSubview(self.genreLabel)
        self.contentStackView.addArrangedSubview(self.descriptionLabel)

        self.openEntryButton.tintColor = .black
        self.openEntryButton.backgroundColor = .white
        self.openEntryButton.setAttributedTitle(
            NSAttributedString(
                string: "See More",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                    .foregroundColor: UIColor.black
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
            self.openEntryButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -8),
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

// MARK: - DiscoverFeaturedEntryView + UIScrollViewDelegate

extension DiscoverFeaturedEntryView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= 0, scrollView.contentOffset.y <= self.frame.maxY {
            self.coverImageView.frame = self.bounds.offsetBy(dx: 0, dy: scrollView.contentOffset.y / 2)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        CATransaction.setDisableActions(true)
        self.coverImageViewGradientLayer.frame = self.coverImageView.bounds
        CATransaction.commit()
    }
}

// MARK: - DiscoverFeaturedEntryView + ResizeListeningImageViewDelegate

extension DiscoverFeaturedEntryView: ResizeListeningImageViewDelegate {
    func frameDidChange(to frame: CGRect) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        CATransaction.setDisableActions(true)
        self.coverImageViewGradientLayer.frame = self.coverImageView.bounds
        CATransaction.commit()
    }

    func boundsDidChange(to bounds: CGRect) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        CATransaction.setDisableActions(true)
        self.coverImageViewGradientLayer.frame = self.coverImageView.bounds
        CATransaction.commit()
    }
}
