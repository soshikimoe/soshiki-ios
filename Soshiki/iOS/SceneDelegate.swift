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
        window.tintColor = UserDefaults.standard.string(forKey: "app.settings.accentColor").flatMap({
            UIColor.from(rawValue: $0)
        }) ?? UIColor.tintColor
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
            } else if url.pathExtension == "soshikibackup" {
                let alert = UIAlertController(
                    title: "Import Backup",
                    message: "Importing this backup will overwrite your current data. Would you like to proceed?",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Import", style: .destructive) { _ in
                    DataManager.shared.importBackup(url)
                })
                UIApplication.shared.connectedScenes.compactMap({
                    $0 as? UIWindowScene
                }).first?.keyWindow?.rootViewController?.present(alert, animated: true)
            } else if url.pathExtension == "epub" {
                // TODO: add
            } else if url.scheme == "soshiki" {
                if url.host == "login" {
                    SoshikiAPI.shared.loginCallback(url)
                } else if url.host == "tracker" {
                    TrackerManager.shared.loginCallback(url)
                } else if url.host == "addSources" {
                    guard let url = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: {
                        $0.name == "url"
                    })?.value?.removingPercentEncoding.flatMap({ URL(string: $0) }) else { return }
                    Task {
                        await SourceManager.shared.installSources(url)
                    }
                } else if url.host == "addSource" {
                    guard let url = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: {
                        $0.name == "url"
                    })?.value?.removingPercentEncoding.flatMap({ URL(string: $0) }) else { return }
                    Task {
                        await SourceManager.shared.installSource(url)
                    }
                } else if url.host == "addTrackers" {
                    guard let url = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: {
                        $0.name == "url"
                    })?.value?.removingPercentEncoding.flatMap({ URL(string: $0) }) else { return }
                    Task {
                        await TrackerManager.shared.installTrackers(url)
                    }
                } else if url.host == "addTracker" {
                    guard let url = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: {
                        $0.name == "url"
                    })?.value?.removingPercentEncoding.flatMap({ URL(string: $0) }) else { return }
                    Task {
                        await TrackerManager.shared.installTracker(url)
                    }
                }
            }
        }
    }
}
