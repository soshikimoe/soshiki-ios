//
//  LocalSource.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/16/23.
//

import Foundation

protocol LocalSource: Source {
    func importPart(_ url: URL, number partNumber: Double, addingTo entryId: String)
    func importPart(_ url: URL, number partNumber: Double, withTitle title: String)
    func importFull(_ url: URL)
    func delete(id: String)
}
