//
//  Source.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/21/22.
//

import Foundation

protocol Source<EntryType>: Equatable, Identifiable {
    associatedtype EntryType: Entry
    var id: String { get }
    var name: String { get }

    func getListing(listing: SourceListing, page: Int) async -> SourceResults<EntryType>?
    func getSearchResults(query: String, page: Int, filters: [SourceFilter]) async -> SourceResults<EntryType>?
    func getEntry(id: String) async -> EntryType?
    func getFilters() async -> [SourceFilterGroup]
    func getListings() async -> [SourceListing]
    func getSettings() async -> [SourceFilterGroup]
}

protocol NetworkSource: Source {
    var author: String { get }
    var version: String { get }
    var image: URL { get }
}
