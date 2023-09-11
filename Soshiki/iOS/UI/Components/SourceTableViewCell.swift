//
//  SourceCellView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/23/23.
//

import UIKit

class SourceTableViewCell: UITableViewCell {
    let iconView = UIImageView()
    let titleView = UILabel()
    let subtitleView = UILabel()

    init(source: any Source, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        var leadingAnchor = self.contentView.layoutMarginsGuide.leadingAnchor

        if let icon = (source as? any NetworkSource)?.image {
            iconView.image = UIImage(contentsOfFile: icon.path)
            contentView.addSubview(iconView)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor).isActive = true
            iconView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
            iconView.widthAnchor.constraint(equalToConstant: 50).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 50).isActive = true
            iconView.layer.borderWidth = 0.25
            iconView.layer.borderColor = UIColor.gray.cgColor
            iconView.layer.cornerRadius = 10
            iconView.layer.masksToBounds = true
            leadingAnchor = iconView.trailingAnchor
        }

        titleView.text = source.name
        titleView.font = .systemFont(ofSize: 17, weight: .semibold)
        contentView.addSubview(titleView)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor).isActive = true
        titleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true

        if let author = (source as? any NetworkSource)?.author {
            subtitleView.text = author
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
