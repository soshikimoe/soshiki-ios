//
//  JSPromise.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/20/22.
//

@preconcurrency import JavaScriptCore

class JSFetch {
    static func inject(into context: JSContext) {
        let fetch: @convention(block) (String, JSValue, JSValue, JSValue) -> Void = { urlString, optionsValue, resolve, reject in
            guard let url = URL(string: urlString) else {
                reject.call(withArguments: ["Invalid URL"])
                return
            }
            guard let options = optionsValue.toDictionary() as? [String: Any] else {
                reject.call(withArguments: ["Invalid options"])
                return
            }
            var request = URLRequest(url: url)
            if let method = options["method"] as? String {
                request.httpMethod = method
            }
            if let headers = options["headers"] as? [String: String] {
                for key in headers.keys {
                    request.setValue(headers[key], forHTTPHeaderField: key)
                }
            }
            if let body = options["body"] as? String {
                request.httpBody = body.data(using: .utf8)
            }
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let response = response as? HTTPURLResponse, let data, let dataString = String(data: data, encoding: .utf8) {
                    resolve.call(withArguments: [[
                        "data": dataString,
                        "status": response.statusCode,
                        "statusText": HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
                        "headers": response.allHeaderFields as? [String: String] ?? [:]
                    ]])
                } else {
                    reject.call(withArguments: [error?.localizedDescription ?? "An error occured while fetching \(urlString)"])
                }
            }.resume()
        }
        context.setObject(fetch, forKeyedSubscript: "__fetch__" as NSString)
    }
}
