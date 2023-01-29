//
//  JSTextSource.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/15/23.
//

import Foundation
import JavaScriptCore

class JSTextSource: JSSource, TextSource {
    func getChapters(id: String) async -> [TextSourceChapter] {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: []) }
            let callbackId = "getChaptersCallback_\(String.random())"
            let errorId = "getChaptersError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ entry in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let dict = entry.toArray() as? [[String: Any]] {
                    return callback.resume(returning: dict.compactMap({ chapter in
                        if let id = chapter["id"] as? String,
                           let entryId = chapter["entryId"] as? String,
                           let chapterNumber = chapter["chapter"] as? Double {
                            return TextSourceChapter(
                                id: id,
                                entryId: entryId,
                                name: chapter["name"] as? String,
                                chapter: chapterNumber,
                                volume: chapter["volume"] as? Double,
                                translator: chapter["translator"] as? String
                            )
                        } else {
                            return nil
                        }
                    }))
                }
                return callback.resume(returning: [])
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                print(error.toString() ?? "JSContext Error")
                return callback.resume(returning: [])
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: [])
            }
            object.invokeMethod("_getChapters", withArguments: [callbackValue, errorValue, id])
        }
    }

    func getChapterDetails(id: String, entryId: String) async -> TextSourceChapterDetails? {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: nil) }
            let callbackId = "getChapterDetailsCallback_\(String.random())"
            let errorId = "getChapterDetailsError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ entry in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let dict = entry.toObject() as? [String: Any],
                   let id = dict["id"] as? String,
                   let entryId = dict["entryId"] as? String,
                   let html = dict["html"] as? String {
                    return callback.resume(returning: TextSourceChapterDetails(
                        id: id,
                        entryId: entryId,
                        html: html,
                        baseUrl: dict["baseUrl"] as? String
                    ))
                }
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                print(error.toString() ?? "JSContext Error")
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: nil)
            }
            object.invokeMethod("_getChapterDetails", withArguments: [callbackValue, errorValue, id, entryId])
        }
    }
}
