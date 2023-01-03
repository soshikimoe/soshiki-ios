//
//  SoshikiAPI.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/15/22.
//

import Foundation

class SoshikiAPI {
    static let baseUrl = "https://graphql.soshiki.moe/v1/"

    var token: String {
        get {
            UserDefaults.standard.string(forKey: "account.token") ?? ""
        } set {
            UserDefaults.standard.set(newValue, forKey: "account.token")
        }
    }

    static let shared = SoshikiAPI()

    static let baseLibrariesQuery: [LibraryOutput] = [
        .mediaType,
        .categories([
            .name,
            .entries([
                .entry(baseEntriesQuery)
            ])
        ])
    ]

    static let baseEntriesQuery: [EntryOutput] = [
        .id,
        .info([
            .title,
            .cover,
            .anilist([
                .title([
                    .english,
                    .romaji
                ]),
                .staff([
                    .name([
                        .full
                    ])
                ]),
                .coverImage([
                    .large,
                    .color
                ]),
                .bannerImage,
                .description
            ]),
            .mal([
                .synopsis
            ])
        ]),
        .platforms([
            .name,
            .sources([
                .id,
                .name
            ])
        ])
    ]
}
