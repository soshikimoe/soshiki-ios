//
//  AppDelegate.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/22/23.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        SourceManager.shared.startup()
        TrackerManager.shared.startup()

        UNUserNotificationCenter.current().requestAuthorization(options: [ .alert, .badge ]) { _, _ in }
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()

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
//        let info = response.notification.request.content.userInfo
//        guard let platform = info["platform"] as? String,
//              let source = info["source"] as? String,
//              let sourceId = info["sourceId"] as? String,
//              let id = info["id"] as? String,
//              let mediaType = (info["mediaType"] as? String).flatMap({ MediaType(rawValue: $0) }),
//              let sourceObject = SourceManager.shared.sources.first(where: { $0.id == source }) else { return }
//        print(await center.deliveredNotifications().map({ $0.request.content.title }))
        Task {
            _ = await SoshikiAPI.shared.setNotificationBadge(count: 0)
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}
