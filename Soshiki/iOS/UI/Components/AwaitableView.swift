//
//  AwaitableView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/5/23.
//

import SwiftUI

struct AwaitableView<T, Content>: View where Content: View {
    @State var result: T?
    let content: (T) -> Content

    init(_ function: @escaping () async -> T, _ content: @escaping (T) -> Content) {
        self.content = content
        Task { [self] in
            self.result = await function()
        }
    }

    var body: some View {
        if let result {
            content(result)
        } else {
            ProgressView()
        }
    }
}
