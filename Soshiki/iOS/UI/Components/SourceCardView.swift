//
//  SourceCardView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/30/22.
//

import SwiftUI

struct SourceCardView: View {
    var source: Source
    var body: some View {
        HStack {
            if let uiImage = UIImage(contentsOfFile: source.image.path()) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading) {
                Text(source.name)
                    .fontWeight(.semibold)
                Text(source.author)
                    .foregroundColor(.secondary)
            }
        }
    }
}
