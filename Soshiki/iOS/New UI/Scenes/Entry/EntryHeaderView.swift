//
//  EntryHeaderView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 4/9/23.
//

import UIKit
import Nuke

class EntryHeaderView: UIView {
    let coverImageView: ResizeListeningImageView
    let coverImageViewGradientLayer: CAGradientLayer

    let titleLabel: UILabel
    let subtitleLabel: UILabel

    let tagScrollView: UIScrollView
    let tagStackView: UIStackView

    let startButton: UIButton

    let buttonStackView: UIStackView
    let libraryButton: UIButton
    let webviewButton: UIButton
    let trackerButton: UIButton

    let descriptionLabel: UILabel

    let titleSubtitleStackView: UIStackView

    let contentStackView: UIStackView

    let closeButton: UIButton
    let moreButton: UIButton

    var isLandscape: Bool {
        self.frame.width > self.frame.height
    }

    weak var delegate: EntryHeaderViewDelegate?

    override init(frame: CGRect) {
        self.coverImageView = ResizeListeningImageView()
        self.coverImageViewGradientLayer = CAGradientLayer()
        self.titleLabel = UILabel()
        self.subtitleLabel = UILabel()
        self.tagScrollView = UIScrollView()
        self.tagStackView = UIStackView()
        self.startButton = UIButton(type: .roundedRect)
        self.buttonStackView = UIStackView()
        self.libraryButton = UIButton(type: .roundedRect)
        self.webviewButton = UIButton(type: .roundedRect)
        self.trackerButton = UIButton(type: .roundedRect)
        self.descriptionLabel = UILabel()
        self.titleSubtitleStackView = UIStackView()
        self.contentStackView = UIStackView()
        self.closeButton = UIButton(type: .roundedRect)
        self.moreButton = UIButton(type: .roundedRect)

        super.init(frame: frame)

        configureSubviews()
        applyConstraints()

        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        CATransaction.setDisableActions(true)
        self.coverImageViewGradientLayer.frame = self.coverImageView.bounds
        CATransaction.commit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureSubviews() {
        self.clipsToBounds = true
        self.backgroundColor = .black

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

        self.tagScrollView.showsHorizontalScrollIndicator = false

        self.tagStackView.axis = .horizontal
        self.tagStackView.spacing = 8

        self.tagStackView.translatesAutoresizingMaskIntoConstraints = false
        self.tagScrollView.addSubview(self.tagStackView)

        self.descriptionLabel.numberOfLines = 8

        var configuration = UIButton.Configuration.plain()
        configuration.imagePadding = 8
        self.startButton.configuration = configuration
        self.startButton.tintColor = .black
        self.startButton.backgroundColor = .white
        self.startButton.setAttributedTitle(
            NSAttributedString(
                string: "No Content Available",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
            ),
            for: .normal
        )
        self.startButton.layer.cornerRadius = 10
        self.startButton.clipsToBounds = true
        self.startButton.addTarget(self, action: #selector(startButtonPressed(_:)), for: .touchUpInside)

        self.libraryButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        self.libraryButton.tintColor = .black
        self.libraryButton.backgroundColor = .white
        self.libraryButton.layer.cornerRadius = 10
        self.libraryButton.clipsToBounds = true
        self.libraryButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold), forImageIn: .normal)
        self.libraryButton.addTarget(self, action: #selector(libraryButtonPressed(_:)), for: .touchUpInside)

        self.webviewButton.setImage(UIImage(systemName: "globe"), for: .normal)
        self.webviewButton.tintColor = .black
        self.webviewButton.backgroundColor = .white
        self.webviewButton.layer.cornerRadius = 10
        self.webviewButton.clipsToBounds = true
        self.webviewButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold), forImageIn: .normal)
        self.webviewButton.addTarget(self, action: #selector(webviewButtonPressed(_:)), for: .touchUpInside)

        self.trackerButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        self.trackerButton.tintColor = .black
        self.trackerButton.backgroundColor = .white
        self.trackerButton.layer.cornerRadius = 10
        self.trackerButton.clipsToBounds = true
        self.trackerButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold), forImageIn: .normal)
        self.trackerButton.addTarget(self, action: #selector(trackerButtonPressed(_:)), for: .touchUpInside)

        self.buttonStackView.axis = .horizontal
        self.buttonStackView.spacing = 8
        self.buttonStackView.addArrangedSubview(self.libraryButton)
        self.buttonStackView.addArrangedSubview(self.webviewButton)
        self.buttonStackView.addArrangedSubview(self.trackerButton)

        self.titleSubtitleStackView.axis = .vertical
        self.titleSubtitleStackView.spacing = 4
        self.titleSubtitleStackView.alignment = .leading
        self.titleSubtitleStackView.addArrangedSubview(self.titleLabel)
        self.titleSubtitleStackView.addArrangedSubview(self.subtitleLabel)

        self.contentStackView.axis = .vertical
        self.contentStackView.spacing = 8
        self.contentStackView.addArrangedSubview(self.titleSubtitleStackView)
        self.contentStackView.addArrangedSubview(self.tagScrollView)
        self.contentStackView.addArrangedSubview(self.descriptionLabel)
        self.contentStackView.addArrangedSubview(self.startButton)
        self.contentStackView.addArrangedSubview(self.buttonStackView)

        self.closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        self.closeButton.backgroundColor = .darkGray
        self.closeButton.tintColor = .white
        self.closeButton.layer.cornerRadius = 16
        self.closeButton.clipsToBounds = true
        self.closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)
        self.closeButton.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold),
            forImageIn: .normal
        )

        self.moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        self.moreButton.backgroundColor = .darkGray
        self.moreButton.tintColor = .white
        self.moreButton.layer.cornerRadius = 16
        self.moreButton.clipsToBounds = true
        if let menu = self.delegate?.moreButtonMenu {
            self.moreButton.showsMenuAsPrimaryAction = true
            self.moreButton.removeTarget(self, action: #selector(moreButtonPressed(_:)), for: .touchUpInside)
            self.moreButton.menu = menu
        } else {
            self.moreButton.showsMenuAsPrimaryAction = false
            self.moreButton.addTarget(self, action: #selector(moreButtonPressed(_:)), for: .touchUpInside)
            self.moreButton.menu = nil
        }
        self.moreButton.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold),
            forImageIn: .normal
        )

        self.coverImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.coverImageView)
        self.contentStackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentStackView)
        self.closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.closeButton)
        self.moreButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.moreButton)
    }

    func applyConstraints() {
        NSLayoutConstraint.activate([
            self.coverImageView.topAnchor.constraint(equalTo: self.topAnchor),
            self.coverImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.coverImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.coverImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -100),

            self.tagStackView.topAnchor.constraint(equalTo: self.tagScrollView.topAnchor),
            self.tagStackView.leadingAnchor.constraint(equalTo: self.tagScrollView.leadingAnchor),
            self.tagStackView.trailingAnchor.constraint(equalTo: self.tagScrollView.trailingAnchor),
            self.tagStackView.bottomAnchor.constraint(equalTo: self.tagScrollView.bottomAnchor),

            self.tagScrollView.heightAnchor.constraint(equalTo: self.tagStackView.heightAnchor),

            self.startButton.widthAnchor.constraint(equalTo: self.contentStackView.widthAnchor),
            self.startButton.heightAnchor.constraint(equalToConstant: 40),

            self.webviewButton.widthAnchor.constraint(equalTo: self.libraryButton.widthAnchor),

            self.trackerButton.widthAnchor.constraint(equalTo: self.libraryButton.widthAnchor),

            self.buttonStackView.widthAnchor.constraint(equalTo: self.contentStackView.widthAnchor),
            self.buttonStackView.heightAnchor.constraint(equalToConstant: 40),

            self.contentStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.contentStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
            self.contentStackView.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -16 * 2),

            self.closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 48),
            self.closeButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            self.closeButton.widthAnchor.constraint(equalToConstant: 32),
            self.closeButton.heightAnchor.constraint(equalToConstant: 32),

            self.moreButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 48),
            self.moreButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            self.moreButton.widthAnchor.constraint(equalToConstant: 32),
            self.moreButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    func setEntry(to sourceEntry: SourceEntry) {
        self.coverImageView.alpha = 0
        if let url = URL(string: self.isLandscape ? sourceEntry.banner ?? sourceEntry.cover : sourceEntry.cover) {
            ImagePipeline.shared.loadImage(with: url) { [weak self] result in
                if case let .success(response) = result {
                    self?.coverImageView.image = response.image
                    self?.coverImageView.alpha = 1
                }
            }
        }

        self.titleLabel.text = sourceEntry.title

        self.subtitleLabel.text = sourceEntry.staff.first

        self.tagStackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })

        self.tagStackView.addArrangedSubview(
            EntryTagView(title: sourceEntry.status.rawValue.capitalized, image: UIImage(systemName: "timer"))
        )

        if let year = sourceEntry.year {
            self.tagStackView.addArrangedSubview(
                EntryTagView(
                    title: ((sourceEntry.season.flatMap({ [ $0.rawValue.capitalized ] }) ?? []) + [ "\(year)" ]).joined(separator: " "),
                    image: UIImage(systemName: "calendar")
                )
            )
        }

        if let score = sourceEntry.score {
            self.tagStackView.addArrangedSubview(
                EntryTagView(
                    title: score.toTruncatedString(),
                    image: UIImage(systemName: "star.fill"),
                    color: UIColor(red: 240/255, green: 216/255, blue: 0, alpha: 1)
                )
            )
        }

        for tag in sourceEntry.tags {
            self.tagStackView.addArrangedSubview(EntryTagView(title: tag))
        }

        self.descriptionLabel.attributedText = NSAttributedString.html(sourceEntry.description, font: .systemFont(ofSize: 12), color: .white)

        self.delegate?.sizeDidChange?()
    }

    func updateMoreButtonState() {
        if let menu = self.delegate?.moreButtonMenu {
            self.moreButton.showsMenuAsPrimaryAction = true
            self.moreButton.removeTarget(self, action: #selector(moreButtonPressed(_:)), for: .touchUpInside)
            self.moreButton.menu = menu
        } else {
            self.moreButton.showsMenuAsPrimaryAction = false
            self.moreButton.addTarget(self, action: #selector(moreButtonPressed(_:)), for: .touchUpInside)
            self.moreButton.menu = nil
        }
    }
}

// MARK: - Button Handlers

extension EntryHeaderView {
    @objc func closeButtonPressed(_ sender: UIButton) {
        self.delegate?.closeButtonPressed?()
    }

    @objc func moreButtonPressed(_ sender: UIButton) {
        self.delegate?.moreButtonPressed?()
    }

    @objc func startButtonPressed(_ sender: UIButton) {
        self.delegate?.startButtonPressed?()
    }

    @objc func libraryButtonPressed(_ sender: UIButton) {
        self.delegate?.libraryButtonPressed?()
    }

    @objc func webviewButtonPressed(_ sender: UIButton) {
        self.delegate?.webviewButtonPressed?()
    }

    @objc func trackerButtonPressed(_ sender: UIButton) {
        self.delegate?.trackerButtonPressed?()
    }
}

// MARK: - EntryHeaderView + UIScrollViewDelegate

extension EntryHeaderView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= 0, scrollView.contentOffset.y <= self.frame.maxY {
            self.coverImageView.frame.origin = self.bounds.offsetBy(dx: 0, dy: scrollView.contentOffset.y / 2).origin
        }
    }
}

// MARK: - EntryHeaderView + ResizeListeningImageViewDelegate

extension EntryHeaderView: ResizeListeningImageViewDelegate {
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

@objc protocol EntryHeaderViewDelegate {
    @objc optional var moreButtonMenu: UIMenu? { get }

    @objc optional func startButtonPressed()
    @objc optional func closeButtonPressed()
    @objc optional func moreButtonPressed()
    @objc optional func libraryButtonPressed()
    @objc optional func trackerButtonPressed()
    @objc optional func webviewButtonPressed()
    @objc optional func sizeDidChange()
}
