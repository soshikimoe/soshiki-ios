//
//  DiscoverFeaturedPageControlReusableView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/12/23.
//

import Foundation
import UIKit

class DiscoverFeaturedPageControlReusableView: UICollectionReusableView {
    let pageControl: UIPageControl

    override init(frame: CGRect) {
        self.pageControl = UIPageControl()

        super.init(frame: frame)

        self.pageControl.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.pageControl)

        NSLayoutConstraint.activate([
            self.pageControl.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.pageControl.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
