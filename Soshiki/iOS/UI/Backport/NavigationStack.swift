//
//  NavigationStack.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/20/23.
//

import SwiftUI

struct NavigationStack<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if #available(iOS 16, *) {
            SwiftUI.NavigationStack {
                content()
            }
        } else {
            NavigationView {
                content()
            }.navigationViewStyle(.stack)
        }
    }
}
