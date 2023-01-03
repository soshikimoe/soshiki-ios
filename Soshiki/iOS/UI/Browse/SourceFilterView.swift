//
//  SearchFilterView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/28/22.
//

import SwiftUI
import Sliders

struct SourceFilterView: View {
    @Binding var filters: [any SourceFilter]

    var body: some View {
        List(filters.enumerated().map({ $0 }), id: \.element.id) { offset, element in
            Section {
                switch element {
                case let textFilter as SourceTextFilter:
                    SourceTextFilterView(filter: Binding(get: { textFilter }, set: { filters[offset] = $0 }))
                case let toggleFilter as SourceToggleFilter:
                    SourceToggleFilterView(filter: Binding(get: { toggleFilter }, set: { filters[offset] = $0 }))
                case let segmentFilter as SourceSegmentFilter:
                    SourceSegmentFilterView(filter: Binding(get: { segmentFilter }, set: { filters[offset] = $0 }))
                case let selectFilter as SourceSelectFilter:
                    SourceSelectFilterView(filter: Binding(get: { selectFilter }, set: { filters[offset] = $0 }))
                case let excludableSelectFilter as SourceExcludableSelectFilter:
                    SourceExcludableSelectFilterView(filter: Binding(get: { excludableSelectFilter }, set: { filters[offset] = $0 }))
                case let multiSelectFilter as SourceMultiSelectFilter:
                    SourceMultiSelectFilterView(filter: Binding(get: { multiSelectFilter }, set: { filters[offset] = $0 }))
                case let excludableMultiSelectFilter as SourceExcludableMultiSelectFilter:
                    SourceExcludableMultiSelectFilterView(filter: Binding(get: { excludableMultiSelectFilter }, set: { filters[offset] = $0 }))
                case let sortFilter as SourceSortFilter:
                    SourceSortFilterView(filter: Binding(get: { sortFilter }, set: { filters[offset] = $0 }))
                case let ascendableSortFilter as SourceAscendableSortFilter:
                    SourceAscendableSortFilterView(filter: Binding(get: { ascendableSortFilter }, set: { filters[offset] = $0 }))
                case let numberFilter as SourceNumberFilter:
                    SourceNumberFilterView(filter: Binding(get: { numberFilter }, set: { filters[offset] = $0 }))
                case let rangeFilter as SourceRangeFilter:
                    SourceRangeFilterView(filter: Binding(get: { rangeFilter }, set: { filters[offset] = $0 }))
                default:
                    EmptyView()
                }
            }
        }
    }
}

struct SourceTextFilterView: View {
    @Binding var filter: SourceTextFilter

    var body: some View {
        VStack(alignment: .leading) {
            Text(filter.name)
            TextField(filter.placeholder, text: $filter.value)
        }
    }
}

struct SourceToggleFilterView: View {
    @Binding var filter: SourceToggleFilter

    var body: some View {
        Toggle(filter.name, isOn: $filter.value)
    }
}

struct SourceSegmentFilterView: View {
    @Binding var filter: SourceSegmentFilter

    var body: some View {
        VStack(alignment: .leading) {
            Text(filter.name)
            Picker(filter.name, selection: $filter.value) {
                ForEach(filter.selections, id: \.self) { selection in
                    Text(selection).tag(selection)
                }
            }.pickerStyle(.segmented)
        }
    }
}

struct SourceSelectFilterView: View {
    @Binding var filter: SourceSelectFilter

    @State var expanded = false

    var body: some View {
        HStack {
            Text(filter.name)
            Spacer()
            Button {
                withAnimation {
                    expanded.toggle()
                }
            } label: {
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
            }
        }
        if expanded {
            ForEach(filter.selections, id: \.self) { selection in
                Button {
                    filter.value = filter.value == selection ? nil : selection
                } label: {
                    HStack {
                        Text(selection).foregroundColor(.white)
                        Spacer()
                        if filter.value == selection {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
}

struct SourceExcludableSelectFilterView: View {
    @Binding var filter: SourceExcludableSelectFilter

    @State var expanded = false

    var body: some View {
        HStack {
            Text(filter.name)
            Spacer()
            Button {
                withAnimation {
                    expanded.toggle()
                }
            } label: {
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
            }
        }
        if expanded {
            ForEach(filter.selections, id: \.self) { selection in
                Button {
                    filter.value = (filter.value?.0 == selection ? (filter.value?.1 == true ? nil : ((selection, true))) : (selection, false))
                } label: {
                    HStack {
                        Text(selection).foregroundColor(.white)
                        Spacer()
                        if filter.value?.0 == selection {
                            Image(systemName: filter.value?.1 == true ? "xmark" : "checkmark")
                        }
                    }
                }
            }
        }
    }
}

struct SourceMultiSelectFilterView: View {
    @Binding var filter: SourceMultiSelectFilter

    @State var expanded = false

    var body: some View {
        HStack {
            Text(filter.name)
            Spacer()
            Button {
                withAnimation {
                    expanded.toggle()
                }
            } label: {
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
            }
        }
        if expanded {
            ForEach(filter.selections, id: \.self) { selection in
                Button {
                    if let index = filter.value.firstIndex(of: selection) {
                        filter.value.remove(at: index)
                    } else {
                        filter.value.append(selection)
                    }
                } label: {
                    HStack {
                        Text(selection).foregroundColor(.white)
                        Spacer()
                        if filter.value.contains(selection) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
}

struct SourceExcludableMultiSelectFilterView: View {
    @Binding var filter: SourceExcludableMultiSelectFilter

    @State var expanded = false

    var body: some View {
        HStack {
            Text(filter.name)
            Spacer()
            Button {
                withAnimation {
                    expanded.toggle()
                }
            } label: {
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
            }
        }
        if expanded {
            ForEach(filter.selections, id: \.self) { selection in
                Button {
                    if let index = filter.value.firstIndex(where: { $0.0 == selection }) {
                        if filter.value[index].1 {
                            filter.value.remove(at: index)
                        } else {
                            filter.value[index] = (selection, true)
                        }
                    } else {
                        filter.value.append((selection, false))
                    }
                } label: {
                    HStack {
                        Text(selection).foregroundColor(.white)
                        Spacer()
                        if let item = filter.value.first(where: { $0.0 == selection }) {
                            Image(systemName: item.1 ? "xmark" : "checkmark")
                        }
                    }
                }
            }
        }
    }
}

struct SourceSortFilterView: View {
    @Binding var filter: SourceSortFilter

    @State var expanded = false

    var body: some View {
        HStack {
            Text(filter.name)
            Spacer()
            Button {
                withAnimation {
                    expanded.toggle()
                }
            } label: {
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
            }
        }
        if expanded {
            ForEach(filter.selections, id: \.self) { selection in
                Button {
                    filter.value = filter.value == selection ? nil : selection
                } label: {
                    HStack {
                        Text(selection).foregroundColor(.white)
                        Spacer()
                        if filter.value == selection {
                            Image(systemName: "chevron.down")
                        }
                    }
                }
            }
        }
    }
}

struct SourceAscendableSortFilterView: View {
    @Binding var filter: SourceAscendableSortFilter

    @State var expanded = false

    var body: some View {
        HStack {
            Text(filter.name)
            Spacer()
            Button {
                withAnimation {
                    expanded.toggle()
                }
            } label: {
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
            }
        }
        if expanded {
            ForEach(filter.selections, id: \.self) { selection in
                Button {
                    filter.value = (filter.value?.0 == selection ? (filter.value?.1 == true ? nil : ((selection, true))) : (selection, false))
                } label: {
                    HStack {
                        Text(selection).foregroundColor(.white)
                        Spacer()
                        if filter.value?.0 == selection {
                            Image(systemName: filter.value?.1 == true ? "chevron.up" : "chevron.down")
                        }
                    }
                }
            }
        }
    }
}

struct SourceNumberFilterView: View {
    @Binding var filter: SourceNumberFilter

    var body: some View {
        HStack {
            Text(filter.name)
            Spacer()
            InlineStepper(
                value: $filter.value,
                lowerBound: filter.lowerBound,
                upperBound: filter.upperBound,
                step: filter.step,
                allowsCustomInput: filter.allowsCustomInput
            )
        }
    }
}

struct SourceRangeFilterView: View {
    @Binding var filter: SourceRangeFilter

    var body: some View {
        VStack {
            HStack {
                Text(filter.name)
                Spacer()
                Text("\(filter.value.0.toTruncatedString()) to \(filter.value.1.toTruncatedString())")
            }.padding(.top, 8)
            RangeSlider(range: Binding(get: {
                filter.value.0...filter.value.1
            }, set: {
                filter.value = ($0.lowerBound, $0.upperBound)
            }), in: filter.lowerBound...filter.upperBound, step: filter.step).rangeSliderStyle(HorizontalRangeSliderStyle(
                lowerThumbSize: CGSize(width: 16, height: 16), upperThumbSize: CGSize(width: 16, height: 16)
            )).padding(.vertical, -8)
        }
    }
}
