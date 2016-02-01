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

class SenseiManager: NSObject {

    static var sharedManager = SenseiManager()
    
    var senseiSitting: Bool {
        get {
            return shouldSenseiSit()
        }
    }
    
    var showSenseiSitAnimation: Bool = false
    override init() {
        super.init()
        showSenseiSitAnimation = shouldShowSenseiAnimation()
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
    
    func postSitSenseiNotification() {
        if TutorialManager.sharedInstance.completed {
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.SitSenseiNotification, object: nil)
        }
    }
    
    private func shouldSenseiSit() -> Bool {
        return !TutorialManager.sharedInstance.completed && TutorialManager.sharedInstance.lastStepNumber() < 1 || showSenseiSitAnimation || isSleepTime()
    }

    private func isSleepTime() -> Bool {
        let sleepTime = NSCalendar.currentCalendar().isDateInWeekend(NSDate()) ? Settings.sharedSettings.sleepTimeWeekends : Settings.sharedSettings.sleepTimeWeekdays
        
        let sleepStart = sleepTime.start.dateLessDate()
        let sleepEnd = sleepTime.end.dateLessDate()
        let now = NSDate().dateLessDate()
        
        return now.dateBetweenDates(sleepStart, lastDate: sleepEnd)
    }
    
    private func shouldShowSenseiAnimation() -> Bool {
        let sleepTime = NSCalendar.currentCalendar().isDateInWeekend(NSDate()) ? Settings.sharedSettings.sleepTimeWeekends : Settings.sharedSettings.sleepTimeWeekdays
        let lastActivity = NSUserDefaults.standardUserDefaults().objectForKey("LastActiveTime") == nil ? NSDate() : NSUserDefaults.standardUserDefaults().objectForKey("LastActiveTime") as! NSDate
        
        let lastActivityDate = lastActivity.dateLessDate()
        let sleeptimeEndDate = sleepTime.end.dateLessDate()
        
        let lastActivityBeforeSleep = lastActivityDate.compare(sleeptimeEndDate) == NSComparisonResult.OrderedAscending
        let nowAfterSleep = sleeptimeEndDate.compare(NSDate()) == NSComparisonResult.OrderedAscending
        
        var timeIntervalSinceNow = lastActivity.timeIntervalSinceNow
        if timeIntervalSinceNow < 0 {
            timeIntervalSinceNow *= -1
        }

        let lastActivityMoreThenAnHourAgo = timeIntervalSinceNow > 60*60
        
        return lastActivityBeforeSleep && nowAfterSleep || lastActivityMoreThenAnHourAgo
    }
}
