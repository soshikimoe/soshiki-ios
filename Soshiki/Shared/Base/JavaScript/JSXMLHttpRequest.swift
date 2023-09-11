//
//  JSXMLHTTPRequest.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/21/22.
//

/*
import JavaScriptCore

class JSXMLHttpRequest {
    static func inject(into context: JSContext) {
        context.setObject(XMLHttpRequest.self, forKeyedSubscript: "XMLHttpRequest" as NSString)
    }
}

@objc fileprivate protocol XMLHttpRequestExports: JSExport {
    var readyState: NSNumber { get }
    var response: NSString { get }
    var responseText: NSString { get }
    var responseType: NSString { get }
    var responseURL: NSString { get }
    var responseXML: NSString { get }
    var status: NSNumber { get }
    var statusText: NSString { get }
    var timeout: NSNumber { get set }
    var withCredentials: Bool { get set }
    
    func abort() -> Void
    func getAllResponseHeaders() -> NSString
    func getResponseHeader(_ headerName: NSString) -> NSString
    func `open`(_ method: NSString, _ url: NSString) -> Void
    func send(_ body: JSValue) -> Void
    func setRequestHeader(_ key: NSString, _ value: NSString) -> Void
    func addEventListener(_ name: NSString, _ callback: JSValue) -> Void
}

@objc fileprivate class XMLHttpRequest: NSObject, XMLHttpRequestExports {
    dynamic var readyState: NSNumber = 0
    dynamic var response: NSString = ""
    dynamic var responseText: NSString = ""
    dynamic var responseType: NSString = ""
    dynamic var responseURL: NSString = ""
    dynamic var responseXML: NSString = ""
    dynamic var status: NSNumber = 0
    dynamic var statusText: NSString = ""
    dynamic var timeout: NSNumber = 0
    dynamic var withCredentials: Bool = false
    
    required override init() {}
    
    private var task: Task<Void, Never>?
    private var _response: HTTPURLResponse?
    private var data: Data?
    
    private var headers: [String: String] = [:]
    private var request: URLRequest?
    
    private var listeners: [String: JSValue] = [:]
    
    func abort() {
        task?.cancel()
        task = nil
        readyState = 4
        listeners["abort"]?.call(withArguments: [])
        listeners["loadend"]?.call(withArguments: [])
        listeners["readystatechange"]?.call(withArguments: [])
    }
    
    func getAllResponseHeaders() -> NSString {
        (_response?.allHeaderFields as? [String: String])?.map({ (key, value) in "\(key): \(value)" }).joined(separator: "\r\n") as? NSString ?? ""
    }
    
    func getResponseHeader(_ headerName: NSString) -> NSString {
        _response?.value(forHTTPHeaderField: headerName as String) as? NSString ?? ""
    }
    
    func open(_ method: NSString, _ url: NSString) {
        if let url = URL(string: url as String) {
            request = URLRequest(url: url)
            request!.httpMethod = method as String
        }
        readyState = 1
    }
    
    func send(_ body: JSValue) {
        guard request != nil else { return }
        for key in headers.keys {
            request!.setValue(headers[key]!, forHTTPHeaderField: key)
        }
        if !body.isNull && !body.isUndefined {
            request!.httpBody = body.toString().data(using: .utf8)
        }
        task = Task { [weak self] in
            self?.listeners["loadstart"]?.call(withArguments: [])
            if let (data, response) = try? await URLSession.shared.data(for: request!) {
                self?.data = data
                self?._response = response as? HTTPURLResponse
                self?.response = String(data: data, encoding: .utf8) as? NSString ?? ""
                self?.responseText = String(data: data, encoding: .utf8) as? NSString ?? ""
                self?.responseType = "text"
                self?.responseURL = response.url?.absoluteString as? NSString ?? ""
                self?.status = self?._response?.statusCode as? NSNumber ?? 0
                self?.statusText = self?.status == 200 ? "OK" : ""
                self?.listeners["load"]?.call(withArguments: [])
                self?.listeners["loadend"]?.call(withArguments: [])
                self?.listeners["readystatechange"]?.call(withArguments: [])
            } else {
                self?.listeners["error"]?.call(withArguments: [])
            }
            self?.readyState = 4
            self?.listeners["loadend"]?.call(withArguments: [])
            self?.listeners["readystatechange"]?.call(withArguments: [])
        }
    }
    
    func setRequestHeader(_ key: NSString, _ value: NSString) {
        headers[key as String] = value as String
    }
    
    func addEventListener(_ name: NSString, _ callback: JSValue) {
        listeners[name as String] = callback
    }
    
    func removeEventListener(_ name: NSString) {
        listeners.removeValue(forKey: name as String)
    }
}
*/
