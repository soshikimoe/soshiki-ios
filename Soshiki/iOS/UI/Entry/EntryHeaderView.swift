//
//  EntryHeaderView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/25/23.
//

import UIKit
import Nuke
import SafariServices

class EntryHeaderView: UIView {
    var observers: [NSObjectProtocol] = []

    let mediaType: MediaType
    var localEntry: LocalEntry?
    var entry: Entry?
    var linkUrl: URL? {
        didSet {
            self.linkButton.isEnabled = linkUrl != nil
        }
    }
//    let bannerImageView = UIImageView()
//    let bannerGradientLayer = CAGradientLayer()
    let headerStackView = UIStackView()
    let titleCoverStackView = UIStackView()
    let coverImageView = UIImageView()
    let titleStackView = UIStackView()
    let titleView = UILabel()
    let subtitleView = UILabel()
    let tagScrollView = UIScrollView()
    let tagStackView = UIStackView()
    let descriptionView = UILabel()
    let seeMoreButton = UIButton()
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
    var continueAction: (() -> Void)?

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

        titleView.font = .systemFont(ofSize: 22, weight: .heavy)
        titleView.numberOfLines = 3
        titleView.minimumScaleFactor = 0.5

        subtitleView.textColor = .secondaryLabel
        subtitleView.font = .systemFont(ofSize: 17)
        subtitleView.numberOfLines = 3
        subtitleView.minimumScaleFactor = 0.5

        tagStackView.axis = .horizontal
        tagStackView.spacing = 8
        tagStackView.translatesAutoresizingMaskIntoConstraints = false

        descriptionView.numberOfLines = 4
        descriptionView.font = .systemFont(ofSize: 15)

        seeMoreButton.setTitleColor(.tintColor, for: .normal)
        seeMoreButton.addTarget(self, action: #selector(toggleDescription), for: .touchUpInside)
        seeMoreButton.translatesAutoresizingMaskIntoConstraints = false

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
        continueButton.addTarget(self, action: #selector(continueButtonPressed), for: .touchUpInside)

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
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonPressed), for: .touchUpInside)

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
        linkButton.addTarget(self, action: #selector(linkButtonPressed), for: .touchUpInside)

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
        webViewButton.addTarget(self, action: #selector(webViewButtonPressed), for: .touchUpInside)

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

    func setEntry(to entry: LocalEntry, with databaseEntry: Entry? = nil) {
        self.localEntry = entry
        self.entry = databaseEntry

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
            descriptionView.text = description
            headerStackView.addArrangedSubview(descriptionView)

            seeMoreButton.setAttributedTitle(
                NSAttributedString(string: "See More", attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .bold)]),
                for: .normal
            )
            headerStackView.addArrangedSubview(seeMoreButton)
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
    }

    @objc func toggleDescription() {
        if descriptionExpanded {
            descriptionView.numberOfLines = 4
            seeMoreButton.setAttributedTitle(
                NSAttributedString(string: "See More", attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .bold)]),
                for: .normal
            )
        } else {
            descriptionView.numberOfLines = 0
            seeMoreButton.setAttributedTitle(
                NSAttributedString(string: "See Less", attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .bold)]),
                for: .normal
            )
        }
        descriptionExpanded = !descriptionExpanded
    }

    @objc func continueButtonPressed() {
        continueAction?()
    }

    @objc func bookmarkButtonPressed() {
        guard let entry else { return }
        if LibraryManager.shared.library(forMediaType: mediaType)?.all.ids.contains(entry._id) == true {
            Task {
                await LibraryManager.shared.remove(entry: entry)
            }
        } else {
            Task {
                await LibraryManager.shared.add(entry: entry)
            }
        }
    }

    @objc func linkButtonPressed() {

    }

    @objc func webViewButtonPressed() {
        if let linkUrl {
            self.nearestViewController?.present(SFSafariViewController(url: linkUrl), animated: true)
        }
    }
}
