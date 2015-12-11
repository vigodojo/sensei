
//
//  AppDelegate.swift
//  Sensei
//
//  Created by Sauron Black on 5/6/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

let ApplicationDidReceiveRemotePushNotification = "ApplicationDidReceiveRemotePushNotification"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var pushNotification: PushNotification?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        pushNotification = extractPushFromLaunchOptions(launchOptions)
        Fabric.with([Crashlytics()])
        TutorialManager.sharedInstance
        if !NSUserDefaults.standardUserDefaults().boolForKey("IsProVersion") {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "IsProVersion")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        return true
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        CoreDataManager.sharedInstance.saveContext()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        CoreDataManager.sharedInstance.saveContext()
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        var token = deviceToken.description.stringByReplacingOccurrencesOfString("<", withString: "", options: .CaseInsensitiveSearch, range: nil)
        token = token.stringByReplacingOccurrencesOfString(">", withString: "", options: .CaseInsensitiveSearch, range: nil)
        token = token.stringByReplacingOccurrencesOfString(" ", withString: "", options: .CaseInsensitiveSearch, range: nil)
        token = token.stringByReplacingOccurrencesOfString("_", withString: "", options: .CaseInsensitiveSearch, range: nil)
        if APIManager.sharedInstance.logined {
            APIManager.sharedInstance.sendDeviceToken(token)
        } else {
            APIManager.sharedInstance.deviceToken = token
        }
        print("Sensei Device Token: \(token)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("Push Info = \(userInfo)")
        NSNotificationCenter.defaultCenter().postNotificationName(ApplicationDidReceiveRemotePushNotification, object: nil, userInfo: userInfo)
    }
    
    // MARK: - Private
    
    private func extractPushFromLaunchOptions(launchOptions: [NSObject: AnyObject]?) -> PushNotification? {
        if let userInfo = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject: AnyObject]{
            return PushNotification(userInfo:userInfo)
        }
        return nil
    }
    
    // MARK: - Test Data
    
    func showAlertWithTitle(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }
}

