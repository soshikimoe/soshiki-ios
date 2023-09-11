//
//  NSLayoutConstraint.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/16/23.
//

import UIKit

extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}
