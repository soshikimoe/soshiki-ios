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

//
//  From https://sarunw.com/posts/how-to-compare-two-app-version-strings-in-swift/
//

extension String {
    func versionCompare(_ otherVersion: String) -> ComparisonResult {
        let versionDelimiter = "."

        var versionComponents = self.components(separatedBy: versionDelimiter)
        var otherVersionComponents = otherVersion.components(separatedBy: versionDelimiter)

        let zeroDiff = versionComponents.count - otherVersionComponents.count

        if zeroDiff == 0 {
            return self.compare(otherVersion, options: .numeric)
        } else {
            let zeros = Array(repeating: "0", count: abs(zeroDiff))
            if zeroDiff > 0 {
                otherVersionComponents.append(contentsOf: zeros)
            } else {
                versionComponents.append(contentsOf: zeros)
            }
            return versionComponents.joined(separator: versionDelimiter)
                .compare(otherVersionComponents.joined(separator: versionDelimiter), options: .numeric)
        }
    }
}
