//
//  ContentView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/14/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject var contentViewModel = ContentViewModel()

    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "folder.fill")
                }
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "globe")
                }
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }.environmentObject(contentViewModel)
            .environmentObject(SourceManager.shared)
    }
}

@MainActor class ContentViewModel: ObservableObject {
    @Published var libraries: Libraries?
    @AppStorage("app.session.mediaType") var mediaType: MediaType = .image

    func refreshLibraries() async {
        if let libraries = try? await SoshikiAPI.shared.getLibraries().get() {
            self.libraries = libraries
        }
    }

    func library(forMediaType mediaType: MediaType) -> FullLibrary? {
        mediaType == .text ? libraries?.text : mediaType == .image ? libraries?.image : libraries?.video
    }
}
