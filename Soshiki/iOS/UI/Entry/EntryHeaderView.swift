//
//  EntryHeaderView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/5/23.
//

import SwiftUI
import NukeUI

struct EntryHeaderView: View {
    let entry: UnifiedEntry

    @State var descriptionExpanded = false

    var body: some View {
        ZStack(alignment: .top) {
            LazyImage(url: URL(string: entry.banner ?? ""), resizingMode: .aspectFill)
                .frame(height: 250)
                .overlay {
                    LinearGradient(colors: [.clear, Color(uiColor: UIColor.systemBackground)], startPoint: .top, endPoint: .bottom)
                }
            VStack(alignment: .leading) {
                Spacer(minLength: 150)
                HStack(spacing: 20) {
                    LazyImage(url: URL(string: entry.cover)) { state in
                        if let image = state.image {
                            image
                        } else if state.error != nil {
                            Rectangle()
                                .overlay {
                                    Image(systemName: "exclamationmark.triangle")
                                }
                                .foregroundColor(.gray)
                        } else {
                            Rectangle()
                                .foregroundColor(.gray)
                        }
                    }.aspectRatio(1/1.5, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .frame(width: 150, height: 225)
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(style: StrokeStyle(lineWidth: 0.25))
                            .foregroundColor(.gray)
                        )
                    VStack(alignment: .leading) {
                        Spacer(minLength: 0)
                        Text(entry.title)
                            .font(.title2)
                            .fontWeight(.heavy)
                        if let mainStaff = entry.staff.first {
                            Text(mainStaff)
                                .foregroundColor(.secondary)
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                    Spacer(minLength: 0)
                }
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(entry.tags, id: \.self) { tag in
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.secondarySystemBackground)
                                Text(tag.uppercased())
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .font(.caption)
                                    .fontWeight(.heavy)
                            }
                        }
                    }
                }.scrollIndicators(.hidden)
                if let description = entry.description {
                    Text(description)
                        .lineLimit(descriptionExpanded ? 100 : 4)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.subheadline)
                }
                HStack {
                    Spacer()
                    Button {
                        descriptionExpanded.toggle()
                    } label: {
                        Text(descriptionExpanded ? "See Less" : "See More")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                }
            }.padding(10)
        }.edgesIgnoringSafeArea(.top)
            .navigationBarBackButtonHidden(true)
            .tint(entry.color.flatMap({ Color(hex: $0) }) ?? .accentColor)
    }
}
