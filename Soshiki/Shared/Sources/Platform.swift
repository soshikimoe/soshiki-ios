//
//  SourceContext.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/20/22.
//

import JavaScriptCore

protocol Listable {
    var id: String { get }
    var name: String { get }
    var author: String { get }
    var image: URL? { get }
}

class Platform: Listable {
    let id: String
    let name: String
    let author: String
    let image: URL?
    let version: String
    let context: JSContext
    var sources: [Source] = []

    init?(directory: URL) {
        let manifestFile = directory.appendingPathComponent("manifest.json", conformingTo: .json)
        guard FileManager.default.fileExists(atPath: manifestFile.absoluteString),
              let manifestData = try? Data(contentsOf: manifestFile),
              let manifest = try? JSONDecoder().decode(PlatformManifest.self, from: manifestData) else { return nil }
        let sourceFile = directory.appendingPathComponent("translator.js", conformingTo: .javaScript)
        guard FileManager.default.fileExists(atPath: sourceFile.absoluteString),
              let sourceData = try? Data(contentsOf: sourceFile),
              let script = String(data: sourceData, encoding: .utf8) else { return nil }
        guard let context = JSContext() else { return nil }
        context.evaluateScript(script)

        context.evaluateScript("globalThis.Translator = new globalThis.__Translator__.default()")

        context.objectForKeyedSubscript("console").setObject({ message in
            print("JSContext (\(manifest.name)) console.log: \(message)")
        } as @convention(block) (String) -> Void, forKeyedSubscript: "log")
        context.objectForKeyedSubscript("console").setObject({ message in
            print("JSContext (\(manifest.name)) console.warn: \(message)")
        } as @convention(block) (String) -> Void, forKeyedSubscript: "warn")
        context.objectForKeyedSubscript("console").setObject({ message in
            print("JSContext (\(manifest.name)) console.error: \(message)")
        } as @convention(block) (String) -> Void, forKeyedSubscript: "error")
        context.exceptionHandler = { _, value in print("JSContext (\(manifest.name)) error: \(String(describing: value))") }
        context.evaluateScript("globalThis.__callbacks__ = {}")

        let _image = directory.appendingPathComponent(manifest.icon, conformingTo: .png)
        let image = FileManager.default.fileExists(atPath: _image.absoluteString) ? _image : nil

        self.id = manifest.id
        self.name = manifest.name
        self.author = manifest.author
        self.version = manifest.version
        self.image = image
        self.context = context
    }

    @discardableResult
    func addSource(directory: URL) -> Bool {
        if let source = Source(platform: name, directory: directory, context: context) {
            sources.append(source)
            return true
        }
        return false
    }
}

struct PlatformManifest: Codable {
    let id: String
    let name: String
    let author: String
    let icon: String
    let version: String
}
