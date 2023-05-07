//
//  ExpandableSectionHeaderView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/9/23.
//

import UIKit

class ExpandableSectionHeaderView: UIView {
    let titleLabel: UILabel
    let chevronImageView: UIImageView

    let contentStackView: UIStackView

    init() {
        self.titleLabel = UILabel()
        self.chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        self.contentStackView = UIStackView()

        super.init(frame: .zero)

        configureSubviews()
        applyConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureSubviews() {
        self.contentStackView.axis = .horizontal
        self.contentStackView.alignment = .center
        self.contentStackView.spacing = 4

        self.titleLabel.font = .systemFont(ofSize: 25, weight: .bold)

        self.chevronImageView.tintColor = .secondaryLabel
        self.chevronImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(weight: .heavy)

        self.contentStackView.addArrangedSubview(self.titleLabel)
        self.contentStackView.addArrangedSubview(self.chevronImageView)

        self.contentStackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentStackView)
    }

    func applyConstraints() {
        NSLayoutConstraint.activate([
            self.contentStackView.topAnchor.constraint(equalTo: self.topAnchor),
            self.contentStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.contentStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    func setTitle(to title: String) {
        self.titleLabel.text = title
    }
}
