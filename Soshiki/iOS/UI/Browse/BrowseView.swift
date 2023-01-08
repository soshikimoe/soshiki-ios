//
//  BrowseView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/30/22.
//

import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var sourceManager: SourceManager

    var body: some View {
        NavigationStack {
            List {
                Section("Text") {
                    ForEach(sourceManager.sources.filter({ $0 is TextSource }), id: \.id) { source in
                        NavigationLink {
                            SourceView(source: source)
                        } label: {
                            SourceCardView(source: source)
                        }
                    }
                    if !sourceManager.sources.contains(where: { $0 is TextSource }) {
                        Text("No Sources Found.")
                    }
                }
                Section("Image") {
                    ForEach(sourceManager.sources.filter({ $0 is ImageSource }), id: \.id) { source in
                        NavigationLink {
                            SourceView(source: source)
                        } label: {
                            SourceCardView(source: source)
                        }
                    }
                    if !sourceManager.sources.contains(where: { $0 is ImageSource }) {
                        Text("No Sources Found.")
                    }
                }
                Section("Video") {
                    ForEach(sourceManager.sources.filter({ $0 is VideoSource }), id: \.id) { source in
                        NavigationLink {
                            SourceView(source: source)
                        } label: {
                            SourceCardView(source: source)
                        }
                    }
                    if !sourceManager.sources.contains(where: { $0 is VideoSource }) {
                        Text("No Sources Found.")
                    }
                }
            }.navigationTitle("Browse")
        }
    }
}
