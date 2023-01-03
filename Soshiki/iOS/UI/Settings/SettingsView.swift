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
                    if SoshikiAPI.shared.token.isEmpty {
                        Button {
                            loginViewPresented.toggle()
                        } label: {
                            Text("Login")
                        }.sheet(isPresented: $loginViewPresented) {
                            LoginView()
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button {
                                            loginViewPresented.toggle()
                                        } label: {
                                            Text("Done").bold()
                                        }
                                    }
                                }.toolbar(.hidden, for: .bottomBar)
                        }
                    } else {
                        Button {
                            SoshikiAPI.shared.token = ""
                        } label: {
                            Text("Logout")
                        }
                    }
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
            }
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
