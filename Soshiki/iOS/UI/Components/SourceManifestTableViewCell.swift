//
//  SourceManifestTableViewCell.swift
//  Soshiki
//
//  Created by Jim Phieffer on 5/12/23.
//

import UIKit
import Nuke

class SourceManifestTableViewCell: UITableViewCell {
    let manifest: SourceListSourceManifest
    let baseUrl: URL

    let iconView = UIImageView()
    let titleView = UILabel()
    let subtitleView = UILabel()

    var button: SourceButton?

    init(
        manifest: SourceListSourceManifest,
        baseUrl: URL,
        reuseIdentifier: String?,
        buttonText: String? = nil,
        buttonAction: @escaping () -> Void = {}
    ) {
        self.manifest = manifest
        self.baseUrl = baseUrl

        if let buttonText {
            self.button = SourceButton(buttonText, block: buttonAction)
        }

        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        var leadingAnchor = self.contentView.layoutMarginsGuide.leadingAnchor

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

        ImagePipeline.shared.loadImage(
            with: baseUrl
                .deletingLastPathComponent()
                .appendingPathComponent(manifest.path)
                .deletingLastPathComponent()
                .appendingPathComponent("res")
                .appendingPathComponent(manifest.icon)
        ) { [weak self] result in
            if case let .success(response) = result {
                self?.iconView.image = response.image
            }
        }

        titleView.text = manifest.name
        titleView.font = .systemFont(ofSize: 17, weight: .semibold)
        contentView.addSubview(titleView)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor).isActive = true
        titleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true

        subtitleView.text = manifest.author
        subtitleView.font = .systemFont(ofSize: 15)
        subtitleView.textColor = .secondaryLabel
        contentView.addSubview(subtitleView)
        subtitleView.translatesAutoresizingMaskIntoConstraints = false
        subtitleView.topAnchor.constraint(equalTo: titleView.bottomAnchor).isActive = true
        subtitleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true

        if let button = self.button {
            button.translatesAutoresizingMaskIntoConstraints = false
            self.accessoryView = button
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
