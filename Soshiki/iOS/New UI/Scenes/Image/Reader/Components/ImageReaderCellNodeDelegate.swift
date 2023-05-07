//
//  ReaderCellNodeDelegate.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/23/23.
//

import AsyncDisplayKit
import Foundation

@objc protocol ImageReaderCellNodeDelegate: AnyObject {
    @objc optional func didEnterVisibleState(at indexPath: IndexPath)
    @objc optional func didExitVisibleState(at indexPath: IndexPath)
}
