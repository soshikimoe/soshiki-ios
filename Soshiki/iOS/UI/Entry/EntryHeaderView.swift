//
//  EntryHeaderView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/25/23.
//

import UIKit
import Nuke

class EntryHeaderView: UIView {
    var observers: [NSObjectProtocol] = []

    weak var delegate: (any EntryHeaderViewDelegate)?

    let mediaType: MediaType
    var localEntry: LocalEntry?
    var entry: Entry?
    var history: History?
//    let bannerImageView = UIImageView()
//    let bannerGradientLayer = CAGradientLayer()
    let headerStackView = UIStackView()
    let titleCoverStackView = UIStackView()
    let coverImageView = UIImageView()
    let titleStackView = UIStackView()
    let titleView = UILabel()
    let subtitleView = UILabel()
    let starImageViews = [ UIImageView(), UIImageView(), UIImageView(), UIImageView(), UIImageView() ]
    let starSpacerView = UIView()
    let starStackView = UIStackView()
    let statusLabelView = UILabel()
    let statusTitleView = UILabel()
    let statusSpacerView = UIView()
    let statusStackView = UIStackView()
    let tagScrollView = UIScrollView()
    let tagStackView = UIStackView()
    let descriptionLabelView = UILabel()
    let seeMoreButton = UIButton()
    let descriptionView = UIView()
    let continueButton = UIButton(type: .roundedRect)
    let bookmarkButton = UIButton(type: .roundedRect)
    let linkButton = UIButton(type: .roundedRect)
    let webViewButton = UIButton(type: .roundedRect)
    let buttonStackView = UIStackView()

    var canContinue = false {
        didSet {
            if canContinue {
                self.continueButton.setAttributedTitle(NSAttributedString(
                    string: self.mediaType == .video ? "Continue Watching" : "Continue Reading",
                    attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .bold)]
                ), for: .normal)
            } else {
                self.continueButton.setAttributedTitle(NSAttributedString(
                    string: self.mediaType == .video ? "Begin Watching" : "Begin Reading",
                    attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .bold)]
                ), for: .normal)
            }
        }
    }

    var descriptionExpanded = false

    init(mediaType: MediaType) {
        self.mediaType = mediaType
        super.init(frame: .zero)

        headerStackView.axis = .vertical
        headerStackView.spacing = 8

        titleCoverStackView.axis = .horizontal
        titleCoverStackView.alignment = .bottom
        titleCoverStackView.spacing = 12

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.layer.borderWidth = 0.25
        coverImageView.layer.borderColor = UIColor.gray.cgColor
        coverImageView.layer.cornerRadius = 20
        coverImageView.clipsToBounds = true
        coverImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        coverImageView.heightAnchor.constraint(equalToConstant: 225).isActive = true

        titleStackView.axis = .vertical
        titleStackView.spacing = 5

        titleView.font = .systemFont(ofSize: 22, weight: .bold)
        titleView.numberOfLines = 3
        titleView.minimumScaleFactor = 0.5

        subtitleView.textColor = .secondaryLabel
        subtitleView.font = .systemFont(ofSize: 17)
        subtitleView.numberOfLines = 3
        subtitleView.minimumScaleFactor = 0.5

        starStackView.axis = .horizontal
        starStackView.alignment = .leading

        statusTitleView.text = "Status"
        statusTitleView.textColor = .secondaryLabel
        statusTitleView.font = .systemFont(ofSize: 15)

        statusLabelView.font = .systemFont(ofSize: 15, weight: .semibold)

        statusStackView.axis = .horizontal
        statusStackView.spacing = 5
        statusStackView.alignment = .leading

        tagStackView.axis = .horizontal
        tagStackView.spacing = 8
        tagStackView.translatesAutoresizingMaskIntoConstraints = false

        descriptionLabelView.numberOfLines = 4
        descriptionLabelView.font = .systemFont(ofSize: 15)
        descriptionLabelView.translatesAutoresizingMaskIntoConstraints = false

        seeMoreButton.setTitleColor(.tintColor, for: .normal)
        seeMoreButton.addTarget(self, action: #selector(toggleDescription), for: .touchUpInside)
        seeMoreButton.translatesAutoresizingMaskIntoConstraints = false

        descriptionView.translatesAutoresizingMaskIntoConstraints = false

        headerStackView.translatesAutoresizingMaskIntoConstraints = false

        buttonStackView.spacing = 8
        buttonStackView.axis = .horizontal

        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        continueButton.setImage(UIImage(
            systemName: mediaType == .video ? "play.fill" : "book.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        ), for: .normal)
        var configuration = UIButton.Configuration.plain()
        configuration.imagePadding = 8
        continueButton.configuration = configuration
        continueButton.setAttributedTitle(NSAttributedString(
            string: mediaType == .video ? "Begin Watching" : "Begin Reading",
            attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .bold)]
        ), for: .normal)
        continueButton.backgroundColor = self.tintColor
        continueButton.tintColor = .white
        continueButton.layer.cornerRadius = 10
        continueButton.clipsToBounds = true
        continueButton.addTarget(delegate, action: #selector(EntryHeaderViewDelegate.continueButtonPressed), for: .touchUpInside)

        bookmarkButton.translatesAutoresizingMaskIntoConstraints = false
        bookmarkButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        bookmarkButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        bookmarkButton.setImage(UIImage(
            systemName: "bookmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        ), for: .normal)
        bookmarkButton.backgroundColor = self.tintColor
        bookmarkButton.tintColor = .white
        bookmarkButton.layer.cornerRadius = 10
        bookmarkButton.clipsToBounds = true
        bookmarkButton.addTarget(delegate, action: #selector(EntryHeaderViewDelegate.bookmarkButtonPressed), for: .touchUpInside)

        linkButton.translatesAutoresizingMaskIntoConstraints = false
        linkButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        linkButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        linkButton.setImage(UIImage(
            systemName: "link.badge.plus",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        ), for: .normal)
        linkButton.backgroundColor = self.tintColor
        linkButton.tintColor = .white
        linkButton.layer.cornerRadius = 10
        linkButton.clipsToBounds = true
        linkButton.addTarget(delegate, action: #selector(EntryHeaderViewDelegate.linkButtonPressed), for: .touchUpInside)

        webViewButton.translatesAutoresizingMaskIntoConstraints = false
        webViewButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        webViewButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        webViewButton.setImage(UIImage(
            systemName: "globe",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        ), for: .normal)
        webViewButton.backgroundColor = self.tintColor
        webViewButton.tintColor = .white
        webViewButton.layer.cornerRadius = 10
        webViewButton.clipsToBounds = true
        webViewButton.addTarget(delegate, action: #selector(EntryHeaderViewDelegate.webViewButtonPressed), for: .touchUpInside)

        observers.append(
            NotificationCenter.default.addObserver(forName: .init(LibraryManager.Keys.libraries), object: nil, queue: nil) { [weak self] _ in
                guard let entry = self?.entry else { return }
                if LibraryManager.shared.library(forMediaType: mediaType)?.all.ids.contains(entry._id) == true {
                    Task { @MainActor in
                        self?.bookmarkButton.setImage(UIImage(
                            systemName: "bookmark.fill",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
                        ), for: .normal)
                    }
                } else {
                    Task { @MainActor in
                        self?.bookmarkButton.setImage(UIImage(
                            systemName: "bookmark",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
                        ), for: .normal)
                    }
                }
            }
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func setEntry(to entry: LocalEntry, with databaseEntry: Entry? = nil, history: History? = nil) {
        self.localEntry = entry
        self.entry = databaseEntry
        self.history = history

        self.subviews.forEach({ $0.removeFromSuperview() })

//        bannerImageView.contentMode = .scaleAspectFill
//        bannerImageView.clipsToBounds = true
//        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(bannerImageView)
//        bannerImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
//        bannerImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
//        bannerImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
//        bannerImageView.heightAnchor.constraint(equalToConstant: 350).isActive = true
//        if let url = entry.banners.first.flatMap({ URL(string: $0.image) }) {
//            ImagePipeline.shared.loadImage(with: url) { [weak self] result in
//                if case .success(let response) = result {
//                    self?.bannerImageView.image = response.image
//                }
//            }
//        }
//
//        bannerGradientLayer.colors = [ UIColor.clear.cgColor, UIColor.systemBackground.cgColor ]
//        bannerGradientLayer.locations = [ 0, 0.8 ]
//        bannerGradientLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 350)
//        bannerGradientLayer.needsDisplayOnBoundsChange = true
//        bannerImageView.layer.insertSublayer(bannerGradientLayer, at: 0)

        if let url = URL(string: entry.cover) {
            ImagePipeline.shared.loadImage(with: url) { [weak self] result in
                if case .success(let response) = result {
                    self?.coverImageView.image = response.image
                }
            }
        }

        titleCoverStackView.addArrangedSubview(coverImageView)

        titleView.text = entry.title
        titleStackView.addArrangedSubview(titleView)

        subtitleView.text = entry.staff.first
        titleStackView.addArrangedSubview(subtitleView)

        if let history {
            if let score = history.score {
                for (index, starImageView) in starImageViews.enumerated() {
                    starImageView.image = UIImage(
                        systemName: Int(round(score)) >= index * 2 + 2
                            ? "star.fill"
                            : Int(round(score)) >= index * 2 + 1 ? "star.leadinghalf.filled" : "star"
                    )
                    starImageView.tintColor = .label
                    starImageView.preferredSymbolConfiguration = .init(pointSize: 15, weight: .semibold)
                    starStackView.addArrangedSubview(starImageView)
                }
            } else {
                for starImageView in starImageViews {
                    starImageView.image = UIImage(systemName: "star")
                    starImageView.tintColor = .secondaryLabel
                    starImageView.preferredSymbolConfiguration = .init(pointSize: 15, weight: .semibold)
                    starStackView.addArrangedSubview(starImageView)
                }
            }
            starStackView.addArrangedSubview(starSpacerView)

            statusLabelView.text = history.status.prettyName

            statusStackView.addArrangedSubview(statusTitleView)
            statusStackView.addArrangedSubview(statusLabelView)
            statusStackView.addArrangedSubview(statusSpacerView)

            titleStackView.addArrangedSubview(statusStackView)
            titleStackView.addArrangedSubview(starStackView)
        }

        titleCoverStackView.addArrangedSubview(titleStackView)

        headerStackView.addArrangedSubview(titleCoverStackView)

        for tag in entry.tags {
            let backgroundView = UIView()
            backgroundView.backgroundColor = .secondarySystemFill
            backgroundView.layer.cornerRadius = 10
            backgroundView.clipsToBounds = true

            let labelView = UILabel()
            labelView.text = tag.uppercased()
            labelView.font = .systemFont(ofSize: 12, weight: .heavy)

            labelView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.addSubview(labelView)
            labelView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
            labelView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true

            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.widthAnchor.constraint(equalTo: labelView.widthAnchor, constant: 20).isActive = true
            backgroundView.heightAnchor.constraint(equalTo: labelView.heightAnchor, constant: 10).isActive = true
            tagStackView.addArrangedSubview(backgroundView)
        }

        tagScrollView.addSubview(tagStackView)
        tagStackView.leadingAnchor.constraint(equalTo: tagScrollView.leadingAnchor).isActive = true
        tagStackView.trailingAnchor.constraint(equalTo: tagScrollView.trailingAnchor).isActive = true
        tagStackView.topAnchor.constraint(equalTo: tagScrollView.topAnchor).isActive = true
        tagStackView.bottomAnchor.constraint(equalTo: tagScrollView.bottomAnchor).isActive = true

        tagScrollView.showsVerticalScrollIndicator = false
        tagScrollView.showsHorizontalScrollIndicator = false
        addSubview(tagScrollView)
        tagScrollView.heightAnchor.constraint(equalTo: tagStackView.heightAnchor).isActive = true

        headerStackView.addArrangedSubview(tagScrollView)

        if let description = entry.description {
            descriptionLabelView.text = description

            seeMoreButton.setAttributedTitle(
                NSAttributedString(string: "See More", attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .bold)]),
                for: .normal
            )

            descriptionView.addSubview(descriptionLabelView)
            descriptionView.addSubview(seeMoreButton)
            descriptionLabelView.topAnchor.constraint(equalTo: descriptionView.topAnchor).isActive = true
            descriptionLabelView.leadingAnchor.constraint(equalTo: descriptionView.leadingAnchor).isActive = true
            descriptionLabelView.trailingAnchor.constraint(equalTo: descriptionView.trailingAnchor).isActive = true
            seeMoreButton.topAnchor.constraint(equalTo: descriptionLabelView.bottomAnchor, constant: -5).isActive = true
            seeMoreButton.trailingAnchor.constraint(equalTo: descriptionView.trailingAnchor).isActive = true
            seeMoreButton.bottomAnchor.constraint(equalTo: descriptionView.bottomAnchor).isActive = true

            headerStackView.addArrangedSubview(descriptionView)
        }

        if let databaseEntry, LibraryManager.shared.library(forMediaType: mediaType)?.all.ids.contains(databaseEntry._id) == true {
            bookmarkButton.setImage(UIImage(
                systemName: "bookmark.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
            ), for: .normal)
        }

        buttonStackView.arrangedSubviews.forEach({ $0.removeFromSuperview() })

        buttonStackView.addArrangedSubview(continueButton)
        buttonStackView.addArrangedSubview(databaseEntry == nil ? linkButton : bookmarkButton)
        buttonStackView.addArrangedSubview(webViewButton)

        headerStackView.addArrangedSubview(buttonStackView)

        addSubview(headerStackView)
        self.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        self.headerStackView.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor).isActive = true
        self.headerStackView.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor).isActive = true
        self.heightAnchor.constraint(equalTo: self.headerStackView.heightAnchor).isActive = true
        self.invalidateIntrinsicContentSize()
        delegate?.sizeDidChange?()
    }

    @objc func toggleDescription() {
        if descriptionExpanded {
            descriptionLabelView.numberOfLines = 4
            seeMoreButton.setAttributedTitle(
                NSAttributedString(string: "See More", attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .bold)]),
                for: .normal
            )
        } else {
            descriptionLabelView.numberOfLines = 0
            seeMoreButton.setAttributedTitle(
                NSAttributedString(string: "See Less", attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .bold)]),
                for: .normal
            )
        }
        self.invalidateIntrinsicContentSize()
        descriptionExpanded = !descriptionExpanded
        delegate?.sizeDidChange?()
    }
}

@objc protocol EntryHeaderViewDelegate {
    @objc optional func webViewButtonPressed()
    @objc optional func linkButtonPressed()
    @objc optional func bookmarkButtonPressed()
    @objc optional func continueButtonPressed()
    @objc optional func sizeDidChange()
}
