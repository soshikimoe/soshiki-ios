//
//  SourceSettingsView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/1/23.
//

import SwiftUI

struct SourceSettingsView: View {
    var source: any Source
    @Binding var settings: [any SourceFilter]

    var body: some View {
        List(settings.enumerated().map({ $0 }), id: \.element.id) { offset, element in
            Section {
                switch element {
                case var textFilter as SourceTextFilter:
                    SourceTextFilterView(filter: Binding(get: {
                        if let value = UserDefaults.standard.value(forKey: "settings.source.\(source.id).\(textFilter.id)") as? String {
                            textFilter.value = value
                        }
                        return textFilter
                    }, set: {
                        UserDefaults.standard.set($0.value, forKey: "settings.source.\(source.id).\(textFilter.id)")
                        settings[offset] = $0
                    }))
                case var toggleFilter as SourceToggleFilter:
                    SourceToggleFilterView(filter: Binding(get: {
                        if let value = UserDefaults.standard.value(forKey: "settings.source.\(source.id).\(toggleFilter.id)") as? Bool {
                            toggleFilter.value = value
                        }
                        return toggleFilter
                    }, set: {
                        UserDefaults.standard.set($0.value, forKey: "settings.source.\(source.id).\(toggleFilter.id)")
                        settings[offset] = $0
                    }))
                case var segmentFilter as SourceSegmentFilter:
                    SourceSegmentFilterView(filter: Binding(get: {
                        if let value = UserDefaults.standard.value(forKey: "settings.source.\(source.id).\(segmentFilter.id)") as? String {
                            segmentFilter.value = value
                        }
                        return segmentFilter
                    }, set: {
                        UserDefaults.standard.set($0.value, forKey: "settings.source.\(source.id).\(segmentFilter.id)")
                        settings[offset] = $0
                    }))
                case var selectFilter as SourceSelectFilter:
                    SourceSelectFilterView(filter: Binding(get: {
                        if let value = UserDefaults.standard.value(forKey: "settings.source.\(source.id).\(selectFilter.id)") as? String? {
                            selectFilter.value = value
                        }
                        return selectFilter
                    }, set: {
                        UserDefaults.standard.set($0.value, forKey: "settings.source.\(source.id).\(selectFilter.id)")
                        settings[offset] = $0
                    }))
                case var excludableSelectFilter as SourceExcludableSelectFilter:
                    SourceExcludableSelectFilterView(filter: Binding(get: {
                        if let value = UserDefaults.standard.value(forKey: "settings.source.\(source.id).\(excludableSelectFilter.id)") as? (String, Bool)? {
                            excludableSelectFilter.value = value
                        }
                        return excludableSelectFilter
                    }, set: {
                        UserDefaults.standard.set($0.value, forKey: "settings.source.\(source.id).\(excludableSelectFilter.id)")
                        settings[offset] = $0
                    }))
                case var multiSelectFilter as SourceMultiSelectFilter:
                    SourceMultiSelectFilterView(filter: Binding(get: {
                        if let value = UserDefaults.standard.value(forKey: "settings.source.\(source.id).\(multiSelectFilter.id)") as? [String] {
                            multiSelectFilter.value = value
                        }
                        return multiSelectFilter
                    }, set: {
                        UserDefaults.standard.set($0.value, forKey: "settings.source.\(source.id).\(multiSelectFilter.id)")
                        settings[offset] = $0
                    }))
                case var excludableMultiSelectFilter as SourceExcludableMultiSelectFilter:
                    SourceExcludableMultiSelectFilterView(filter: Binding(get: {
                        if let value = UserDefaults.standard.value(forKey: "settings.source.\(source.id).\(excludableMultiSelectFilter.id)") as? [(String, Bool)] {
                            excludableMultiSelectFilter.value = value
                        }
                        return excludableMultiSelectFilter
                    }, set: {
                        UserDefaults.standard.set($0.value, forKey: "settings.source.\(source.id).\(excludableMultiSelectFilter.id)")
                        settings[offset] = $0
                    }))
                case var sortFilter as SourceSortFilter:
                    SourceSortFilterView(filter: Binding(get: {
                        if let value = UserDefaults.standard.value(forKey: "settings.source.\(source.id).\(sortFilter.id)") as? String? {
                            sortFilter.value = value
                        }
                        return sortFilter
                    }, set: {
                        UserDefaults.standard.set($0.value, forKey: "settings.source.\(source.id).\(sortFilter.id)")
                        settings[offset] = $0
                    }))
                case var ascendableSortFilter as SourceAscendableSortFilter:
                    SourceAscendableSortFilterView(filter: Binding(get: {
                        if let value = UserDefaults.standard.value(forKey: "settings.source.\(source.id).\(ascendableSortFilter.id)") as? (String, Bool)? {
                            ascendableSortFilter.value = value
                        }
                        return ascendableSortFilter
                    }, set: {
                        UserDefaults.standard.set($0.value, forKey: "settings.source.\(source.id).\(ascendableSortFilter.id)")
                        settings[offset] = $0
                    }))
                case var numberFilter as SourceNumberFilter:
                    SourceNumberFilterView(filter: Binding(get: {
                        if let value = UserDefaults.standard.value(forKey: "settings.source.\(source.id).\(numberFilter.id)") as? Double {
                            numberFilter.value = value
                        }
                        return numberFilter
                    }, set: {
                        UserDefaults.standard.set($0.value, forKey: "settings.source.\(source.id).\(numberFilter.id)")
                        settings[offset] = $0
                    }))
                case var rangeFilter as SourceRangeFilter:
                    SourceRangeFilterView(filter: Binding(get: {
                        if let value = UserDefaults.standard.value(forKey: "settings.source.\(source.id).\(rangeFilter.id)") as? (Double, Double) {
                            rangeFilter.value = value
                        }
                        return rangeFilter
                    }, set: {
                        UserDefaults.standard.set($0.value, forKey: "settings.source.\(source.id).\(rangeFilter.id)")
                        settings[offset] = $0
                    }))
                default:
                    EmptyView()
                }
            }
        }
    }
}
