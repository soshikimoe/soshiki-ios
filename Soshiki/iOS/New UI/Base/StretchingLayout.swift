//
//  StretchingLayout.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/8/23.
//

import UIKit

class StretchingCollectionViewCompositionalLayout: UICollectionViewCompositionalLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutAttributes = super.layoutAttributesForElements(in: rect) else { return nil }

        if let collectionView,
           let viewController = collectionView.nearestViewController as? StretchingLayoutParent,
           collectionView.contentOffset.y <= 0 {
            for layoutAttribute in layoutAttributes where
                layoutAttribute.representedElementKind == UICollectionView.elementKindSectionHeader && layoutAttribute.indexPath.section == 0 {
                layoutAttribute.frame = CGRect(
                    x: 0,
                    y: collectionView.contentOffset.y,
                    width: collectionView.frame.width,
                    height: viewController.headerHeight - collectionView.contentOffset.y
                )
            }
        }

        return layoutAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { true }
}

class StretchingCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutAttributes = super.layoutAttributesForElements(in: rect) else { return nil }

        if let collectionView,
           let viewController = collectionView.nearestViewController as? StretchingLayoutParent,
           collectionView.contentOffset.y <= 0 {
            for layoutAttribute in layoutAttributes where
                layoutAttribute.representedElementKind == UICollectionView.elementKindSectionHeader && layoutAttribute.indexPath.section == 0 {
                layoutAttribute.frame = CGRect(
                    x: 0,
                    y: collectionView.contentOffset.y,
                    width: collectionView.frame.width,
                    height: viewController.headerHeight - collectionView.contentOffset.y
                )
            }
        }

        return layoutAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { true }
}

protocol StretchingLayoutParent: AnyObject {
    var headerHeight: CGFloat { get }
}
