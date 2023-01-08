//
//  SettingsView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/23/22.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var sourceManager: SourceManager

    @State var loginViewPresented = false

    @State var loggedIn = SoshikiAPI.shared.token != nil

    @State var addSourceAlertPresented = false
    @State var addSourceAlertTextContent = ""

    var body: some View {
        NavigationStack {
            List {
                Section(header: "Account") {
                    if loggedIn {
                        Button {
                            SoshikiAPI.shared.logout()
                            loggedIn = false
                        } label: {
                            Text("Logout")
                        }
                    } else {
                        Button {
                            loginViewPresented.toggle()
                        } label: {
                            Text("Login")
                        }.sheet(isPresented: $loginViewPresented) {
                            WebView(url: SoshikiAPI.shared.loginUrl, safariViewController: SoshikiAPI.shared.loginViewController)
                        }
                    }
                }.onChange(of: loginViewPresented) { _ in
                    loggedIn = SoshikiAPI.shared.token != nil
                }
                Section(header: "Sources") {
                    NavigationLink {
                        List {
                            ForEach(sourceManager.sources, id: \.id) { source in
                                SourceCardView(source: source)
                            }.onDelete(perform: deleteSource)
                        }.toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    addSourceAlertPresented.toggle()
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }.alert("Install a Source", isPresented: $addSourceAlertPresented) {
                            TextField("Source URL", text: $addSourceAlertTextContent)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                            Button("Install", role: .cancel) {
                                if let url = URL(string: addSourceAlertTextContent), url.pathExtension == "soshikisource" {
                                    Task {
                                        await sourceManager.installSource(url)
                                    }
                                }
                                addSourceAlertTextContent = ""
                            }
                        } message: {
                            Text("Enter a source URL below to install it.")
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
            sourceManager.removeSource(id: sourceManager.sources[offset].id)
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
