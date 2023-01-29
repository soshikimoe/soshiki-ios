//
//  SceneDelegate.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/22/23.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: scene)
        window.rootViewController = MainViewController()
        self.window = window
        window.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if url.pathExtension == "soshikisource" {
                Task {
                    await SourceManager.shared.installSource(url)
                }
            } else if url.pathExtension == "soshikitracker" {
                Task {
                    await TrackerManager.shared.installTracker(url)
                }
            } else if url.pathExtension == "soshikisources" {
                SourceManager.shared.installSources(url)
            } else if url.pathExtension == "epub" {
                // TODO: add
            } else if url.scheme == "soshiki" {
                if url.host == "login" {
                    SoshikiAPI.shared.loginCallback(url)
                } else if url.host == "tracker" {
                    TrackerManager.shared.loginCallback(url)
                }
            }
        }
    }
}
