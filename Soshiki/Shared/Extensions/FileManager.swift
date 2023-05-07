//
//  FileManager.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/23/22.
//

import Foundation

extension FileManager {
    var documentDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
