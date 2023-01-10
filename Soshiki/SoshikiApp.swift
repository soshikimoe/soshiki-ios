//
//  SoshikiApp.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/14/22.
//

import SwiftUI

@main
struct SoshikiApp: App {
    init() {
        SourceManager.shared.startup()
        TrackerManager.shared.startup()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    if url.pathExtension == "soshikisource" {
                        Task {
                            await SourceManager.shared.installSource(url)
                        }
                    }
                    if url.pathExtension == "soshikitracker" {
                        Task {
                            await TrackerManager.shared.installTracker(url)
                        }
                    }
                    if url.pathExtension == "soshikisources" {
                        SourceManager.shared.installSources(url)
                    }
                    if url.scheme == "soshiki" {
                        if url.host == "login" {
                            SoshikiAPI.shared.loginCallback(url)
                        } else if url.host == "tracker" {
                            TrackerManager.shared.loginCallback(url)
                        }
                    }
                }
        }
    }
}
