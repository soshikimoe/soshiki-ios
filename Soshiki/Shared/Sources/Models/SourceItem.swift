//
//  SourceItem.swift
//  Soshiki
//
//  Created by Jim Phieffer on 4/1/23.
//

import Foundation

struct SourceItem: Identifiable, Hashable {
    let id: String
    let group: Double?
    let number: Double
    let name: String?
    let info: String?
    let thumbnail: String?
    let timestamp: Double?
    let mediaType: MediaType

    init(
        id: String,
        group: Double? = nil,
        number: Double,
        name: String? = nil,
        info: String? = nil,
        thumbnail: String?,
        timestamp: Double?,
        mediaType: MediaType
    ) {
        self.id = id
        self.group = group
        self.number = number
        self.name = name
        self.info = info
        self.thumbnail = thumbnail
        self.timestamp = timestamp
        self.mediaType = mediaType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
