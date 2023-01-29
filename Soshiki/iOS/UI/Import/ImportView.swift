//
//  ImportView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/16/23.
//

import SwiftUI

/*
struct ImportView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject var importViewModel: ImportViewModel

    init(mediaType: MediaType, url: Binding<URL?>) {
        self._importViewModel = StateObject(wrappedValue: ImportViewModel(mediaType: mediaType, url: url))
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Type")
                    Spacer()
                    Menu {
                        ForEach(ImportViewModel.ImportType.allCases, id: \.rawValue) { type in
                            Button {
                                importViewModel.importType = type
                            } label: {
                                if importViewModel.importType == type {
                                    Label(type.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(type.rawValue)
                                }
                            }
                        }
                    } label: {
                        Text(importViewModel.importType.rawValue).padding(.trailing, -3)
                        Image(systemName: "chevron.down")
                    }
                }
                if importViewModel.importType == .volume {
                    Toggle("Add to Existing Entry", isOn: $importViewModel.addToExisting)
                }
                Divider()
            }.padding([.horizontal, .top])
                .navigationTitle("Import File")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) {
                            dismiss.callAsFunction()
                        } label: {
                            Text("Cancel")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            if importViewModel.importFile() {
                                dismiss.callAsFunction()
                            }
                        } label: {
                            Text("Confirm")
                        }
                    }
                }.onAppear {
                    importViewModel.refreshSearch()
                }
            if importViewModel.importType == .volume {
                HStack {
                    Text("Volume")
                    Spacer()
                    InlineStepper(value: $importViewModel.partNumber, lowerBound: -1, upperBound: .infinity, step: 1, allowsCustomInput: true)
                }.padding(.horizontal)
                if importViewModel.addToExisting {
                    SearchBar(text: $importViewModel.searchText, onCommit: {
                        importViewModel.refreshSearch()
                    })
                    if let entries = importViewModel.searchResults?.entries {
                        List(entries, id: \.id) { entry in
                            Button {
                                importViewModel.selectedId = entry.id
                            } label: {
                                HStack {
                                    EntryRowView(entry: entry.toLocalEntry())
                                    Spacer(minLength: 0)
                                    if importViewModel.selectedId == entry.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } else {
                    TextField("Insert Title Here", text: $importViewModel.newEntryTitle)
                        .padding(.horizontal)
                }
            }
            Spacer()
        }
    }
}

class ImportViewModel: ObservableObject {
    let mediaType: MediaType
    @Binding var url: URL?

    @Published var importType: ImportType = .full

    @Published var addToExisting = false

    var loadingTask: Task<Void, Never>?

    @Published var searchText = ""
    @Published var searchResults: SourceEntryResults?

    @Published var selectedId: String?

    var source: any LocalSource

    @Published var newEntryTitle = ""
    @Published var partNumber: Double = 1

    init(mediaType: MediaType, url: Binding<URL?>) {
        self.mediaType = mediaType
        self._url = url
        self.source = LocalTextSource.shared
    }

    func refreshSearch() {
        loadingTask = Task {
            if let searchResults = await source.getSearchResults(query: self.searchText, filters: [], previousResultsInfo: nil) {
                Task { @MainActor in
                    self.searchResults = searchResults
                    loadingTask = nil
                }
            } else {
                loadingTask = nil
            }
        }
    }

    func importFile() -> Bool {
        guard let url else { return false }
        if importType == .full {
            source.importFull(url)
            return true
        } else if addToExisting, let selectedId {
            source.importPart(url, number: partNumber, addingTo: selectedId)
            return true
        } else if !addToExisting, !newEntryTitle.isEmpty {
            source.importPart(url, number: partNumber, withTitle: newEntryTitle)
            return true
        }
        return false
    }

    enum ImportType: String, CaseIterable, CustomStringConvertible {
        var description: String { self.rawValue }

        case full = "Full"
        case volume = "Volume"
    }
}
*/
