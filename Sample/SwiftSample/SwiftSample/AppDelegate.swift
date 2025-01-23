//
//  AppDelegate.swift
//  SwiftSample
//
//  Created by Pramit Tewari on 17/01/25.
//

import UIKit
import UserNotifications
import FreshchatSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
        if #available(iOS 10.0, *) {
            let center  = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
                if error == nil{
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        } else {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
        self.initFreshchatSDK()
        return true
    }

    func initFreshchatSDK() {
        let appID = "appid"
        let appKey = "appkey"
        let domain = "domain"

        let fchatConfig = FreshchatConfig.init(appID: appID, andAppKey: appKey) //Enter your AppID and AppKey here
        fchatConfig.domain = domain
//        fchatConfig.themeName = "CustomThemeFile"
        Freshchat.sharedInstance().initWith(fchatConfig)
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Freshchat.sharedInstance().setPushRegistrationToken(deviceToken)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if Freshchat.sharedInstance().isFreshchatNotification(notification.request.content.userInfo) {
            Freshchat.sharedInstance().handleRemoteNotification(notification.request.content.userInfo, andAppstate: UIApplication.shared.applicationState)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if Freshchat.sharedInstance().isFreshchatNotification(response.notification.request.content.userInfo) {
            Freshchat.sharedInstance().handleRemoteNotification(response.notification.request.content.userInfo, andAppstate: UIApplication.shared.applicationState)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Freshchat.sharedInstance().isFreshchatNotification(userInfo) {
            Freshchat.sharedInstance().handleRemoteNotification(userInfo, andAppstate: application.applicationState)
        }
        completionHandler(UIBackgroundFetchResult.noData)
    }

}

