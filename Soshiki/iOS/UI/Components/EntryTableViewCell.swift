//
//  EntryTableViewCell.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/1/23.
//

import UIKit
import Nuke

class EntryTableViewCell: UITableViewCell {
    let coverView = UIImageView()
    let titleView = UILabel()
    let subtitleView = UILabel()

    init(entry: Entry, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        var leadingAnchor = self.contentView.layoutMarginsGuide.leadingAnchor

        if let cover = entry.covers.first {
            contentView.addSubview(coverView)
            coverView.translatesAutoresizingMaskIntoConstraints = false
            coverView.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor).isActive = true
            coverView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
            coverView.widthAnchor.constraint(equalToConstant: 50).isActive = true
            coverView.heightAnchor.constraint(equalToConstant: 75).isActive = true
            coverView.layer.borderWidth = 0.25
            coverView.layer.borderColor = UIColor.gray.cgColor
            coverView.layer.cornerRadius = 10
            coverView.layer.masksToBounds = true
            leadingAnchor = coverView.trailingAnchor

            Task {
                if let url = URL(string: cover.image) {
                    ImagePipeline.shared.loadImage(with: url) { [weak self] result in
                        if case .success(let response) = result {
                            self?.coverView.image = response.image
                        }
                    }
                }
            }
        }

        titleView.text = entry.title
        titleView.font = .systemFont(ofSize: 17, weight: .semibold)
        titleView.numberOfLines = 2
        titleView.minimumScaleFactor = 0.5
        contentView.addSubview(titleView)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor).isActive = true
        titleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        titleView.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor).isActive = true

        if let person = entry.staff.first {
            subtitleView.text = person.name
            subtitleView.font = .systemFont(ofSize: 15)
            subtitleView.textColor = .secondaryLabel
            contentView.addSubview(subtitleView)
            subtitleView.translatesAutoresizingMaskIntoConstraints = false
            subtitleView.topAnchor.constraint(equalTo: titleView.bottomAnchor).isActive = true
            subtitleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
