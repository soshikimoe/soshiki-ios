//
//  String.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/19/22.
//

extension String {
    func truncateToWord(maxLength: Int) -> String {
        self.count > maxLength ? String(self.enumerated().reversed().drop(while: { index, character in
            character != " " || index >= maxLength
        }).map({ $0.1 }).reversed().dropLast(1)) + "…" : self
    }
}

//
//  Adapted from https://stackoverflow.com/a/26845710/7829684
//

extension String {
    static func random(length: Int = 16) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map({ _ in letters.randomElement()! }))
    }
}
