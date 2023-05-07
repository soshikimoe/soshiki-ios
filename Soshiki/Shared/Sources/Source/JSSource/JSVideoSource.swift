//
//  JSVideoSource.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/15/23.
//

import Foundation
import JavaScriptCore

class JSVideoSource: JSSource, VideoSource {
    func getEpisodes(id: String) async -> [VideoSourceEpisode] {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: []) }
            let callbackId = "getEpisodesCallback_\(String.random())"
            let errorId = "getEpisodesError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ entry in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let dict = entry.toArray() as? [[String: Any]] {
                    return callback.resume(returning: dict.compactMap({ episode in
                        if let id = episode["id"] as? String,
                           let entryId = episode["entryId"] as? String,
                           let episodeNumber = episode["episode"] as? Double,
                           let type = (episode["type"] as? String).flatMap({ VideoSourceEpisodeType(rawValue: $0) }) {
                            return VideoSourceEpisode(
                                id: id,
                                entryId: entryId,
                                name: episode["name"] as? String,
                                episode: episodeNumber,
                                season: episode["season"] as? Double,
                                type: type,
                                thumbnail: episode["thumbnail"] as? String,
                                timestamp: episode["timestamp"] as? Double
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
            object.invokeMethod("_getEpisodes", withArguments: [callbackValue, errorValue, id])
        }
    }

    func getEpisodeDetails(id: String, entryId: String) async -> VideoSourceEpisodeDetails? {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: nil) }
            let callbackId = "getEpisodeDetailsCallback_\(String.random())"
            let errorId = "getEpisodeDetailsError_\(String.random())"
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ entry in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let dict = entry.toObject() as? [String: Any],
                   let id = dict["id"] as? String,
                   let entryId = dict["entryId"] as? String,
                   let providers = dict["providers"] as? [[String: Any]] {
                    return callback.resume(returning: VideoSourceEpisodeDetails(
                        id: id,
                        entryId: entryId,
                        providers: providers.compactMap({ provider in
                            if let name = provider["name"] as? String,
                               let urls = provider["urls"] as? [[String: Any]] {
                                return VideoSourceEpisodeProvider(
                                    name: name,
                                    urls: urls.compactMap({ url in
                                        if let type = (url["type"] as? String).flatMap({ VideoSourceEpisodeUrlType(rawValue: $0) }),
                                           let urlString = url["url"] as? String {
                                            return VideoSourceEpisodeUrl(
                                                type: type,
                                                url: urlString,
                                                quality: url["quality"] as? Double
                                            )
                                        } else {
                                            return nil
                                        }
                                    }).sorted(by: { url1, url2 in
                                        (url1.quality ?? 0) > (url2.quality ?? 0)
                                    })
                                )
                            } else {
                                return nil
                            }
                        })
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
            object.invokeMethod("_getEpisodeDetails", withArguments: [callbackValue, errorValue, id, entryId])
        }
    }

    func modifyVideoRequest(request: URLRequest) async -> URLRequest? {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: nil) }
            let callbackId = "modifyVideoRequestCallback_\(String.random())"
            let errorId = "modifyVideoRequestError_\(String.random())"
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
                    return callback.resume(returning: request)
                }
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId as NSString)
            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                print(error.toString() ?? "JSContext Error")
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId as NSString)
            guard let url = request.url?.absoluteString,
                  let object = self.context.objectForKeyedSubscript(self.id),
                  let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: nil)
            }
            var options: [String: Any] = [:]
            if let method = request.httpMethod {
                options["method"] = method
            }
            if let headers = request.allHTTPHeaderFields {
                options["headers"] = headers
            }
            if let body = request.httpBody.flatMap({ String(data: $0, encoding: .utf8) }) {
                options["body"] = body
            }
            object.invokeMethod("_modifyVideoRequest", withArguments: [callbackValue, errorValue, url, options])
        }
    }
}
