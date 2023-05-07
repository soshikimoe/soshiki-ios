//
//  ResizeListeningImageView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 4/2/23.
//

import UIKit

class ResizeListeningImageView: UIImageView {
    var delegate: ResizeListeningImageViewDelegate?

    override var bounds: CGRect {
        didSet {
            self.delegate?.boundsDidChange?(to: self.bounds)
        }
    }

    override var frame: CGRect {
        didSet {
            self.delegate?.frameDidChange?(to: self.frame)
        }
    }
}

@objc protocol ResizeListeningImageViewDelegate: AnyObject {
    @objc optional func boundsDidChange(to bounds: CGRect)
    @objc optional func frameDidChange(to frame: CGRect)
}
