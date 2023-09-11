//
//  ImageCellNodeResizeDelegate.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/23/23.
//

import AsyncDisplayKit
import Foundation

protocol ImageCellNodeResizeDelegate: AnyObject {
    func willResize(from currentSize: CGSize, to newSize: CGSize, at indexPath: IndexPath)
}
