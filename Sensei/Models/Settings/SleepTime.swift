//
//  SleepTime.swift
//  Sensei
//
//  Created by Sauron Black on 6/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import CoreData
import RestClient

class SleepTime: NSManagedObject {
    
    static let EntityName = "SleepTime"
    
    static var timeFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    @NSManaged var start: NSDate
    @NSManaged var end: NSDate
    @NSManaged var settingsForWeekdays: Settings
    @NSManaged var settingsForWeekend: Settings
    
    class func sleepTimeWithStartTimeStrng(startTimeString: String, endTimeString: String) -> SleepTime {
        let sleepTime = CoreDataManager.sharedInstance.createObjectForEntityWithName(SleepTime.EntityName) as! SleepTime
        sleepTime.start = SleepTime.timeFormatter.dateFromString(startTimeString)!
        sleepTime.end = SleepTime.timeFormatter.dateFromString(endTimeString)!
        return sleepTime
    }
    
    class var objectMapping: RCObjectMapping {
        let mapping = RCObjectMapping(objectClass: SleepTime.self, mappingArray: ["start", "end"])
        mapping.setValueTransformerClass(SleepTimeValueTransformer.self, forProperty: "start")
        mapping.setValueTransformerClass(SleepTimeValueTransformer.self, forProperty: "end")
        return mapping
    }
}

class SleepTimeValueTransformer: NSObject, RCValueTransformerProtocol {
    
    static func objectValueFromJSONValue(jsonValue: String!) -> AnyObject! {
        return SleepTime.timeFormatter.dateFromString(jsonValue)
    }
    
    static func JSONValueFromObjectValue(objectValue: AnyObject!) -> String! {
        if let date = objectValue as? NSDate {
            return SleepTime.timeFormatter.stringFromDate(date)
        }
        return nil
    }
}
