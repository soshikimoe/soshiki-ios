//
//  WebView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/2/23.
//

import SwiftUI
import SafariServices

struct WebView: UIViewControllerRepresentable {
    var url: URL
    var safariViewController: SFSafariViewController?

    func makeUIViewController(context: Context) -> SFSafariViewController {
        safariViewController ?? SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {

    }
}
