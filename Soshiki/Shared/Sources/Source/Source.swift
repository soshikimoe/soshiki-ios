//
//  Source.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/21/22.
//

import Foundation
import JavaScriptCore

protocol Source: Equatable, Identifiable {
    var id: String { get }
    var name: String { get }

    func getListing(listing: SourceListing, previousResultsInfo: SourceEntryResultsInfo?) async -> SourceEntryResults?
    func getSearchResults(query: String, filters: [any SourceFilter], previousResultsInfo: SourceEntryResultsInfo?) async -> SourceEntryResults?
    func getEntry(id: String) async -> SourceEntry?
    func getFilters() async -> [any SourceFilter]
    func getListings() async -> [SourceListing]
    func getSettings() async -> [any SourceFilter]
}

protocol NetworkSource: Source {
    var author: String { get }
    var version: String { get }
    var image: URL { get }
}
