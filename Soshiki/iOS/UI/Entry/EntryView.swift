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

    @State var sources: [Source] = []

    var accentColor: Color?

    init(entry: Entry) {
        self.entry = entry
        self.accentColor = Color(hex: entry.info?.anilist?.coverImage?.color ?? "")
    }

    @State var descriptionExpanded: Bool = false

    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                LazyImage(url: URL(string: entry.info?.anilist?.bannerImage ?? ""), resizingMode: .aspectFill)
                    .frame(height: 250)
                    .overlay {
                        LinearGradient(colors: [.clear, Color(uiColor: UIColor.systemBackground)], startPoint: .top, endPoint: .bottom)
                    }
                VStack(alignment: .leading) {
                    Spacer(minLength: 150)
                    HStack(spacing: 20) {
                        LazyImage(url: URL(string: entry.info?.anilist?.coverImage?.large ?? entry.info?.cover ?? "")) { state in
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
                            Text(entry.info?.anilist?.title?.english ?? entry.info?.anilist?.title?.romaji ?? entry.info?.title ?? "")
                                .font(.title2)
                                .fontWeight(.heavy)
                            if let mainStaff = entry.info?.anilist?.staff?.first?.name?.full {
                                Text(mainStaff)
                                    .foregroundColor(.secondary)
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    if let anilistDescription = entry.info?.anilist?.description {
                        Text(anilistDescription
                                .replacing("<br />", with: "\n")
                             // swiftlint:disable:next force_try
                                .replacing(try! Regex("<.*?>"), with: "") + "\n\nData provided by the Anilist API.")
                            .lineLimit(descriptionExpanded ? 100 : 4)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.subheadline)
                    } else if let malDescription = entry.info?.mal?.synopsis {
                        Text(malDescription + "\n\nData provided by the MyAnimeList API.")
                            .lineLimit(descriptionExpanded ? nil : 4)
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
//                    if let _ = sources as? [TextSource] {
//
//                    } else
                    if let sources = sources as? [ImageSource] {
                        ImageSourceChaptersView(entry: entry, sources: sources)
                    } else if let sources = sources as? [VideoSource] {
                        VideoSourceEpisodesView(entry: entry, sources: sources)
                    }
                }.padding(10)
            }
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
            .onAppear {
                sources = SourceManager.shared.sources.filter({ source in
                    contentViewModel.currentMediaType == .text
                        ? source is TextSource
                        : contentViewModel.currentMediaType == .image ? source is ImageSource : source is VideoSource
                }).filter({ source in
                    entry.platforms?.first(where: { $0.name == "Soshiki" })?.sources?.contains(where: { $0.name == source.id }) == true
                })
            }
    }
}
