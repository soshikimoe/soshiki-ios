//
//  SettingItem.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/5/23.
//

import Foundation
import UIKit

protocol SettingItem {
    associatedtype ValueType

    var id: String { get }
    var title: String { get }
    var value: ValueType { get set }
    var valueDidChange: (Self) -> Void { get }
}

class TextSettingItem: SettingItem {
    let id: String
    let title: String
    var value: String
    let placeholder: String?
    let valueDidChange: (TextSettingItem) -> Void

    init(id: String, title: String, value: String = "", placeholder: String? = nil, valueDidChange: @escaping (TextSettingItem) -> Void) {
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
    let valueDidChange: (ToggleSettingItem) -> Void

    init(id: String, title: String, value: Bool = false, valueDidChange: @escaping (ToggleSettingItem) -> Void) {
        self.id = id
        self.title = title
        self.value = value
        self.valueDidChange = valueDidChange
    }
}

class SegmentSettingItem: SettingItem {
    let id: String
    let title: String
    var value: [SourceSelectFilterOption]
    let valueDidChange: (SegmentSettingItem) -> Void

    init(id: String, title: String, value: [SourceSelectFilterOption], valueDidChange: @escaping (SegmentSettingItem) -> Void) {
        self.id = id
        self.title = title
        self.value = value
        self.valueDidChange = valueDidChange
    }
}

class SelectSettingItem: SettingItem {
    let id: String
    let title: String
    var value: [SourceSelectFilterOption]
    let valueDidChange: (SelectSettingItem) -> Void

    init(id: String, title: String, value: [SourceSelectFilterOption], valueDidChange: @escaping (SelectSettingItem) -> Void) {
        self.id = id
        self.title = title
        self.value = value
        self.valueDidChange = valueDidChange
    }
}

class ExcludableSelectSettingItem: SettingItem {
    let id: String
    let title: String
    var value: [SourceSelectFilterOption]
    let valueDidChange: (ExcludableSelectSettingItem) -> Void

    init(id: String, title: String, value: [SourceSelectFilterOption], valueDidChange: @escaping (ExcludableSelectSettingItem) -> Void) {
        self.id = id
        self.title = title
        self.value = value
        self.valueDidChange = valueDidChange
    }
}

class MultiSelectSettingItem: SettingItem {
    let id: String
    let title: String
    var value: [SourceSelectFilterOption]
    let valueDidChange: (MultiSelectSettingItem) -> Void

    init(id: String, title: String, value: [SourceSelectFilterOption], valueDidChange: @escaping (MultiSelectSettingItem) -> Void) {
        self.id = id
        self.title = title
        self.value = value
        self.valueDidChange = valueDidChange
    }
}

class ExcludableMultiSelectSettingItem: SettingItem {
    let id: String
    let title: String
    var value: [SourceSelectFilterOption]
    let valueDidChange: (ExcludableMultiSelectSettingItem) -> Void

    init(id: String, title: String, value: [SourceSelectFilterOption], valueDidChange: @escaping (ExcludableMultiSelectSettingItem) -> Void) {
        self.id = id
        self.title = title
        self.value = value
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
    let valueDidChange: (NumberSettingItem) -> Void

    init(
        id: String,
        title: String,
        value: Double,
        lowerBound: Double,
        upperBound: Double,
        step: Double,
        valueDidChange: @escaping (NumberSettingItem) -> Void
    ) {
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
    let valueDidChange: (ButtonSettingItem) -> Void

    init(id: String, title: String, presentsView: Bool = false, valueDidChange: @escaping (ButtonSettingItem) -> Void) {
        self.id = id
        self.title = title
        self.presentsView = presentsView
        self.valueDidChange = valueDidChange
    }
}

class ColorSettingItem: SettingItem {
    let id: String
    let title: String
    let supportsAlpha: Bool
    let canReset: Bool
    var value: UIColor?
    let valueDidChange: (ColorSettingItem) -> Void

    init(
        id: String,
        title: String,
        supportsAlpha: Bool = true,
        canReset: Bool = false,
        value: UIColor?,
        valueDidChange: @escaping (ColorSettingItem) -> Void
    ) {
        self.id = id
        self.title = title
        self.supportsAlpha = supportsAlpha
        self.canReset = canReset
        self.value = value
        self.valueDidChange = valueDidChange
    }
}
