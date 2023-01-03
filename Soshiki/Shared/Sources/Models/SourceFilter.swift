//
//  SourceFilter.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/28/22.
//

import Foundation
import JavaScriptCore

enum SourceFilterType {
    init?(_ filter: any SourceFilter) {
        if let filter = filter as? SourceTextFilter {
            self = .textFilter(filter)
        } else if let filter = filter as? SourceToggleFilter {
            self = .toggleFilter(filter)
        } else if let filter = filter as? SourceSegmentFilter {
            self = .segmentFilter(filter)
        } else if let filter = filter as? SourceSelectFilter {
            self = .selectFilter(filter)
        } else if let filter = filter as? SourceExcludableSelectFilter {
            self = .excludableSelectFilter(filter)
        } else if let filter = filter as? SourceMultiSelectFilter {
            self = .multiSelectFilter(filter)
        } else if let filter = filter as? SourceExcludableMultiSelectFilter {
            self = .excludableMultiSelectFilter(filter)
        } else if let filter = filter as? SourceSortFilter {
            self = .sortFilter(filter)
        } else if let filter = filter as? SourceAscendableSortFilter {
            self = .ascendableSortFilter(filter)
        } else if let filter = filter as? SourceNumberFilter {
            self = .numberFilter(filter)
        } else if let filter = filter as? SourceRangeFilter {
            self = .rangeFilter(filter)
        } else {
            return nil
        }
    }

    case textFilter(SourceTextFilter)
    case toggleFilter(SourceToggleFilter)
    case segmentFilter(SourceSegmentFilter)
    case selectFilter(SourceSelectFilter)
    case excludableSelectFilter(SourceExcludableSelectFilter)
    case multiSelectFilter(SourceMultiSelectFilter)
    case excludableMultiSelectFilter(SourceExcludableMultiSelectFilter)
    case sortFilter(SourceSortFilter)
    case ascendableSortFilter(SourceAscendableSortFilter)
    case numberFilter(SourceNumberFilter)
    case rangeFilter(SourceRangeFilter)
}

protocol JSObjectEncodable {
    var object: [String: Any] { get }
}

protocol JSObjectDecodable {
    init?(from object: [String: Any])
}

protocol JSObjectCodable: JSObjectDecodable, JSObjectEncodable {}

protocol SourceFilter<ValueType>: JSObjectCodable {
    associatedtype ValueType
    var id: String { get }
    var value: ValueType { get set }
    var name: String { get }
}

protocol SourceMultiRowFilter {
    var selections: [String] { get }
}

struct SourceTextFilter: SourceFilter {
    init?(from object: [String: Any]) {
        guard let id = object["id"] as? String,
              let value = object["value"] as? String,
              let name = object["name"] as? String else { return nil }
        self.id = id
        self.value = value
        self.name = name
        self.placeholder = object["placeholder"] as? String ?? ""
    }

    let id: String
    var value: String
    let name: String
    let placeholder: String

    var object: [String: Any] {
        [
            "id": id,
            "value": value,
            "name": name,
            "placeholder": placeholder
        ]
    }
}

struct SourceToggleFilter: SourceFilter {
    init?(from object: [String: Any]) {
        guard let id = object["id"] as? String,
              let value = object["value"] as? Bool,
              let name = object["name"] as? String else { return nil }
        self.id = id
        self.value = value
        self.name = name
    }

    let id: String
    var value: Bool
    let name: String

    var object: [String: Any] {
        [
            "id": id,
            "value": value,
            "name": name
        ]
    }
}

struct SourceSegmentFilter: SourceFilter {
    init?(from object: [String: Any]) {
        guard let id = object["id"] as? String,
              let value = object["value"] as? String,
              let name = object["name"] as? String,
              let selections = object["selections"] as? [String] else { return nil }
        self.id = id
        self.value = value
        self.name = name
        self.selections = selections
    }

    let id: String
    var value: String
    let name: String
    let selections: [String]

    var object: [String: Any] {
        [
            "id": id,
            "value": value,
            "name": name,
            "selections": selections
        ]
    }
}

struct SourceSelectFilter: SourceFilter, SourceMultiRowFilter {
    init?(from object: [String: Any]) {
        guard let id = object["id"] as? String,
              let value = object["value"] as? String?,
              let name = object["name"] as? String,
              let selections = object["selections"] as? [String] else { return nil }
        self.id = id
        self.value = value
        self.name = name
        self.selections = selections
    }

    let id: String
    var value: String?
    let name: String
    let selections: [String]

    var object: [String: Any] {
        [
            "id": id,
            "value": value as Any,
            "name": name,
            "selections": selections
        ]
    }
}

struct SourceExcludableSelectFilter: SourceFilter, SourceMultiRowFilter {
    init?(from object: [String: Any]) {
        guard let id = object["id"] as? String,
              let value = object["value"] as? [Any]?, value.flatMap({ $0.count == 2 && $0[0] is String && $0[1] is Bool }) ?? true,
              let name = object["name"] as? String,
              let selections = object["selections"] as? [String] else { return nil }
        self.id = id
        self.value = value.flatMap({
            if $0.count == 2, let string = $0[0] as? String, let bool = $0[1] as? Bool {
                return (string, bool)
            } else {
                return nil
            }
        })
        self.name = name
        self.selections = selections
    }

    let id: String
    var value: (String, Bool)?
    let name: String
    let selections: [String]

    var object: [String: Any] {
        [
            "id": id,
            "value": value.flatMap({ [$0.0, $0.1] }) as Any,
            "name": name,
            "selections": selections
        ]
    }
}

struct SourceMultiSelectFilter: SourceFilter, SourceMultiRowFilter {
    init?(from object: [String: Any]) {
        guard let id = object["id"] as? String,
              let value = object["value"] as? [String],
              let name = object["name"] as? String,
              let selections = object["selections"] as? [String] else { return nil }
        self.id = id
        self.value = value
        self.name = name
        self.selections = selections
    }

    let id: String
    var value: [String]
    let name: String
    let selections: [String]

    var object: [String: Any] {
        [
            "id": id,
            "value": value as Any,
            "name": name,
            "selections": selections
        ]
    }
}

struct SourceExcludableMultiSelectFilter: SourceFilter, SourceMultiRowFilter {
    init?(from object: [String: Any]) {
        guard let id = object["id"] as? String,
              let value = object["value"] as? [[Any]], value.allSatisfy({ $0.count == 2 && $0[0] is String && $0[1] is Bool }),
              let name = object["name"] as? String,
              let selections = object["selections"] as? [String] else { return nil }
        self.id = id
        self.value = value.compactMap({
            if $0.count == 2, let string = $0[0] as? String, let bool = $0[1] as? Bool {
                return (string, bool)
            } else {
                return nil
            }
        })
        self.name = name
        self.selections = selections
    }

    let id: String
    var value: [(String, Bool)]
    let name: String
    let selections: [String]

    var object: [String: Any] {
        [
            "id": id,
            "value": value.map({ [$0.0, $0.1] }) as Any,
            "name": name,
            "selections": selections
        ]
    }
}

struct SourceSortFilter: SourceFilter, SourceMultiRowFilter {
    init?(from object: [String: Any]) {
        guard let id = object["id"] as? String,
              let value = object["value"] as? String?,
              let name = object["name"] as? String,
              let selections = object["selections"] as? [String] else { return nil }
        self.id = id
        self.value = value
        self.name = name
        self.selections = selections
    }

    let id: String
    var value: String?
    let name: String
    let selections: [String]

    var object: [String: Any] {
        [
            "id": id,
            "value": value as Any,
            "name": name,
            "selections": selections
        ]
    }
}

struct SourceAscendableSortFilter: SourceFilter, SourceMultiRowFilter {
    init?(from object: [String: Any]) {
        guard let id = object["id"] as? String,
              let value = object["value"] as? [Any]?, value.flatMap({ $0.count == 2 && $0[0] is String && $0[1] is Bool }) ?? true,
              let name = object["name"] as? String,
              let selections = object["selections"] as? [String] else { return nil }
        self.id = id
        self.value = value.flatMap({
            if $0.count == 2, let string = $0[0] as? String, let bool = $0[1] as? Bool {
                return (string, bool)
            } else {
                return nil
            }
        })
        self.name = name
        self.selections = selections
    }

    let id: String
    var value: (String, Bool)?
    let name: String
    let selections: [String]

    var object: [String: Any] {
        [
            "id": id,
            "value": value.flatMap({ [$0.0, $0.1] }) as Any,
            "name": name,
            "selections": selections
        ]
    }
}

struct SourceNumberFilter: SourceFilter {
    init?(from object: [String: Any]) {
        guard let id = object["id"] as? String,
              let value = object["value"] as? Float,
              let name = object["name"] as? String,
              let lowerBound = object["lowerBound"] as? Float,
              let upperBound = object["upperBound"] as? Float else { return nil }
        self.id = id
        self.value = value
        self.name = name
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.step = object["step"] as? Float ?? 1
        self.allowsCustomInput = object["allowsCustomInput"] as? Bool ?? false
    }

    let id: String
    var value: Float
    let name: String
    let lowerBound: Float
    let upperBound: Float
    let step: Float
    let allowsCustomInput: Bool

    var object: [String: Any] {
        [
            "id": id,
            "value": value,
            "name": name,
            "lowerBound": lowerBound,
            "upperBound": upperBound,
            "step": step,
            "allowsCustomInput": allowsCustomInput
        ]
    }
}

struct SourceRangeFilter: SourceFilter {
    init?(from object: [String: Any]) {
        guard let id = object["id"] as? String,
              let value = object["value"] as? [Float], value.count == 2,
              let name = object["name"] as? String,
              let lowerBound = object["lowerBound"] as? Float,
              let upperBound = object["upperBound"] as? Float else { return nil }
        self.id = id
        self.value = (value[0], value[1])
        self.name = name
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.step = object["step"] as? Float ?? 1
    }

    let id: String
    var value: (Float, Float)
    let name: String
    let lowerBound: Float
    let upperBound: Float
    let step: Float

    var object: [String: Any] {
        [
            "id": id,
            "value": [value.0, value.1],
            "name": name,
            "lowerBound": lowerBound,
            "upperBound": upperBound,
            "step": step
        ]
    }
}
