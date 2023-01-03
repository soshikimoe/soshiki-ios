//
//  LoginView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/2/23.
//

import SwiftUI
import WebKit

struct LoginView: UIViewRepresentable {
    let delegate = LoginViewDelegate()

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = delegate
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: URL(string: "https://api.soshiki.moe/user/login/discord/redirect")!))
    }
}

class LoginViewDelegate: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            if webView.url?.absoluteString.contains("https://soshiki.moe/account/redirect") == true {
                if let access = webView.url?.absoluteString.split(separator: "&")
                    .first(where: { $0.split(separator: "=").first == "access" })?
                    .split(separator: "=").last?.removingPercentEncoding {
                    SoshikiAPI.shared.token = access
                }
            }
        }
    }
}
