//
//  EntryCollectionViewCell.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/24/23.
//

import UIKit
import Nuke

class EntryCollectionViewCell: UICollectionViewCell {
    let imageView = UIImageView()
    let titleView = UILabel()
    let gradientLayer = CAGradientLayer()
    let notificationBadgeView = UILabel()
    let notificationBadgePaddingView = UIView()
    let unreadBadgeView = UILabel()
    let unreadBadgePaddingView = UIView()
    let badgeStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.layer.cornerRadius = 10
        self.contentView.clipsToBounds = true
        self.contentView.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        self.contentView.layer.borderWidth = 0.25
        self.contentView.layer.borderColor = UIColor.gray.cgColor

        gradientLayer.colors = [ UIColor.clear.cgColor, UIColor(white: 0, alpha: 0.8).cgColor ]
        gradientLayer.frame = self.contentView.bounds
        gradientLayer.cornerRadius = 10
        gradientLayer.needsDisplayOnBoundsChange = true
        gradientLayer.locations = [ 0.5, 1 ]
        imageView.layer.insertSublayer(gradientLayer, at: 0)

        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true

        titleView.font = .systemFont(ofSize: 16, weight: .bold)
        titleView.textColor = .white
        titleView.numberOfLines = 3
        titleView.textAlignment = .left
        titleView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(titleView)
        titleView.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        titleView.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        titleView.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor).isActive = true

        unreadBadgeView.font = .systemFont(ofSize: 15, weight: .bold)
        unreadBadgeView.textColor = .white
        unreadBadgeView.translatesAutoresizingMaskIntoConstraints = false
        unreadBadgePaddingView.backgroundColor = .systemRed
        unreadBadgePaddingView.layer.cornerRadius = 5
        unreadBadgePaddingView.clipsToBounds = true
        unreadBadgePaddingView.translatesAutoresizingMaskIntoConstraints = false
        unreadBadgePaddingView.addSubview(unreadBadgeView)
        unreadBadgePaddingView.heightAnchor.constraint(equalTo: unreadBadgeView.heightAnchor, constant: 5).isActive = true
        unreadBadgePaddingView.widthAnchor.constraint(equalTo: unreadBadgeView.widthAnchor, constant: 10).isActive = true
        unreadBadgeView.centerXAnchor.constraint(equalTo: unreadBadgePaddingView.centerXAnchor).isActive = true
        unreadBadgeView.centerYAnchor.constraint(equalTo: unreadBadgePaddingView.centerYAnchor).isActive = true

        notificationBadgeView.font = .systemFont(ofSize: 15, weight: .bold)
        notificationBadgeView.textColor = .white
        notificationBadgeView.translatesAutoresizingMaskIntoConstraints = false
        notificationBadgePaddingView.backgroundColor = .systemBlue
        notificationBadgePaddingView.layer.cornerRadius = 5
        notificationBadgePaddingView.clipsToBounds = true
        notificationBadgePaddingView.translatesAutoresizingMaskIntoConstraints = false
        notificationBadgePaddingView.addSubview(notificationBadgeView)
        notificationBadgePaddingView.heightAnchor.constraint(equalTo: notificationBadgeView.heightAnchor, constant: 5).isActive = true
        notificationBadgePaddingView.widthAnchor.constraint(equalTo: notificationBadgeView.widthAnchor, constant: 10).isActive = true
        notificationBadgeView.centerXAnchor.constraint(equalTo: notificationBadgePaddingView.centerXAnchor).isActive = true
        notificationBadgeView.centerYAnchor.constraint(equalTo: notificationBadgePaddingView.centerYAnchor).isActive = true

        badgeStackView.spacing = 8
        badgeStackView.axis = .horizontal
        badgeStackView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(badgeStackView)
        badgeStackView.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor).isActive = true
        badgeStackView.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setEntry(entry: LocalEntry) {
        gradientLayer.frame = self.contentView.bounds

        imageView.image = nil

        titleView.text = entry.title

        if let url = URL(string: entry.cover) {
            ImagePipeline.shared.loadImage(with: url) { [weak self] result in
                if case .success(let response) = result {
                    self?.imageView.image = response.image
                }
            }
        }
    }

    func setNotificationBadge(to badge: Int) {
        if badge > 0 {
            if notificationBadgeView.text.flatMap({ $0.isEmpty }) != false {
                badgeStackView.addArrangedSubview(notificationBadgePaddingView)
            }
            notificationBadgeView.text = "\(badge)"
        } else {
            notificationBadgeView.text = nil
            badgeStackView.removeArrangedSubview(notificationBadgeView)
        }
    }

    func setUnreadBadge(to badge: Int) {
        if badge > 0 {
            if unreadBadgeView.text == nil {
                badgeStackView.insertArrangedSubview(unreadBadgeView, at: 0)
            }
            unreadBadgeView.text = "\(badge)"
        } else {
            unreadBadgeView.text = nil
            badgeStackView.removeArrangedSubview(unreadBadgeView)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.frame = self.contentView.bounds
    }
}
