//
//  Int.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/2/23.
//

extension Int {
    func toMinuteSecondString() -> String {
        "\(self / 60):\((self % 60 < 10) ? "0\(self % 60)" : "\(self % 60)")"
    }
}
