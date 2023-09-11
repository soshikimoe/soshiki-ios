//
//  ExpandableSectionHeaderView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/9/23.
//

import UIKit

class ExpandableSectionHeaderView: UICollectionReusableView {
    let titleLabel: UILabel
    let chevronImageView: UIImageView

    let contentStackView: UIStackView

    let gestureRecognizer: UITapGestureRecognizer

    var expandAction: () -> Void

    override init(frame: CGRect) {
        self.titleLabel = UILabel()
        self.chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        self.contentStackView = UIStackView()

        self.gestureRecognizer = UITapGestureRecognizer()

        self.expandAction = {}

        super.init(frame: frame)

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

        self.gestureRecognizer.numberOfTapsRequired = 1
        self.gestureRecognizer.numberOfTouchesRequired = 1
        self.gestureRecognizer.addTarget(self, action: #selector(viewPressed))

        self.addGestureRecognizer(self.gestureRecognizer)
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

    func setExpandable(_ expandable: Bool) {
        self.chevronImageView.isHidden = !expandable
    }

    func setExpandAction(_ action: @escaping () -> Void) {
        self.expandAction = action
    }

    @objc func viewPressed() {
        if !self.chevronImageView.isHidden {
            self.expandAction()
        }
    }
}
