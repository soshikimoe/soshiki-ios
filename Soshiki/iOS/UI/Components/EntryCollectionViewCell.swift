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

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setEntry(entry: LocalEntry) {
        self.contentView.layer.cornerRadius = 10
        self.contentView.clipsToBounds = true

        self.contentView.layer.borderWidth = 0.25
        self.contentView.layer.borderColor = UIColor.gray.cgColor

        gradientLayer.colors = [ UIColor.clear.cgColor, UIColor(white: 0, alpha: 0.8).cgColor ]
        gradientLayer.frame = self.contentView.bounds
        gradientLayer.cornerRadius = 10
        gradientLayer.needsDisplayOnBoundsChange = true
        gradientLayer.locations = [ 0.5, 1 ]
        imageView.layer.insertSublayer(gradientLayer, at: 0)

        imageView.image = nil
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true

        titleView.text = entry.title
        titleView.font = .systemFont(ofSize: 16, weight: .bold)
        titleView.textColor = .white
        titleView.numberOfLines = 3
        titleView.textAlignment = .left
        titleView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(titleView)
        titleView.layoutMargins = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        titleView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        titleView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        titleView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true

        if let url = URL(string: entry.cover) {
            ImagePipeline.shared.loadImage(with: url) { [weak self] result in
                if case .success(let response) = result {
                    self?.imageView.image = response.image
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.frame = self.contentView.bounds
    }
}
