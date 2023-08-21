//
//  SourceFilter.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/28/22.
//

import Foundation
import JavaScriptCore

enum BaseFilterCodingKeys: String, CodingKey {
    case type
}

enum FilterType: String, Codable {
    case text = "TEXT"
    case toggle = "TOGGLE"
    case segment = "SEGMENT"
    case select = "SELECT"
    case excludableSelect = "EXCLUDABLE_SELECT"
    case multiSelect = "MULTI_SELECT"
    case excludableMultiSelect = "EXCLUDABLE_MULTI_SELECT"
    case sort = "SORT"
    case ascendableSort = "ASCENDABLE_SORT"
    case number = "NUMBER"
}

class SourceFilterGroup: Codable {
    enum CodingKeys: String, CodingKey {
        case header
        case footer
        case filters
    }

    let header: String?
    let footer: String?
    let filters: [any SourceFilter]

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.header = try container.decodeIfPresent(String.self, forKey: .header)
        self.footer = try container.decodeIfPresent(String.self, forKey: .footer)
        var filtersContainer = try container.nestedUnkeyedContainer(forKey: .filters)
        var filters: [any SourceFilter] = []
        while !filtersContainer.isAtEnd {
            let filterContainer = try filtersContainer.nestedContainer(keyedBy: BaseFilterCodingKeys.self)
            let type = try filterContainer.decode(FilterType.self, forKey: .type)
            switch type {
            case .text: filters.append(try SourceTextFilter(from: try filterContainer.superDecoder()))
            case .toggle: filters.append(try SourceToggleFilter(from: try filterContainer.superDecoder()))
            case .segment: filters.append(try SourceSegmentFilter(from: try filterContainer.superDecoder()))
            case .select: filters.append(try SourceSelectFilter(from: try filterContainer.superDecoder()))
            case .excludableSelect: filters.append(try SourceExcludableSelectFilter(from: try filterContainer.superDecoder()))
            case .multiSelect: filters.append(try SourceMultiSelectFilter(from: try filterContainer.superDecoder()))
            case .excludableMultiSelect: filters.append(try SourceExcludableMultiSelectFilter(from: try filterContainer.superDecoder()))
            case .sort: filters.append(try SourceSortFilter(from: try filterContainer.superDecoder()))
            case .ascendableSort: filters.append(try SourceAscendableSortFilter(from: try filterContainer.superDecoder()))
            case .number: filters.append(try SourceNumberFilter(from: try filterContainer.superDecoder()))
            }
        }
        self.filters = filters
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.header, forKey: .header)
        try container.encodeIfPresent(self.footer, forKey: .footer)
        var filtersContainer = container.nestedUnkeyedContainer(forKey: .filters)
        for filter in self.filters {
            try filtersContainer.encode(filter)
        }
    }
}

protocol SourceFilter<ValueType>: Codable {
    associatedtype ValueType: Codable
    var id: String { get }
    var value: ValueType { get set }
    var name: String { get }
}

class SourceTextFilter: SourceFilter, Codable {
    let id: String
    var value: String
    let name: String
    let placeholder: String?
}

class SourceToggleFilter: SourceFilter, Codable {
    let id: String
    var value: Bool
    let name: String
}

class SourceSegmentFilterOption: Codable {
    let id: String
    let name: String
    var selected: Bool
}

class SourceSegmentFilter: SourceFilter, Codable {
    let id: String
    var value: [SourceSegmentFilterOption]
    let name: String
}

class SourceSelectFilterOption: Codable {
    let id: String
    let name: String
    var selected: Bool
    var excluded: Bool?
    var ascending: Bool?

    init(id: String, name: String, selected: Bool, excluded: Bool? = nil, ascending: Bool? = nil) {
        self.id = id
        self.name = name
        self.selected = selected
        self.excluded = excluded
        self.ascending = ascending
    }
}

class SourceSelectFilter: SourceFilter, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
    let name: String
}

class SourceExcludableSelectFilter: SourceFilter, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
    let name: String
}

class SourceMultiSelectFilter: SourceFilter, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
    let name: String
}

class SourceExcludableMultiSelectFilter: SourceFilter, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
    let name: String
}

class SourceSortFilter: SourceFilter, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
    let name: String
}

class SourceAscendableSortFilter: SourceFilter, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
    let name: String
}

class SourceNumberFilter: SourceFilter, Codable {
    let id: String
    var value: Double
    let name: String
    let lowerBound: Double
    let upperBound: Double
    let step: Double
    let allowsCustomInput: Bool
}
