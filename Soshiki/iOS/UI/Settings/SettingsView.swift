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
                        SourcesView()
                    } label: {
                        Text("Sources")
                    }
                }
                Section(header: "Trackers") {
                    NavigationLink {
                        TrackersView()
                    } label: {
                        Text("Trackers")
                    }
                }
            }.navigationTitle("Settings")
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
