//
//  EntryRowView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/1/23.
//

import SwiftUI
import NukeUI

struct EntryRowView: View {
    var title: String
    var subtitle: String
    var cover: String

    var newCount = 0
    var unseenCount = 0

    var body: some View {
        HStack {
            LazyImage(url: URL(string: cover)) { state in
                if let image = state.image {
                    image.resizingMode(.aspectFill)
                } else if state.error != nil {
                    Rectangle()
                        .overlay {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.black)
                        }
                        .foregroundColor(.gray)
                } else {
                    Rectangle()
                        .foregroundColor(.gray)
                }
            }
            .aspectRatio(1/1.5, contentMode: .fit)
            .overlay(LinearGradient(colors: [.clear, .init(white: 0, opacity: 0.8)], startPoint: .center, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(style: StrokeStyle(lineWidth: 0.25))
                .foregroundColor(.gray)
            )
            .frame(width: 100, height: 150)
            ZStack(alignment: .topLeading) {
                HStack(spacing: 5) {
                    Spacer()
                    if newCount != 0 {
                        Text(newCount >= 100 ? "99+" : " \(newCount) ")
                            .background(.blue)
                            .foregroundColor(.white)
                            .bold()
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    if unseenCount != 0 {
                        Text(unseenCount >= 100 ? " 99+ " : " \(unseenCount) ")
                            .background(.red)
                            .foregroundColor(.white)
                            .bold()
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
                VStack(alignment: .leading) {
                    Text(title)
                        .lineLimit(3)
                        .foregroundColor(.white)
                        .bold()
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .lineLimit(3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
}
