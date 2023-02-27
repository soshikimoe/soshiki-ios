//
//  SettingItem.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/5/23.
//

import Foundation

protocol SettingItem {
    associatedtype ValueType

    var id: String { get }
    var title: String { get }
    var value: ValueType { get set }
    var valueDidChange: (ValueType) -> Void { get }
}

class TextSettingItem: SettingItem {
    let id: String
    let title: String
    var value: String
    let placeholder: String?
    let valueDidChange: (String) -> Void

    init(id: String, title: String, value: String = "", placeholder: String? = nil, valueDidChange: @escaping (String) -> Void) {
        self.id = id
        self.title = title
        self.value = value
        self.placeholder = placeholder
        self.valueDidChange = valueDidChange
    }
}

class ToggleSettingItem: SettingItem {
    let id: String
    let title: String
    var value: Bool
    let valueDidChange: (Bool) -> Void

    init(id: String, title: String, value: Bool = false, valueDidChange: @escaping (Bool) -> Void) {
        self.id = id
        self.title = title
        self.value = value
        self.valueDidChange = valueDidChange
    }
}

class SegmentSettingItem: SettingItem {
    let id: String
    let title: String
    var value: String
    let options: [String]
    let valueDidChange: (String) -> Void

    init(id: String, title: String, value: String? = nil, options: [String], valueDidChange: @escaping (String) -> Void) {
        self.id = id
        self.title = title
        self.value = value ?? options[0]
        self.options = options
        self.valueDidChange = valueDidChange
    }
}

class SelectSettingItem: SettingItem {
    let id: String
    let title: String
    var value: String?
    let options: [String]
    let valueDidChange: (String?) -> Void

    init(id: String, title: String, value: String? = nil, options: [String], valueDidChange: @escaping (String?) -> Void) {
        self.id = id
        self.title = title
        self.value = value
        self.options = options
        self.valueDidChange = valueDidChange
    }
}

class ExcludableSelectSettingItem: SettingItem {
    let id: String
    let title: String
    var value: (String, Bool)?
    let options: [String]
    let valueDidChange: ((String, Bool)?) -> Void

    init(id: String, title: String, value: (String, Bool)? = nil, options: [String], valueDidChange: @escaping ((String, Bool)?) -> Void) {
        self.id = id
        self.title = title
        self.value = value
        self.options = options
        self.valueDidChange = valueDidChange
    }
}

class MultiSelectSettingItem: SettingItem {
    let id: String
    let title: String
    var value: [String]
    let options: [String]
    let valueDidChange: ([String]) -> Void

    init(id: String, title: String, value: [String] = [], options: [String], valueDidChange: @escaping ([String]) -> Void) {
        self.id = id
        self.title = title
        self.value = value
        self.options = options
        self.valueDidChange = valueDidChange
    }
}

class ExcludableMultiSelectSettingItem: SettingItem {
    let id: String
    let title: String
    var value: [(String, Bool)]
    let options: [String]
    let valueDidChange: ([(String, Bool)]) -> Void

    init(id: String, title: String, value: [(String, Bool)] = [], options: [String], valueDidChange: @escaping ([(String, Bool)]) -> Void) {
        self.id = id
        self.title = title
        self.value = value
        self.options = options
        self.valueDidChange = valueDidChange
    }
}

class NumberSettingItem: SettingItem {
    let id: String
    let title: String
    var value: Double
    let lowerBound: Double
    let upperBound: Double
    let step: Double
    let valueDidChange: (Double) -> Void

    init(id: String, title: String, value: Double, lowerBound: Double, upperBound: Double, step: Double, valueDidChange: @escaping (Double) -> Void) {
        self.id = id
        self.title = title
        self.value = value
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.step = step
        self.valueDidChange = valueDidChange
    }
}

class ButtonSettingItem: SettingItem {
    let id: String
    let title: String
    var value: Void
    let presentsView: Bool
    let valueDidChange: (()) -> Void

    init(id: String, title: String, presentsView: Bool = false, valueDidChange: @escaping (()) -> Void) {
        self.id = id
        self.title = title
        self.presentsView = presentsView
        self.valueDidChange = valueDidChange
    }
}
