//
//  ImageSource.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/31/22.
//

import Foundation
import Nuke

protocol ImageSource: Source {
    func getChapters(id: String, page: Int) async -> SourceResults<ImageSourceChapter>?
    func getChapterDetails(id: String, entryId: String) async -> ImageSourceChapterDetails?
    func modifyImageRequest(request: ImageRequest) async -> ImageRequest?
}
