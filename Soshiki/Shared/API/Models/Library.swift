//
//  Library.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/4/23.
//

import Foundation

struct Library: Codable {
    let ids: [String]
}

struct LibraryCategory: Codable {
    let id: String
    let name: String
    let ids: [String]
}

struct FullLibrary: Codable {
    let all: Library
    let categories: [LibraryCategory]
}

struct Libraries: Codable {
    let text: FullLibrary
    let image: FullLibrary
    let video: FullLibrary
}
