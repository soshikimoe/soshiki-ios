//
//  LocalTextSource.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/15/23.
//

import Foundation

class LocalTextSource: JSTextSource {
    static let shared = LocalTextSource()

    init() {
        let context = JSContext()!
        super.init(id: "local", name: "Local", author: "", version: "1.0.0", image: <#T##URL#>, context: <#T##JSContext#>)
    }
}
