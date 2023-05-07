//
//  NSDirectionalEdgeInsets.swift
//  Soshiki
//
//  Created by Jim Phieffer on 4/1/23.
//

import UIKit

extension NSDirectionalEdgeInsets {
    init(top: CGFloat? = nil, left: CGFloat? = nil, bottom: CGFloat? = nil, right: CGFloat? = nil) {
        self.init(top: top ?? 0, leading: left ?? 0, bottom: bottom ?? 0, trailing: right ?? 0)
    }

    init(horizontal: CGFloat? = nil, vertical: CGFloat? = nil) {
        self.init(top: vertical ?? 0, left: horizontal ?? 0, bottom: vertical ?? 0, right: horizontal ?? 0)
    }

    init(all: CGFloat? = nil) {
        self.init(top: all ?? 0, left: all ?? 0, bottom: all ?? 0, right: all ?? 0)
    }
}
