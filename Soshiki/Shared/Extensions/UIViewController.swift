//
//  UIViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/25/22.
//

import UIKit

extension UIViewController {
    convenience init(_ view: UIView) {
        self.init()
        self.view = view
    }
}
