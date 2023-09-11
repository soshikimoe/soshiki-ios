//
//  ImageReaderFlowLayout.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/23/23.
//

import AsyncDisplayKit
import Foundation

class ImageReaderFlowLayout: UICollectionViewFlowLayout {
    var needsOffsetChange: Bool = false {
        didSet {
            if self.needsOffsetChange {
                self.cachedCollectionViewContentSize = self.collectionViewContentSize
            } else {
                self.cachedCollectionViewContentSize = nil
            }
        }
    }

    private var cachedCollectionViewContentSize: CGSize?

    override func prepare() {
        super.prepare()

        if let collectionView = self.collectionView,
           let cachedCollectionViewContentSize = self.cachedCollectionViewContentSize {
            let horizontalDifference = self.collectionViewContentSize.width - cachedCollectionViewContentSize.width
            let verticalDifference = self.collectionViewContentSize.height - cachedCollectionViewContentSize.height

            collectionView.setContentOffset(
                CGPoint(
                    x: collectionView.contentOffset.x + horizontalDifference,
                    y: collectionView.contentOffset.y + verticalDifference
                ),
                animated: false
            )

            self.needsOffsetChange = false
        }
    }
}
