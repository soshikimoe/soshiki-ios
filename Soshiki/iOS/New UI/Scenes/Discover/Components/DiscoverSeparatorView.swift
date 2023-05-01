//
//  DiscoverSeparatorView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/10/23.
//

import UIKit

class DiscoverSeparatorView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .opaqueSeparator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        self.frame = layoutAttributes.frame
    }
}
