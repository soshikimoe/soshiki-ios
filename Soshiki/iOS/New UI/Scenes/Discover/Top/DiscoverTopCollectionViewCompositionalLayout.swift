//
//  DiscoverTopCollectionViewCompositionalLayout.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/10/23.
//

import UIKit

class DiscoverTopCollectionViewCompositionalLayout: UICollectionViewCompositionalLayout {
    override init(section: NSCollectionLayoutSection, configuration: UICollectionViewCompositionalLayoutConfiguration) {
        super.init(section: section, configuration: configuration)
        self.register(DiscoverSeparatorView.self, forDecorationViewOfKind: "DiscoverSeparatorView")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutAttributes = super.layoutAttributesForElements(in: rect) else { return nil }

        var decorationAttributes: [UICollectionViewLayoutAttributes] = []

        if let collectionView, collectionView.contentOffset.y <= 0 {
            for layoutAttribute in layoutAttributes where layoutAttribute.indexPath.item % 3 != 0 { // bottom 2 elements per column
                let separatorAttribute = UICollectionViewLayoutAttributes(
                    forDecorationViewOfKind: "DiscoverSeparatorView",
                    with: layoutAttribute.indexPath
                )

                let offset = layoutAttribute.frame.height * 2 / 3 + 16 + 30 + 16
                separatorAttribute.frame = CGRect(
                    x: layoutAttribute.frame.minX + offset,
                    y: layoutAttribute.frame.minY - 0.25 - 8,
                    width: layoutAttribute.frame.width - offset,
                    height: 0.5
                )
                separatorAttribute.zIndex = .max

                decorationAttributes.append(separatorAttribute)
            }
        }

        return layoutAttributes + decorationAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { true }
}
