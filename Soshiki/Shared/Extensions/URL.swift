//
//  URL.swift
//  Soshiki
//
//  Created by Jim Phieffer on 5/7/23.
//
//  From https://stackoverflow.com/a/66254547
//

import UniformTypeIdentifiers

extension URL {
    public func mimeType() -> String {
        if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
            return mimeType
        } else {
            return "application/octet-stream"
        }
    }
}
