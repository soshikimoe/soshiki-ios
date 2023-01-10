//
//  TrackerView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/9/23.
//

import SwiftUI
import SafariServices

struct TrackerView: View {
    @EnvironmentObject var trackerManager: TrackerManager

    var tracker: Tracker

    @State var loginViewPresented = false

    @AppStorage var automaticallyTrack: Bool

    var authUrl: URL?

    init(tracker: Tracker) {
        self.tracker = tracker
        self._automaticallyTrack = AppStorage(wrappedValue: false, "settings.tracker.\(tracker.id).automaticallyTrack")
        self.authUrl = tracker.getAuthUrl()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    if let authUrl {
                        Button {
                            trackerManager.currentLoginInformation = (
                                tracker: tracker,
                                viewController: SFSafariViewController(url: authUrl)
                            )
                            loginViewPresented = true
                        } label: {
                            Text("Login")
                        }.sheet(isPresented: $loginViewPresented) {
                            WebView(url: authUrl, safariViewController: trackerManager.currentLoginInformation?.viewController)
                        }
                    }
                    Toggle("Automatically Track", isOn: $automaticallyTrack)
                }
            }.navigationTitle(tracker.name)
        }
    }
}
