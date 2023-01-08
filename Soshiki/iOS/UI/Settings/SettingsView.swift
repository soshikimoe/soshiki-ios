//
//  SettingsView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/23/22.
//

import SwiftUI

struct SettingsView: View {
    @State var loginViewPresented = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: "Account") {
                    Link("Login", destination: SoshikiAPI.shared.loginUrl)
                }
                Section(header: "Sources") {
                    NavigationLink {
                        List {
                            ForEach(SourceManager.shared.sources, id: \.id) { source in
                                SourceCardView(source: source)
                            }.onDelete(perform: deleteSource)
                        }
                    } label: {
                        Text("Sources")
                    }
                }
            }.navigationTitle("Settings")
        }
    }

    func deleteSource(at offsets: IndexSet) {
        for offset in offsets {
            SourceManager.shared.removeSource(id: SourceManager.shared.sources[offset].id)
        }
    }
}

enum SettingsViewType: String {
    case text
    case button
    case select
    case multiSelect
    case number
    case segment
}
