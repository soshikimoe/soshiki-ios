//
//  SourcesView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/8/23.
//

import SwiftUI

struct SourcesView: View {
    @EnvironmentObject var sourceManager: SourceManager

    @State var addSourceAlertPresented = false
    @State var addSourceAlertTextContent = ""

    var body: some View {
        NavigationStack {
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
            }.navigationTitle("Sources")
        }
    }

    func deleteSource(at offsets: IndexSet) {
        for offset in offsets {
            sourceManager.removeSource(id: sourceManager.sources[offset].id)
        }
    }
}
