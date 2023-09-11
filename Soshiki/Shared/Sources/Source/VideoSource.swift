//
//  VideoSource.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/1/23.
//

import Foundation

protocol VideoSource: Source {
    func getEpisodes(id: String, page: Int) async -> SourceResults<VideoSourceEpisode>?
    func getEpisodeDetails(id: String, entryId: String) async -> VideoSourceEpisodeDetails?
    func modifyVideoRequest(request: URLRequest) async -> URLRequest?
}
