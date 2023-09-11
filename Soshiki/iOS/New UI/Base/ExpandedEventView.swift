//
//  ExpandedEventView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/26/23.
//

import UIKit

class ExpandedEventView: UIView {
    var eventEdgeInsets: UIEdgeInsets = .zero

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let origin = self.convert(self.bounds.origin, to: UIScreen.main.coordinateSpace)
        return CGRect(
            x: origin.x - eventEdgeInsets.left,
            y: origin.y - eventEdgeInsets.top,
            width: self.bounds.width + eventEdgeInsets.left + eventEdgeInsets.right,
            height: self.bounds.height + eventEdgeInsets.top + eventEdgeInsets.bottom
        ).contains(point)
    }
}
