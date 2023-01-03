//
//  Float.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/2/22.
//

import Foundation

extension Float {
    func toTruncatedString() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16
        return String(formatter.string(from: number) ?? "")
    }
}
