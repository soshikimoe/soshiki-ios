//
//  Numeric.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/28/23.
//

import Foundation

extension Numeric where Self: Comparable {
    func clamped(to range: Range<Self>) -> Self {
        self < range.lowerBound ? range.lowerBound : self >= range.upperBound ? range.upperBound : self
    }

    func clamped(to range: ClosedRange<Self>) -> Self {
        self < range.lowerBound ? range.lowerBound : self > range.upperBound ? range.upperBound : self
    }

    func equals(_ number: Self, withTolerance tolerance: Self) -> Bool {
        self >= number - tolerance && self <= number + tolerance
    }
}
