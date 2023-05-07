//
//  GestureRecognizingNavigationController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 4/30/23.
//

import UIKit

class GestureRecognizingNavigationController: UINavigationController {
    override func viewDidLoad() {
        self.interactivePopGestureRecognizer?.delegate = self
    }
}

extension GestureRecognizingNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
