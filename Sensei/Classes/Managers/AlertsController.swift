//
//  AlertsController.swift
//  Sensei
//
//  Created by Sergey Sheba on 2/17/16.
//  Copyright © 2016 ThinkMobiles. All rights reserved.
//

import UIKit

class AlertsController {

    //MARK: Public Static

    static let sharedController = AlertsController()
    
    static func rateUsAlertController() -> UIAlertController {
        let alertController = UIAlertController(title: "Rate VIGO Sensei", message: "\(Settings.sharedSettings.name), Do you like your Sensei? If so, we would be grateful if you'd write a good review of the app. If not, please send us a note to let us know how we can make this a five star app for you", preferredStyle: .Alert)
        
        alertController.addAction(UIAlertAction(title: "Rate now", style: .Destructive, handler: { (action) -> Void in
            UpgradeManager.sharedInstance.openAppStoreURL()
        }))
        alertController.addAction(UIAlertAction(title: "No thanks", style: .Cancel, handler: nil))
        AlertsController.sharedController.setRateUsAlertDisplayed()
        return alertController
    }
    
    static func shareMessageAlertController() -> UIAlertController {
        let alertController = UIAlertController(title: "Share", message: "\(Settings.sharedSettings.name), please help us spread the word about ViGO Sensei. We want to help as many people as possible", preferredStyle: .Alert)
        let controller = ((UIApplication.sharedApplication().delegate as! AppDelegate).window?.rootViewController)!
        alertController.addAction(UIAlertAction(title: "Share via Facebook", style: .Default, handler: { (action) -> Void in
            SocialPostingService.postToSocialNetworksWithType(.Facebook, fromController: controller) { (composeResult) -> Void in
                
            }
        }))
        alertController.addAction(UIAlertAction(title: "Share via Twitter", style: .Default, handler: { (action) -> Void in
            SocialPostingService.postToSocialNetworksWithType(.Twitter, fromController: controller) { (composeResult) -> Void in
                
            }
        }))
        alertController.addAction(UIAlertAction(title: "No thanks", style: .Cancel, handler: nil))
        AlertsController.sharedController.setShareAlertDisplayed()
        return alertController
    }
    
    static func upgradeAlertController() -> UIAlertController {
        let alertController = UIAlertController(title: "Upgrade", message: "\(Settings.sharedSettings.name), as your sensei I recommend you upgrade this app, to fully benefit from the effects of its design", preferredStyle: .Alert)
        
        alertController.addAction(UIAlertAction(title: "Upgrade now", style: .Destructive, handler: { (action) -> Void in
            UpgradeManager.sharedInstance.openAppStoreURL()
        }))
        alertController.addAction(UIAlertAction(title: "No thanks", style: .Cancel, handler: nil))
        AlertsController.sharedController.setLastUpgradeAlertTime()
        AlertsController.sharedController.incrementUpgradeAlertTimes()
        return alertController
    }
    
    static func cameraSettingsAlertController() -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: "Please go to Settings and allow Vigo Sensei app to use your device's camera. Or select an image from your gallery.", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            if let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(settingsURL)
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        return alertController
    }
    
    //MARK: Public
    
    func shouldShowRateUsAlert() -> Bool {
        if !TutorialManager.sharedInstance.completed {
            return false
        }
        if rateUsAlertPreviouslyDisplayed() || AlertsController.sharedController.fullDaysAfterInstalation() < 7 {
            return false
        }
        return true
    }
    
    func shouldShowShareAlert() -> Bool {
        if !TutorialManager.sharedInstance.completed {
            return false
        }
        if shareAlertPreviouslyDisplayed() || AlertsController.sharedController.fullDaysAfterInstalation() < 14 {
            return false
        }
        return true
    }
    
    func shouldShowUpgradeAlert() -> Bool {
        if !TutorialManager.sharedInstance.completed {
            return false
        }
        if UpgradeManager.sharedInstance.isProVersion() || AlertsController.sharedController.fullDaysAfterInstalation() < 9 || numberOfUpgradeAlertDisplayed() > 1 {
            return false
        }
        if let lastUpgradeAlertTime = lastUpgradeAlertTime() where lastUpgradeAlertTime.fullDaysSinceNow() < 9 {
            return false
        }
        return true
    }
    
    //MARK: Private
    //MARK: NSUserDefaults

    private func fullDaysAfterInstalation() -> Int {
        let firstInstallTime = (NSUserDefaults.standardUserDefaults().objectForKey("AppInstalationDateTime") as! NSDate)//.timeless()
        return firstInstallTime.fullDaysSinceNow()
    }
    
    private func setRateUsAlertDisplayed() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "RateUsAlertPreviouslyDisplayed")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func rateUsAlertPreviouslyDisplayed() -> Bool {
        let rateUsAlertPreviouslyDisplayed = NSUserDefaults.standardUserDefaults().boolForKey("RateUsAlertPreviouslyDisplayed")
        return rateUsAlertPreviouslyDisplayed.boolValue
    }
    
    func setShareAlertDisplayed() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "ShareAlertPreviouslyDisplayed")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func shareAlertPreviouslyDisplayed() -> Bool {
        let shareAlertPreviouslyDisplayedValue = NSUserDefaults.standardUserDefaults().boolForKey("ShareAlertPreviouslyDisplayed")
        return shareAlertPreviouslyDisplayedValue
    }
    
    private func incrementUpgradeAlertTimes() {
        var times: Int = 1;
        if let upgradeAlertTimes = NSUserDefaults.standardUserDefaults().objectForKey("UpgradeAlertTimes") as? NSNumber {
            times = upgradeAlertTimes.integerValue + 1
        }
        NSUserDefaults.standardUserDefaults().setObject(NSNumber(integer: times), forKey: "UpgradeAlertTimes")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func numberOfUpgradeAlertDisplayed() -> Int {
        var times: Int = 0;
        if let upgradeAlertTimes = NSUserDefaults.standardUserDefaults().objectForKey("UpgradeAlertTimes") as? NSNumber {
            times = upgradeAlertTimes.integerValue
        }
        return times
    }
    
    private func setLastUpgradeAlertTime() {
        NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "LastUpgradeAlertTime")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func lastUpgradeAlertTime() -> NSDate? {
        if let lastUpgradeAlertTime = NSUserDefaults.standardUserDefaults().objectForKey("LastUpgradeAlertTime") as? NSDate {
            return lastUpgradeAlertTime
        }
        return nil
    }
}
