//
//  SenseiManager.swift
//  Sensei
//
//  Created by Sergey Sheba on 1/28/16.
//  Copyright © 2016 ThinkMobiles. All rights reserved.
//

import UIKit

struct Notifications {
    static let SitSenseiNotification = "SitSenseiNotification"
}

class SenseiManager {

    static var sharedManager = SenseiManager()
    
    var senseiSitting: Bool {
        get {
            return shouldSenseiSit()
        }
    }
    
    var standBow: Bool = true
    
    var showSenseiStandAnimation: Bool = false
    var shouldSitBowAfterOpening: Bool = false
    init() {
        shouldSitBowAfterOpening = shouldBowAfterLastActivity()
        showSenseiStandAnimation = isFirstTimeAfterSleep()
    }
    
    func sittingImage() -> UIImage? {
        return UIImage(named: "1_bow_0064")
    }
    
    func standingImage() -> UIImage? {
        return UIImage(named: "3_standbow_0064")
    }
    
    func animateSenseiSittingInImageView(imageView: AnimatableImageView, completion: ((finished: Bool) -> Void)?) {
        animateSensei(AnimationManager.sharedManager.sitStandAnimatableImage()!, imageView: imageView) { (finished) -> Void in
            completion?(finished: finished)
        }
    }
    
    func animateSenseiBowsInImageView(imageView: AnimatableImageView, completion: ((finished: Bool) -> Void)?) {
        animateSensei(AnimationManager.sharedManager.sitsBowAnimatableImage()!, imageView: imageView) { (finished) -> Void in
            completion?(finished: finished)
        }
    }
    
    func animateSenseiStandsBowsInImageView(imageView: AnimatableImageView, completion: ((finished: Bool) -> Void)?) {
        animateSensei(AnimationManager.sharedManager.bowsAnimatableImage()!, imageView: imageView) { (finished) -> Void in
            completion?(finished: finished)
        }
    }
    
    func animateSensei(animatableImage: AnimatableImage, imageView: AnimatableImageView, completion: ((finished: Bool) -> Void)?) {
        imageView.animateAnimatableImage(animatableImage, completion: { (finished) -> Void in
            completion?(finished: finished)
        })
    }
    
    func saveLastActiveTime() {
        NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "LastActiveTime")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func shouldShowSenseiScreen() -> Bool {
        let date = SenseiManager.sharedManager.lastActivityTime()
        return abs(date.timeIntervalSinceNow) >= 10*60
    }
    
    func lastActivityTime() -> NSDate {
        if let lastActivity = NSUserDefaults.standardUserDefaults().objectForKey("LastActiveTime") as? NSDate {
            return lastActivity
        } else {
            saveLastActiveTime()
            return lastActivityTime()
        }
    }
    
    func postSitSenseiNotification() {
        if TutorialManager.sharedInstance.completed {
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.SitSenseiNotification, object: nil)
        }
    }
    
    func shouldSenseiSit() -> Bool {
        //print("isBeginOfTutorial:\(isBeginOfTutorial())")
        //print("showSenseiStandAnimation:\(showSenseiStandAnimation)")
        //print("isSleepTime:\(isSleepTime())")
        //print("shouldSitBowAfterOpening:\(shouldSitBowAfterOpening)")
        return isBeginOfTutorial() || showSenseiStandAnimation || isSleepTime() || shouldSitBowAfterOpening
    }

    func isSleepTime() -> Bool {
        let sleepTime = NSCalendar.currentCalendar().isDateInWeekend(NSDate()) ? Settings.sharedSettings.sleepTimeWeekends : Settings.sharedSettings.sleepTimeWeekdays
        let now = NSDate()
        
        let startComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.TimeZone], fromDate: sleepTime.start)
        let sleepStartAfterNow = NSCalendar.currentCalendar().nextDateAfterDate(now, matchingComponents: startComponents, options: .MatchNextTime)!
        let sleepStartBeforeNow = sleepStartAfterNow.dateByAddingTimeInterval((60*60*24)*(-1))
        
        let endComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.TimeZone], fromDate: sleepTime.end)
        let sleepEnd = NSCalendar.currentCalendar().nextDateAfterDate(sleepStartBeforeNow, matchingComponents: endComponents, options: .MatchNextTime)!

        let isStartBeforeNow = now.compare(sleepStartBeforeNow) == NSComparisonResult.OrderedDescending
        let isEndAfterNow = now.compare(sleepEnd) == NSComparisonResult.OrderedAscending
        
//        //print("******* isSleepTime *******")
//        //print("start: \(sleepStartBeforeNow)\nnow: \(now)\nend: \(sleepEnd)")
//        //print("isSleepTime: \(isStartBeforeNow && isEndAfterNow ? "true" : "false")")
//        //print("**************")
        
        return isStartBeforeNow && isEndAfterNow
    }
    
    private func isBeginOfTutorial() -> Bool {
        return !TutorialManager.sharedInstance.completed && TutorialManager.sharedInstance.lastStepNumber() < 3
    }
    
    func isFirstTimeAfterSleep() -> Bool {
        let sleepTime = NSCalendar.currentCalendar().isDateInWeekend(NSDate()) ? Settings.sharedSettings.sleepTimeWeekends : Settings.sharedSettings.sleepTimeWeekdays
        let lastActivity = lastActivityTime()

        let startComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.TimeZone], fromDate: sleepTime.start)
        let sleepStartAfterActivity = NSCalendar.currentCalendar().nextDateAfterDate(lastActivity, matchingComponents: startComponents, options: .MatchNextTime)!
        
        let sleepStartBeforeActivity = sleepStartAfterActivity.dateByAddingTimeInterval((60*60*24)*(-1))
        
        let endComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.TimeZone], fromDate: sleepTime.end)
        let sleepEndAfterActivity = NSCalendar.currentCalendar().nextDateAfterDate(sleepStartBeforeActivity, matchingComponents: endComponents, options: .MatchNextTime)!
        
        let lastActivityBeforeSleepEnd = lastActivity.compare(sleepEndAfterActivity) == NSComparisonResult.OrderedAscending
        let now = NSDate()
        let nowAfterSleep = now.compare(sleepEndAfterActivity) == NSComparisonResult.OrderedDescending
        
//        //print("******* isFirstTimeAfterSleep *******")
//        //print("lastActivity: \(lastActivity)\nend: \(sleepEndAfterActivity)\nnow: \(now)")
//        //print("isFirstTimeAfterSleep: \(lastActivityBeforeSleepEnd && nowAfterSleep)")
//        //print("**************")
        
        return lastActivityBeforeSleepEnd && nowAfterSleep
    }
    
    func shouldBowAfterLastActivity() -> Bool {
        if !TutorialManager.sharedInstance.completed {
            return false
        }
        let lastActivity = NSUserDefaults.standardUserDefaults().objectForKey("LastActiveTime") == nil ? NSDate() : NSUserDefaults.standardUserDefaults().objectForKey("LastActiveTime") as! NSDate

        var timeIntervalSinceNow = lastActivity.timeIntervalSinceNow
        if timeIntervalSinceNow < 0 {
            timeIntervalSinceNow *= -1
        }
        
//        //print("******* shouldBowAfterLastActivity *******")
//        //print("shouldBowAfterLastActivity: \(timeIntervalSinceNow > 60*60)")
//        //print("**************")
        
        return timeIntervalSinceNow > 60*60
    }
}