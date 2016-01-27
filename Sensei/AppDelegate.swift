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
        NSUserDefaults.standardUserDefaults().setObject(NSNumber(int: 20), forKey: "TutorialManagerLastCompletedStepNumber")
        NSUserDefaults.standardUserDefaults().synchronize()
        pushNotification = extractPushFromLaunchOptions(launchOptions)
        Fabric.with([Crashlytics()])
        TutorialManager.sharedInstance
        if Settings.sharedSettings.isProVersion?.boolValue == false {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "TutorialUpgradeCompleted")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        return true
    }
    
    func registerForNotifications() {
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    }
    
    func postSitSenseiNotification() {
        if TutorialManager.sharedInstance.completed {
            NSNotificationCenter.defaultCenter().postNotificationName("SitSenseiNotification", object: nil)
        }
    }
    
    func shouldSenseiSit() -> Bool {
        let sleepTime = NSCalendar.currentCalendar().isDateInWeekend(NSDate()) ? Settings.sharedSettings.sleepTimeWeekends : Settings.sharedSettings.sleepTimeWeekdays
        let lastActivity = NSUserDefaults.standardUserDefaults().objectForKey("LastActiveTime") == nil ? NSDate() : NSUserDefaults.standardUserDefaults().objectForKey("LastActiveTime") as! NSDate

        let activityComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.TimeZone], fromDate: lastActivity)
        let sleepEndComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.TimeZone], fromDate: sleepTime.end)
        
        let lastActivityDate = NSCalendar.currentCalendar().dateFromComponents(activityComponents)
        let sleeptimeEndDate = NSCalendar.currentCalendar().dateFromComponents(sleepEndComponents)

        let lastActivityBeforeSleep = lastActivityDate!.compare(sleeptimeEndDate!) == NSComparisonResult.OrderedAscending
        let nowAfterSleep = sleeptimeEndDate!.compare(NSDate()) == NSComparisonResult.OrderedAscending

        return lastActivityBeforeSleep && nowAfterSleep
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        shouldSit = shouldSenseiSit()
        if shouldSit {
            postSitSenseiNotification()
        }
        NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "LastActiveTime")
        NSUserDefaults.standardUserDefaults().synchronize()
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
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("error: \(error.localizedDescription)")
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

