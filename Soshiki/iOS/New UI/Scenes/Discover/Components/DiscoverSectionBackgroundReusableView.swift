//
//  DiscoverSectionBackgroundReusableView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/12/23.
//

import Foundation
import UIKit

class DiscoverSectionBackgroundReusableView: UICollectionReusableView {
    let gradientLayer: CAGradientLayer

    override var bounds: CGRect {
        didSet {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0)
            self.gradientLayer.frame = self.bounds
            CATransaction.commit()
        }
    }

    override init(frame: CGRect) {
        self.gradientLayer = CAGradientLayer()

        super.init(frame: frame)

        self.gradientLayer.colors = [ UIColor.clear.cgColor, UIColor.systemGray6.cgColor ]
        self.gradientLayer.locations = [ 0, 1 ]
        self.gradientLayer.frame = self.bounds
        self.gradientLayer.needsDisplayOnBoundsChange = true

        self.layer.insertSublayer(self.gradientLayer, at: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
