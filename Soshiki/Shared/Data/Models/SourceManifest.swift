//
//  SourceManifest.swift
//  Soshiki
//
//  Created by Jim Phieffer on 8/20/23.
//

import RealmSwift
import Unrealm

protocol SourceManifest: Realmable, Codable {
    var path: String { get set }
    var name: String { get set }
    var author: String { get set }
    var id: String { get set }
    var icon: String { get set }
    var version: String { get set }
    var type: String { get set }
    var schema: Int { get set }
    var baseUrl: String? { get set }
}

final class TextSourceManifest: SourceManifest, Realmable, Codable {
    init() {}

    internal init(
        uuid: String = UUID().uuidString,
        path: String,
        name: String,
        author: String,
        id: String,
        icon: String,
        version: String,
        type: String,
        schema: Int,
        baseUrl: String
    ) {
        self.uuid = uuid
        self.path = path
        self.name = name
        self.author = author
        self.id = id
        self.icon = icon
        self.version = version
        self.type = type
        self.schema = schema
        self.baseUrl = baseUrl
    }

    var uuid: String = UUID().uuidString
    var path: String = ""
    var name: String = ""
    var author: String = ""
    var id: String = ""
    var icon: String = ""
    var version: String = ""
    var type: String = ""
    var schema: Int = 0
    var baseUrl: String?

    static func primaryKey() -> String? { "uuid" }

    private enum CodingKeys: String, CodingKey {
        case path, name, author, id, icon, version, type, schema
    }
}

final class ImageSourceManifest: SourceManifest, Realmable, Codable {
    init() {}

    internal init(
        uuid: String = UUID().uuidString,
        path: String,
        name: String,
        author: String,
        id: String,
        icon: String,
        version: String,
        type: String,
        schema: Int,
        baseUrl: String
    ) {
        self.uuid = uuid
        self.path = path
        self.name = name
        self.author = author
        self.id = id
        self.icon = icon
        self.version = version
        self.type = type
        self.schema = schema
        self.baseUrl = baseUrl
    }

    var uuid: String = UUID().uuidString
    var path: String = ""
    var name: String = ""
    var author: String = ""
    var id: String = ""
    var icon: String = ""
    var version: String = ""
    var type: String = ""
    var schema: Int = 0
    var baseUrl: String?

    static func primaryKey() -> String? { "uuid" }

    private enum CodingKeys: String, CodingKey {
        case path, name, author, id, icon, version, type, schema, baseUrl
    }
}

final class VideoSourceManifest: SourceManifest, Realmable, Codable {
    init() {}

    internal init(
        uuid: String = UUID().uuidString,
        path: String,
        name: String,
        author: String,
        id: String,
        icon: String,
        version: String,
        type: String,
        schema: Int,
        baseUrl: String
    ) {
        self.uuid = uuid
        self.path = path
        self.name = name
        self.author = author
        self.id = id
        self.icon = icon
        self.version = version
        self.type = type
        self.schema = schema
        self.baseUrl = baseUrl
    }

    var uuid: String = UUID().uuidString
    var path: String = ""
    var name: String = ""
    var author: String = ""
    var id: String = ""
    var icon: String = ""
    var version: String = ""
    var type: String = ""
    var schema: Int = 0
    var baseUrl: String?

    static func primaryKey() -> String? { "uuid" }

    private enum CodingKeys: String, CodingKey {
        case path, name, author, id, icon, version, type, schema
    }
}
