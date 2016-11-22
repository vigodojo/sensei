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
    var shouldSit: Bool = false
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        pushNotification = extractPushFromLaunchOptions(launchOptions)
        Fabric.with([Crashlytics()])
        
        if TutorialManager.sharedInstance.completed {
           self.registerForNotifications()
        }
        
        if NSUserDefaults.standardUserDefaults().objectForKey("LastClearTime") == nil {
            NSUserDefaults.standardUserDefaults().setObject(NSDate().dateByAddingTimeInterval(-60*60*24), forKey: "LastClearTime")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        if !UpgradeManager.sharedInstance.isProVersion() {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "TutorialUpgradeCompleted")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        SenseiManager.sharedManager.standBow = true
        return true
    }
    
    func date(hours hours: Int, minutes: Int) -> NSDate {
        let components = NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.TimeZone], fromDate: NSDate())
        components.hour = hours
        components.minute = minutes
        return NSCalendar.currentCalendar().dateFromComponents(components)!
    }
    
    func startFromTutorialStep(stepNumber: Int32) {
        NSUserDefaults.standardUserDefaults().setObject(NSNumber(int: stepNumber), forKey: "TutorialManagerLastCompletedStepNumber")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func registerForNotifications() {
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    }

    func applicationDidEnterBackground(application: UIApplication) {
        SenseiManager.sharedManager.saveLastActiveTime()
        CoreDataManager.sharedInstance.saveContext()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        CoreDataManager.sharedInstance.saveContext()
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        
    }
    //4f0b0a986922738aa55e2a4c3376f43a29498c55463637e609efa3151b69a7dd
    //4f0b0a986922738aa55e2a4c3376f43a29498c55463637e609efa3151b69a7dd
    //4f0b0a986922738aa55e2a4c3376f43a29498c55463637e609efa3151b69a7dd
    
    func applicationWillEnterForeground(application: UIApplication) {
        if APIManager.sharedInstance.reachability.isReachable() && TutorialManager.sharedInstance.completed && !APIManager.sharedInstance.logined && !APIManager.sharedInstance.loggingIn {
            if let idfa = NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") as? String {
                let currentTimeZone = NSTimeZone.systemTimeZone().secondsFromGMT / 3600
                APIManager.sharedInstance.loginWithDeviceId(idfa, timeZone: currentTimeZone, handler: nil)
            }
        }
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        var token = deviceToken.description.stringByReplacingOccurrencesOfString("<", withString: "", options: .CaseInsensitiveSearch, range: nil)
        token = token.stringByReplacingOccurrencesOfString(">", withString: "", options: .CaseInsensitiveSearch, range: nil)
        token = token.stringByReplacingOccurrencesOfString(" ", withString: "", options: .CaseInsensitiveSearch, range: nil)
        token = token.stringByReplacingOccurrencesOfString("_", withString: "", options: .CaseInsensitiveSearch, range: nil)
        
        APIManager.sharedInstance.deviceToken = token

        if APIManager.sharedInstance.logined {
            APIManager.sharedInstance.sendDeviceToken(token)
        }
        print("Sensei Device Token: \(token)")
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("error: \(error.localizedDescription)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("Push Info = \(userInfo)")
        APIManager.sharedInstance.addToLog("didReceiveRemoteNotification APPDELEGATE")
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

