//
//  ColorPickerTableViewCell.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/28/23.
//

import UIKit

class ColorPickerTableViewCell: UITableViewCell {
    init(title: String, colorWell: UIColorWell, reuseIdentifier: String) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        var content = self.defaultContentConfiguration()
        content.text = title
        self.contentConfiguration = content

        colorWell.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(colorWell)
        colorWell.topAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.topAnchor).isActive = true
        colorWell.bottomAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        colorWell.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
