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

enum SourceFilter: Codable {
    case text(SourceTextFilter)
    case toggle(SourceToggleFilter)
    case segment(SourceSegmentFilter)
    case select(SourceSelectFilter)
    case excludableSelect(SourceExcludableSelectFilter)
    case multiSelect(SourceMultiSelectFilter)
    case excludableMultiSelect(SourceExcludableMultiSelectFilter)
    case sort(SourceSortFilter)
    case ascendableSort(SourceAscendableSortFilter)
    case number(SourceNumberFilter)

    var anyFilter: any SourceFilterBase {
        switch self {
        case .text(let filter): return filter
        case .toggle(let filter): return filter
        case .segment(let filter): return filter
        case .select(let filter): return filter
        case .excludableSelect(let filter): return filter
        case .multiSelect(let filter): return filter
        case .excludableMultiSelect(let filter): return filter
        case .sort(let filter): return filter
        case .ascendableSort(let filter): return filter
        case .number(let filter): return filter
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleContainer = try decoder.singleValueContainer()

        let type = try container.decode(FilterType.self, forKey: .type)
        switch type {
        case .text: self = .text(try singleContainer.decode(SourceTextFilter.self))
        case .toggle: self = .toggle(try singleContainer.decode(SourceToggleFilter.self))
        case .segment: self = .segment(try singleContainer.decode(SourceSegmentFilter.self))
        case .select: self = .select(try singleContainer.decode(SourceSelectFilter.self))
        case .excludableSelect: self = .excludableSelect(try singleContainer.decode(SourceExcludableSelectFilter.self))
        case .multiSelect: self = .multiSelect(try singleContainer.decode(SourceMultiSelectFilter.self))
        case .excludableMultiSelect: self = .excludableMultiSelect(try singleContainer.decode(SourceExcludableMultiSelectFilter.self))
        case .sort: self = .sort(try singleContainer.decode(SourceSortFilter.self))
        case .ascendableSort: self = .ascendableSort(try singleContainer.decode(SourceAscendableSortFilter.self))
        case .number: self = .number(try singleContainer.decode(SourceNumberFilter.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var singleContainer = encoder.singleValueContainer()

        switch self {
        case .text(let filter): try singleContainer.encode(filter)
        case .toggle(let filter): try singleContainer.encode(filter)
        case .segment(let filter): try singleContainer.encode(filter)
        case .select(let filter): try singleContainer.encode(filter)
        case .excludableSelect(let filter): try singleContainer.encode(filter)
        case .multiSelect(let filter): try singleContainer.encode(filter)
        case .excludableMultiSelect(let filter): try singleContainer.encode(filter)
        case .sort(let filter): try singleContainer.encode(filter)
        case .ascendableSort(let filter): try singleContainer.encode(filter)
        case .number(let filter): try singleContainer.encode(filter)
        }
    }
}

class SourceFilterGroup: Codable {
    enum CodingKeys: String, CodingKey {
        case header
        case footer
        case filters
    }

    let header: String?
    let footer: String?
    let filters: [SourceFilter]
}

protocol SourceFilterBase<ValueType>: Codable {
    associatedtype ValueType: Codable
    var id: String { get }
    var value: ValueType { get set }
    var name: String { get }
}

class SourceTextFilter: SourceFilterBase, Codable {
    let id: String
    var value: String
    let name: String
    let placeholder: String?
}

class SourceToggleFilter: SourceFilterBase, Codable {
    let id: String
    var value: Bool
    let name: String
}

class SourceSegmentFilter: SourceFilterBase, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
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

class SourceSelectFilter: SourceFilterBase, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
    let name: String
}

class SourceExcludableSelectFilter: SourceFilterBase, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
    let name: String
}

class SourceMultiSelectFilter: SourceFilterBase, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
    let name: String
}

class SourceExcludableMultiSelectFilter: SourceFilterBase, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
    let name: String
}

class SourceSortFilter: SourceFilterBase, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
    let name: String
}

class SourceAscendableSortFilter: SourceFilterBase, Codable {
    let id: String
    var value: [SourceSelectFilterOption]
    let name: String
}

class SourceNumberFilter: SourceFilterBase, Codable {
    let id: String
    var value: Double
    let name: String
    let lowerBound: Double
    let upperBound: Double
    let step: Double
    let allowsCustomInput: Bool
}
