//
//  AppDelegate.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/22/23.
//

import UIKit
import UserNotifications
import Foundation
import AsyncDisplayKit
import GoogleCast

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        SourceManager.shared.startup()
        TrackerManager.shared.startup()

        GCKCastContext.setSharedInstanceWith(
            GCKCastOptions(
                discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID)
            )
        )
        GCKLogger.sharedInstance().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [ .alert, .badge ]) { _, _ in }
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()

        URLSession.shared.configuration.httpShouldSetCookies = false
        for cookie in URLSession.shared.configuration.httpCookieStorage?.cookies ?? [] {
            URLSession.shared.configuration.httpCookieStorage?.deleteCookie(cookie)
        }

        Task {
            let notifications = await UNUserNotificationCenter.current().deliveredNotifications()
            application.applicationIconBadgeNumber = notifications.reduce(0, { accum, item in
                accum + (item.request.content.userInfo["count"] as? Int ?? 0)
            })
        }

        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(token, forKey: "app.notification.id")
        Task {
            _ = await SoshikiAPI.shared.addNotificationDevice(id: token)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        guard let id = info["id"] as? String,
              let mediaType = (info["mediaType"] as? String).flatMap({ MediaType(rawValue: $0) }) else { return }
        Task {
            if let entry = try? await SoshikiAPI.shared.getEntry(mediaType: mediaType, id: id).get() {
                NotificationCenter.default.post(name: .init("app.openToEntry"), object: entry)
            }
        }
    }
}

extension AppDelegate: GCKLoggerDelegate {
    func logMessage(_ message: String, at level: GCKLoggerLevel, fromFunction function: String, location: String) {
        print(function + " - " + message)
    }
}
