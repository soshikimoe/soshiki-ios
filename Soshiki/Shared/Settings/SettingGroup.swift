//
//  SettingGroup.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/5/23.
//

import Foundation

struct SettingGroup {
    let id: String
    let header: String?
    let footer: String?
    let items: [any SettingItem]

    init(id: String, header: String? = nil, footer: String? = nil, items: [any SettingItem]) {
        self.id = id
        self.header = header
        self.footer = footer
        self.items = items
    }
}
