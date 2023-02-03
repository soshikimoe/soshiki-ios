//
//  TrackerCardView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/8/23.
//

import SwiftUI

struct TrackerCardView: View {
    var tracker: Tracker
    var body: some View {
        HStack {
            if let uiImage = UIImage(contentsOfFile: tracker.image.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading) {
                Text(tracker.name)
                    .fontWeight(.semibold)
                Text(tracker.author)
                    .foregroundColor(.secondary)
            }
        }
    }
}
