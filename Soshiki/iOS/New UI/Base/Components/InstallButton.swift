//
//  InstallButton.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/20/23.
//

import UIKit

class InstallButton: UIButton {
    override var frame: CGRect {
        didSet {
            self.configuration?.background.cornerRadius = self.frame.height / 2
        }
    }

    let handler: () -> Void

    init(_ title: String, handler: @escaping () -> Void) {
        self.handler = handler

        super.init(frame: .zero)

        self.setTitle(title, for: .normal)
        self.setAttributedTitle(
            NSAttributedString(
                string: title,
                attributes: [ .font: UIFont.systemFont(ofSize: 13, weight: .bold) ]
            ),
            for: .normal
        )

        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(horizontal: 10, vertical: 5)
        configuration.background.backgroundColor = .tertiarySystemGroupedBackground
        self.configuration = configuration

        self.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)

        self.sizeToFit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func buttonClicked() {
        self.handler()
    }
}
