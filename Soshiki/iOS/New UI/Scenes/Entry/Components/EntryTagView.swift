//
//  EntryTagView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 4/9/23.
//

import UIKit

class EntryTagView: UIStackView {
    let imageView: UIImageView?
    let label: UILabel

    init(title: String, image: UIImage? = nil, color: UIColor = .white) {
        self.label = UILabel()
        if let image {
            self.imageView = UIImageView(image: image)
            self.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
            self.imageView?.tintColor = color
        } else {
            self.imageView = nil
        }

        super.init(frame: .zero)

        self.backgroundColor = UIColor(white: 30/256, alpha: 1)
        self.layer.cornerRadius = 10
        self.clipsToBounds = true

        self.label.text = title.uppercased()
        self.label.font = .systemFont(ofSize: 12, weight: .heavy)
        self.label.textColor = .white

        self.spacing = 3
        self.axis = .horizontal
        self.alignment = .center
        self.isLayoutMarginsRelativeArrangement = true
        self.layoutMargins = UIEdgeInsets(horizontal: 10, vertical: 5)

        if let imageView = self.imageView {
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addArrangedSubview(imageView)
        }

        self.label.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(self.label)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
