//
//  EntryRowView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/1/23.
//

import SwiftUI
import NukeUI

struct EntryRowView: View {
    let entry: LocalEntry

    var newCount = 0
    var unseenCount = 0

    var body: some View {
        HStack {
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
            .frame(width: 50, height: 75)
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(entry.title)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                            .font(.body, weight: .bold)
                            .multilineTextAlignment(.leading)
                            .padding(.top)
                        Spacer()
                        if newCount != 0 {
                            Text(newCount >= 100 ? "99+" : " \(newCount) ")
                                .background(.blue)
                                .foregroundColor(.white)
                                .font(.body, weight: .bold)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        if unseenCount != 0 {
                            Text(unseenCount >= 100 ? " 99+ " : " \(unseenCount) ")
                                .background(.red)
                                .foregroundColor(.white)
                                .font(.body, weight: .bold)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                    Text(entry.staff[safe: 0] ?? "")
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
            }
        }
    }
}
