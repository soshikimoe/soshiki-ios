//
//  BackgroundView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/26/23.
//

import UIKit

class BackgroundView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for subview in self.subviews {
            if let view = recursiveSearch(view: subview, point: point, event: event) {
                return view
            }
        }

        if let view = super.hitTest(point, with: event), view != self {
            return view
        }

        return nil
    }

    func recursiveSearch(view: UIView, point: CGPoint, event: UIEvent?) -> UIView? {
        for subview in view.subviews {
            if let view = recursiveSearch(view: subview, point: point, event: event) {
                return view
            }
        }

        if view.point(inside: point, with: event) {
            return view
        }

        return nil
    }
}
