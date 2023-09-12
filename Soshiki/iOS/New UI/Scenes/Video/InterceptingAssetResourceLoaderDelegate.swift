//
//  InterceptingAssetResourceLoaderDelegate.swift
//  Soshiki
//
//  Created by Jim Phieffer on 9/5/23.
//
//  Adapted from https://github.com/kanderson-wellbeats/sideloadWebVttToAVPlayer/blob/main/CustomResourceLoaderDelegate.cs
//

import AVKit

class InterceptingAssetResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    private class SubtitleBundle {
        internal init(subtitleDTO: InterceptingAssetResourceLoaderDelegate.SubtitleDTO, playlist: String? = nil) {
            self.subtitleDTO = subtitleDTO
            self.playlist = playlist
        }

        let subtitleDTO: SubtitleDTO
        var playlist: String?
    }

    private struct SubtitleDTO {
        let language: String
        let title: String
        let url: String
    }

    static let videoUrlPrefix = "INTERCEPTEDVIDEO"
    static let subtitleUrlPrefix = "INTERCEPTEDSUBTITLE"
    static let subtitleUrlSuffix = "m3u8"
    private let session: URLSession
    private let subtitleBundles: [SubtitleBundle]

    init(_ subtitles: [VideoSourceEpisodeUrlSubtitle]) {
        self.session = URLSession(configuration: .default)
        self.subtitleBundles = subtitles.map({
            SubtitleBundle(subtitleDTO: SubtitleDTO(language: $0.language, title: $0.name, url: $0.url))
        })
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let url = loadingRequest.request.url,
              let dataRequest = loadingRequest.dataRequest else { return true }
        if url.absoluteString.starts(with: Self.subtitleUrlPrefix) {
            guard let targetLanguage = url.host?.split(separator: ".").first,
                  let targetSubtitle = self.subtitleBundles.first(where: { $0.subtitleDTO.language == targetLanguage }),
                  let subtitleUrl = URL(string: targetSubtitle.subtitleDTO.url) else {
                loadingRequest.finishLoading(with: AVError(.unknown))
                return true
            }

            let subtitlePlaylistTask = self.session.dataTask(with: subtitleUrl) { [weak self] data, _, error in
                if let error {
                    loadingRequest.finishLoading(with: error)
                    return
                }
                guard let data, !data.isEmpty, let dataString = String(data: data, encoding: .utf8) else {
                    loadingRequest.finishLoading(with: AVError(.unknown))
                    return
                }

                self?.makePlaylistAndFragments(bundle: targetSubtitle, subtitle: dataString)

                guard let playlistData = targetSubtitle.playlist?.data(using: .utf8) else {
                    loadingRequest.finishLoading(with: AVError(.unknown))
                    return
                }
                dataRequest.respond(with: playlistData)
                loadingRequest.finishLoading()
            }

            subtitlePlaylistTask.resume()
            return true
        }

        guard let newUrl = URL(string: url.absoluteString.replacingOccurrences(of: Self.videoUrlPrefix, with: "")) else { return true }

        if !(
                url.absoluteString.lowercased().hasSuffix(".ism/manifest(format=m3u8-aapl)") ||
                url.absoluteString.lowercased().hasSuffix(".m3u8")
            ) || (
            dataRequest.requestedOffset == 0 && dataRequest.requestedLength == 2 && dataRequest.currentOffset == 0
        ) {
            let newRequest = URLRequest(url: newUrl)
            loadingRequest.redirect = newRequest
            let fakeResponse = HTTPURLResponse(url: newUrl, statusCode: 302, httpVersion: nil, headerFields: nil)
            loadingRequest.response = fakeResponse
            loadingRequest.finishLoading()
            return true
        }

        var correctedRequest = URLRequest(url: newUrl)
        for header in loadingRequest.request.allHTTPHeaderFields ?? [:] {
            correctedRequest.addValue(header.value, forHTTPHeaderField: header.key)
        }

        let masterPlaylistTask = self.session.dataTask(with: correctedRequest) { [weak self] data, _, error in
            if let error {
                loadingRequest.finishLoading(with: error)
                return
            }

            guard let data,
                  let dataString = String(data: data, encoding: .utf8),
                  let withSubs = self?.addSubs(to: dataString),
                  let withSubsData = withSubs.data(using: .utf8) else {
                loadingRequest.finishLoading(with: AVError(.unknown))
                return
            }
            dataRequest.respond(with: withSubsData)
            loadingRequest.finishLoading()
        }
        masterPlaylistTask.resume()
        return true
    }

    func addSubs(to dataString: String) -> String {
        guard dataString.contains("#EXT-X-STREAM-INF:"), !self.subtitleBundles.isEmpty else { return dataString }
        var tracks = dataString.split(separator: "\n").map({ $0.hasPrefix("#EXT-X-STREAM-INF:") ? $0 + ",SUBTITLES=\"subs\"" : $0 })
        tracks.insert(contentsOf: self.subtitleBundles.map({
            "#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID=\"subs\",LANGUAGE=\"\($0.subtitleDTO.language)\",NAME=\"\($0.subtitleDTO.title)\","
            + "AUTOSELECT=YES,CHARACTERISTICS=\"public.accessibility.transcribes-spoken-dialog\""
            + ",URI=\"\(Self.subtitleUrlPrefix)://\($0.subtitleDTO.language).\(Self.subtitleUrlSuffix)\""
        }), at: tracks.firstIndex(where: { $0.contains("#EXT-X-STREAM-INF") }) ?? tracks.endIndex)
        return tracks.joined(separator: "\n")
    }

    private func makePlaylistAndFragments(bundle: SubtitleBundle, subtitle: String) {
        if let regex = try? NSRegularExpression(pattern: #"(\d{2}:\d{2}:\d{2}.\d{3})"#),
           let timeString = regex.matches(in: subtitle, range: NSRange(location: 0, length: subtitle.count)).last.flatMap({
               (subtitle as NSString).substring(with: $0.range)
           }),
           let hour = timeString.split(separator: ":")[safe: 0].flatMap({ Double($0) }), hour.isFinite,
           let minute = timeString.split(separator: ":")[safe: 1].flatMap({ Double($0) }), minute.isFinite,
           let second = timeString.split(separator: ":")[safe: 2].flatMap({ Double($0) }), second.isFinite {
            let rounded = Int(ceil(hour * 3600 + minute * 60 + second))
            bundle.playlist = [
                "#EXTM3U",
                "#EXT-X-TARGETDURATION:\(rounded)",
                "#EXT-X-VERSION:3",
                "#EXT-X-MEDIA-SEQUENCE:0",
                "#EXT-X-PLAYLIST-TYPE:VOD",
                "#EXTINF:\(rounded)",
                bundle.subtitleDTO.url,
                "#EXT-X-ENDLIST"
            ].joined(separator: "\n")
        } else if let regex = try? NSRegularExpression(pattern: #"(\d{2}:\d{2}.\d{3})"#),
                  let timeString = regex.matches(in: subtitle, range: NSRange(location: 0, length: subtitle.count)).last.flatMap({
                      (subtitle as NSString).substring(with: $0.range)
                  }),
                  let minute = timeString.split(separator: ":")[safe: 0].flatMap({ Double($0) }), minute.isFinite,
                  let second = timeString.split(separator: ":")[safe: 1].flatMap({ Double($0) }), second.isFinite {
            let rounded = Int(ceil(minute * 60 + second))
            bundle.playlist = [
                "#EXTM3U",
                "#EXT-X-TARGETDURATION:\(rounded)",
                "#EXT-X-VERSION:3",
                "#EXT-X-MEDIA-SEQUENCE:0",
                "#EXT-X-PLAYLIST-TYPE:VOD",
                "#EXTINF:\(rounded)",
                bundle.subtitleDTO.url,
                "#EXT-X-ENDLIST"
            ].joined(separator: "\n")
        }
    }
}
