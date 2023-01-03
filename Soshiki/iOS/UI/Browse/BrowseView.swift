//
//  BrowseView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/30/22.
//

import SwiftUI

struct BrowseView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Text") {
                    ForEach(SourceManager.shared.sources.filter({ $0 is TextSource }), id: \.id) { source in
                        NavigationLink {
                            SourceView(source: source)
                        } label: {
                            SourceCardView(source: source)
                        }
                    }
                    if !SourceManager.shared.sources.contains(where: { $0 is TextSource }) {
                        Text("No Sources Found.")
                    }
                }
                Section("Image") {
                    ForEach(SourceManager.shared.sources.filter({ $0 is ImageSource }), id: \.id) { source in
                        NavigationLink {
                            SourceView(source: source)
                        } label: {
                            SourceCardView(source: source)
                        }
                    }
                    if !SourceManager.shared.sources.contains(where: { $0 is ImageSource }) {
                        Text("No Sources Found.")
                    }
                }
                Section("Video") {
                    ForEach(SourceManager.shared.sources.filter({ $0 is VideoSource }), id: \.id) { source in
                        NavigationLink {
                            SourceView(source: source)
                        } label: {
                            SourceCardView(source: source)
                        }
                    }
                    if !SourceManager.shared.sources.contains(where: { $0 is VideoSource }) {
                        Text("No Sources Found.")
                    }
                }
            }
        }
    }
}
