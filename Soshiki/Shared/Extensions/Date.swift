//
//  Date.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/20/23.
//

import Foundation

extension Date {
    func hyphenated() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat =  "yyyy-MM-dd-HH-mm-ss"
        return formatter.string(from: self)
    }
}
