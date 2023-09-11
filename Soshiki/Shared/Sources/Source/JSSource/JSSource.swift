//
//  JSSource.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/15/23.
//

import Foundation
import JavaScriptCore

protocol JSSource: AnyObject, NetworkSource {
    var id: String { get }
    var name: String { get }
    var author: String { get }
    var version: String { get }
    var image: URL { get }
    var context: JSContext { get }

    init(id: String, name: String, author: String, version: String, image: URL, context: JSContext)

}

extension JSSource {
    func getFilters() async -> [SourceFilterGroup] {
        await invokeAsyncMethod("_getFilters", on: self.context.objectForKeyedSubscript(self.id), with: []) ?? []
    }

    func getListings() async -> [SourceListing] {
        await invokeAsyncMethod("_getListings", on: self.context.objectForKeyedSubscript(self.id), with: []) ?? []
    }

    func getSettings() async -> [SourceFilterGroup] {
        await invokeAsyncMethod("_getSettings", on: self.context.objectForKeyedSubscript(self.id), with: []) ?? []
    }

    static func == (lhs: any JSSource, rhs: any JSSource) -> Bool {
        lhs.id == rhs.id && type(of: lhs) == type(of: rhs)
    }

    func invokeAsyncMethod<T: Decodable>(_ methodName: String, on object: JSValue, with arguments: [any Encodable]) async -> T? {
        await withCheckedContinuation { [weak self] callback in
            guard let self = self else { return callback.resume(returning: nil) }
            let callbackId = String.random()
            let errorId = String.random()

            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ [weak self] value in
                guard let self = self else { return callback.resume(returning: nil) }
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                if let valueObject = value.toObject(),
                   let object = try? T.fromObject(valueObject) {
                    return callback.resume(returning: object)
                }

                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: callbackId)

            self.context.objectForKeyedSubscript("__callbacks__" as NSString).setObject({ error in
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(callbackId)
                self.context.objectForKeyedSubscript("__callbacks__").deleteProperty(errorId)
                LogManager.shared.log(error.toString() ?? "JSContext Error", at: .error)
                return callback.resume(returning: nil)
            } as @convention(block) (JSValue) -> Void, forKeyedSubscript: errorId)

            guard let callbackValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(callbackId),
                  let errorValue = self.context.objectForKeyedSubscript("__callbacks__").objectForKeyedSubscript(errorId) else {
                return callback.resume(returning: nil)
            }

            object.invokeMethod(
                methodName,
                withArguments: [ callbackValue, errorValue ] + arguments.compactMap({ try? $0.toObject() })
            )
        }
    }
}
