import UIKit
import UserNotifications
import Firebase
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "288893270266"
    
    let nc = NotificationCenter.default
    let surveyNotification = Notification.Name(rawValue:"SurveyNotification")
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
        //        NotificationsController.configure()
        
        nc.addObserver(forName:surveyNotification, object:nil, queue:nil, using:handleSurveyNotification)

        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        if #available(iOS 10.0, *) {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        // [END register_for_notifications]
        
        application.registerForRemoteNotifications()
        printFCMToken()
        return true
    }
    
    func handleSurveyNotification(notification:Notification) -> Void {
        print("[BACKGROUND NOTIFICATION]")
        
        guard let userInfo = notification.userInfo,
            let surveyUrl  = userInfo["surveyUrl"] as? URL else {
                print("No userInfo found in notification")
                return
        }
        goToSurvey(surveyUrl: surveyUrl)
    }

    func goToSurvey(surveyUrl: URL) {
        print("[GO TO URL]")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(surveyUrl as URL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(surveyUrl as URL)
        }
    }
    
    func printFCMToken() {
        if let token = Messaging.messaging().fcmToken {
            print("FCM Token: \(token)")
        } else {
            print("FCM Token: nil")
        }
    }
    
    func open(scheme: String) {
        if let url = URL(string: scheme) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:],
                                          completionHandler: {
                                            (success) in
                                            print("Open \(scheme): \(success)")
                })
            } else {
                let success = UIApplication.shared.openURL(url)
                print("Open \(scheme): \(success)")
            }
        }
    }
    
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("[NOTIFICATION] didReceiveRemoteNotification")
        
        // If you are receiving a notification message while your app is in the background,
        // this callback (-> surveyURL) will not be fired till the user taps on the notification
        // launching the application.
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
//        print(userInfo)
//        print(userInfo["surveyURL"])

//        if let aps = userInfo["aps"] as? NSDictionary {
//            if let alert = aps["alert"] as? NSDictionary {
//                if let message = alert["message"] as? NSString {
//                    print("BBB", message)
//                }
//            } else if let alert = aps["surveyURL"] as? NSString {
//                print("CCC", alert)
//            }
//        }

        
        if let surveyURL = userInfo["surveyURL"] as? String {
            open(scheme: surveyURL)
        }

//        if let data = userInfo["aps"] as? [String: AnyObject] {
//            
//            let notificationData = data["data"] as? [String: String]
//
//            if let urlString = notificationData?["surveyURL"] {
//                print("XXZ", urlString)
//                open(scheme: urlString)
//            } else {
//                print("[FIXME 000] Notification has no surveyUrl")
//                return
//            }
//
//            if let urlString = notificationData?["surveyURL"] {
//                open(scheme: urlString)
//            } else {
//                print("[FIXME 111] Notification has no surveyUrl")
//                return
//            }
//        } else {
//            print("[FIXME 222] Notification has no data")
//            return
//        }
       
//        if let info = userInfo as? Dictionary<String,String> {
//            if let surveyURL = info["surveyURL"] {
//                print("YYY", surveyURL)
//            }
//        }
        
        // http://wp.me/p3Om74-Bk
        if application.applicationState == .active {
            print("XXX APP IS FOREGROUND")
        } else {
            print("XXX APP IS OTHER STATE")
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    }
    
    
//    
//    
//    
//    
//    @available(iOS 10.0, *)
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        completionHandler(.alert)
//    }
//    
//    @available(iOS 10.0, *)
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        print(response)
//        //write your action here
//    }
//
//    
//    if launchOptions != nil{
//    let userInfo = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification]
//    if userInfo != nil {
//    // Perform action here
//    }
//    }
//    
//    
    
    
    // [START refresh_token]
    func tokenRefreshNotification(_ notification: Notification) {
        print("[AD] tokenRefreshNotification")
        
        
        // SEND NOTIFICATION FOR TESTTEST
        
        postTokenToAPI()
        
        Messaging.messaging().shouldEstablishDirectChannel = true
    }
    // [END refresh_token]
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[AD] didFailToRegisterForRemoteNotificationsWithError")
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    
    // [START handle_received_apns_token]
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("[AD] didRegisterForRemoteNotificationsWithDeviceToken")
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
        
        print("[RECEIVED MESSAGE] Received direct channel message:\n\(prettyPrinted)")
        
        // [START post_notification]

        nc.post(name:surveyNotification, object: nil, userInfo: remoteMessage.appData)

//        nc.post(name:surveyNotification,
//                object: nil,
//                userInfo:["message":"Hello there!", "date":Date()])
        // [END post_notification]

//        
//        // Handle Notification
//        let nc = NotificationCenter.default // Note that default is now a property, not a method call
//        nc.addObserver(forName:Notification.Name(rawValue:"Link zur Umfrage"),
//                       object:nil, queue:nil) {
//                        notification in
//                        // Handle notification
//        }
//        
        // http://wp.me/p4aNmq-PI
        

        
        
//        if #available(iOS 10.0, *) {
//            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//            UNUserNotificationCenter.current().requestAuthorization(
//                options: authOptions,
//                completionHandler: {_, _ in })            
//        } else {
//            let settings: UIUserNotificationSettings =
//                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
//        }

    }

}
