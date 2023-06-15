//
//  JSImageSource.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/15/23.
//

import Foundation
import JavaScriptCore
import Nuke

class JSImageSource: JSSource, ImageSource {
    func getChapters(id: String) async -> [ImageSourceChapter] {
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
                            return ImageSourceChapter(
                                id: id,
                                entryId: entryId,
                                name: chapter["name"] as? String,
                                chapter: chapterNumber,
                                volume: chapter["volume"] as? Double,
                                translator: chapter["translator"] as? String,
                                thumbnail: chapter["thumbnail"] as? String,
                                timestamp: chapter["timestamp"] as? Double
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
                LogManager.shared.log(error.toString() ?? "JSContext Error", at: .error)
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

    func getChapterDetails(id: String, entryId: String) async -> ImageSourceChapterDetails? {
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
                   let pages = dict["pages"] as? [[String: Any]] {
                    return callback.resume(returning: ImageSourceChapterDetails(
                        id: id,
                        entryId: entryId,
                        pages: pages.compactMap({ page in
                            if let index = page["index"] as? Int {
                                return ImageSourceChapterPage(
                                    index: index,
                                    url: page["url"] as? String,
                                    base64: page["base64"] as? String
                                )
                            } else {
                                return nil
                            }
                        }).sorted(by: { page1, page2 in
                            page1.index < page2.index
                        })
                    ))
                }
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                LogManager.shared.log(error.toString() ?? "JSContext Error", at: .error)
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

    func modifyImageRequest(request: ImageRequest) async -> ImageRequest? {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: nil) }
            let callbackId = "modifyImageRequestCallback_\(String.random())"
            let errorId = "modifyImageRequestError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ data in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let dict = data.toObject() as? [String: Any],
                   let url = (dict["url"] as? String).flatMap({ URL(string: $0) }),
                   let options = dict["options"] as? [String: Any] {
                    var request = URLRequest(url: url)
                    if let method = options["method"] as? String {
                        request.httpMethod = method
                    }
                    if let headers = options["headers"] as? [String: String] {
                        for header in headers {
                            request.setValue(header.value, forHTTPHeaderField: header.key)
                        }
                    }
                    if let body = options["body"] as? String {
                        request.httpBody = body.data(using: .utf8)
                    }
                    return callback.resume(returning: request.asImageRequest())
                }
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                LogManager.shared.log(error.toString() ?? "JSContext Error", at: .error)
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let url = request.urlRequest.url?.absoluteString,
                  let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: nil)
            }
            var options: [String: Any] = [:]
            if let method = request.urlRequest.httpMethod {
                options["method"] = method
            }
            if let headers = request.urlRequest.allHTTPHeaderFields {
                options["headers"] = headers
            }
            if let body = request.urlRequest.httpBody.flatMap({ String(data: $0, encoding: .utf8) }) {
                options["body"] = body
            }
            object.invokeMethod("_modifyImageRequest", withArguments: [callbackValue, errorValue, url, options])
        }
    }
}
