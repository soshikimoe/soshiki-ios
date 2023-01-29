//
//  Collection.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/19/22.
//

import Foundation

extension Collection where Element: StringRepresentable {
    func graphql(_ parentName: String) -> String {
        "\(parentName) { \(self.map({ $0.rawValue }).joined(separator: ", ")) }"
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Collection where Element: Equatable, Self.Index == Int {
    func removingDuplicates() -> Self {
        self.enumerated().filter({ self.firstIndex(of: $0.element) == $0.offset }).map({ $0.element }) as? Self ?? self
    }
}
