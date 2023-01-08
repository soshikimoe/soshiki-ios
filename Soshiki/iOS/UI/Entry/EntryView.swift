//
//  EntryView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/19/22.
//

import SwiftUI
import NukeUI

struct EntryView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State var shown = false

    var entry: Entry

    @EnvironmentObject var contentViewModel: ContentViewModel

    var accentColor: Color?

    @State var sources: [Source] = []

    init(entry: Entry) {
        self.entry = entry
        self.accentColor = Color(hex: entry.color ?? "")
    }

    var body: some View {
        ScrollView {
            EntryHeaderView(entry: entry.toUnifiedEntry())
            EntrySourceListView(entry: entry)
        }.edgesIgnoringSafeArea(.top)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .foregroundStyle(.white, .tint, .tint)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {

                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundStyle(.white, .tint, .tint)
                    }
                }
            }.tint(accentColor)
    }
}
