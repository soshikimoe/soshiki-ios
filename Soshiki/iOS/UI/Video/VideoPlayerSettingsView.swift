//
//  VideoPlayerSettingsView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/2/23.
//

import SwiftUI

struct VideoPlayerSettingsView: View {
    @ObservedObject var videoPlayerViewModel: VideoPlayerViewModel

    var body: some View {
        Form {
            Section("General") {
                Toggle("Auto Play on Open", isOn: $videoPlayerViewModel.autoPlay)
                Toggle("Auto Play Next Episode", isOn: $videoPlayerViewModel.autoNextEpisode)
                Toggle("Persist Time on Server Change", isOn: $videoPlayerViewModel.persistTimestamp)
            }
            Section("Quality") {
                if let details = videoPlayerViewModel.details {
                    let byQuality = providerUrlsByQuality(details.providers)
                    ForEach(byQuality, id: \.quality) { quality in
                        Text(quality.quality.flatMap({ "\($0.toTruncatedString())p" }) ?? "Unknown Quality")
                        ForEach(quality.urls, id: \.url) { url in
                            Button {
                                if let url = URL(string: url.url) {
                                    Task {
                                        await videoPlayerViewModel.viewController.setUrl(url)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(url.provider)
                                    Spacer()
                                    if url.url == videoPlayerViewModel.currentlyPlayingUrl?.absoluteString {
                                        Image(systemName: "checkmark").foregroundColor(.accentColor)
                                    }
                                }
                            }.foregroundColor(.white)
                                .padding(.leading, 20)
                        }
                    }
                }
            }
        }
    }

    func providerUrlsByQuality(_ providers: [VideoSourceEpisodeProvider]) -> [(quality: Float?, urls: [(provider: String, url: String)])] {
        var byQuality = [(quality: Float?, urls: [(provider: String, url: String)])]()
        for provider in providers {
            for url in provider.urls {
                if let index = byQuality.firstIndex(where: { $0.quality == url.quality }) {
                    byQuality[index].urls.append((provider: provider.name, url: url.url))
                } else {
                    byQuality.append((quality: url.quality, urls: [(provider: provider.name, url: url.url)]))
                }
            }
        }
        return byQuality.sorted(by: { quality1, quality2 in
            (quality1.quality ?? 0) > (quality2.quality ?? 0)
        })
    }
}
