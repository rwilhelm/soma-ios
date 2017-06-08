//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import UserNotifications
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "288893270266"
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
        //        NotificationsController.configure()
        
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        if #available(iOS 10.0, *) {
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            application.registerForRemoteNotifications()
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        // [END register_for_notifications]
        
        printFCMToken()
        
        return true
    }
    
    
    func printFCMToken() {
        if let token = Messaging.messaging().fcmToken {
            print("FCM Token: \(token)")
        } else {
            print("FCM Token: nil")
        }
    }
    
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("AppDelegate didReceiveRemoteNotification")
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    
    // [START refresh_token]
    func tokenRefreshNotification(_ notification: Notification) {
        print("[AD] tokenRefreshNotification")
        
        
        // SEND NOTIFICATION FOR TESTTEST
        
        postTokenToAPI()
        
        Messaging.messaging().shouldEstablishDirectChannel = true
    }
    // [END refresh_token]
    
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("[AD] didReceiveRemoteNotification")
        Messaging.messaging().appDidReceiveMessage(userInfo) // Send to Firebase for analytics  etc.
        print("userInfo", userInfo)
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the InstanceID token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        Messaging.messaging().apnsToken = deviceToken
        postTokenToAPI()
    }
    // [END handle_received_apns_token]
    
    
    // [START connect_on_active]
    func applicationDidBecomeActive(_ application: UIApplication) {
        Messaging.messaging().shouldEstablishDirectChannel = true
    }
    // [END connect_on_active]
    
    // [START disconnect_from_fcm]
    func applicationDidEnterBackground(_ application: UIApplication) {
        Messaging.messaging().shouldEstablishDirectChannel = false
        print("Disconnected from FCM.")
    }
    // [END disconnect_from_fcm]
    
    
    // [START post_token_to_api]
    func postTokenToAPI() {
        
        guard let token = InstanceID.instanceID().token() else {
            print("NIL FCM TOKEN")
            return
        }

//        if let token = Messaging.messaging().fcmToken {
//            print("FCM Token: \(token)")
//        } else {
//            print("FCM Token: nil")
//        }

        let parameters: [String:Any] = [
            "token": token,
            "device_id": UIDevice.current.identifierForVendor!.uuidString
        ]
        
        debugPrint(parameters)
        
        Alamofire.request("https://soma.uni-koblenz.de/fcm/token",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default,
                          headers: nil
            ).responseString { response in
                if response.response?.statusCode == 200 {
                    print("TOKEN UPLOAD OK. RESPONSE: \(response)")
                } else {
                    print("TOKEN UPLOAD FAILED. RESPONSE: \(response)")
                }
        }
    }
    // [END post_token_to_api]
}


extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("didRefreshRegistrationToken")
        printFCMToken()
        postTokenToAPI()
    }
    
    // Direct channel data messages are delivered here, on iOS 10.0+.
    // The `shouldEstablishDirectChannel` property should be be set to |true| before data messages can
    // arrive.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        guard let data =
            try? JSONSerialization.data(withJSONObject: remoteMessage.appData, options: .prettyPrinted),
            let prettyPrinted = String(data: data, encoding: .utf8) else {
                print("[ERROR] Could not read notification data")
                return
        }
        
        let nc = NotificationCenter.default // Note that default is now a property, not a method call
        nc.addObserver(forName:Notification.Name(rawValue:"MyNotification"),
                       object:nil, queue:nil) {
                        notification in
                        // Handle notification
        }
        
        // http://wp.me/p4aNmq-PI
        
        nc.post(name:Notification.Name(rawValue:"MyNotification"),
        object: nil,
        userInfo: ["message":"Hello there!", "date":Date()])
        
        print("Received direct channel message:\n\(prettyPrinted)")
    }
}
