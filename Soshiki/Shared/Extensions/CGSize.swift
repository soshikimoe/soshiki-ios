//
//  CGSize.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/24/23.
//

import Foundation

extension CGSize {
    var aspectRatio: CGFloat {
        self.width / self.height
    }
}
