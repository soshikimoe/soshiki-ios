//
//  SourceCardView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/30/22.
//

import NukeUI
import SwiftUI

struct SourceEntryCellView: View {
    var entry: SourceShortEntry

    var body: some View {
        LazyImage(url: URL(string: entry.cover)) { state in
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
            .overlay {
                VStack(alignment: .leading) {
                    Spacer()
                    HStack {
                        Text(entry.title)
                            .lineLimit(3)
                            .foregroundColor(.white)
                            .bold()
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                }.padding(5)
            }
    }
}
