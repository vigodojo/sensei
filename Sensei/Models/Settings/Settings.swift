//
//  Settings.swift
//  Sensei
//
//  Created by Sauron Black on 6/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import CoreData
import RestClient

enum Gender: String, CustomStringConvertible {
    case Male = "male"
    case Female = "female"
    case SheMale = ""
    
    var description: String {
        return self.rawValue
    }
    
    var personalTitle: String {
        switch self {
            case .Male: return "Sir"
            case .Female: return "Ms"
            case .SheMale: return ""
        }
    }
}

class Settings: NSManagedObject {
    
    struct Constants {
        static let DefaultStartSleepTime = "23:00"
        static let DefaultEndSleepTime = "08:00"
        static let MaxNumberOfLessons = 6
    }
    
    private static let EntityName = "Settings"
    private static let SortDescriptor = NSSortDescriptor(key: "numberOfLessons", ascending: true)

    @NSManaged private var dataFormatString: String
    @NSManaged private var genderString: String
    @NSManaged var name: String
    @NSManaged var numberOfLessons: NSNumber
    @NSManaged var tutorialOn: NSNumber
    @NSManaged var height: NSNumber?
    @NSManaged var weight: NSNumber?
    @NSManaged var isProVersion: NSNumber?
    @NSManaged var dayOfBirth: NSDate?
    @NSManaged var sleepTimeWeekdays: SleepTime
    @NSManaged var sleepTimeWeekends: SleepTime
    
    var dataFormat: DataFormat {
        get {
           return DataFormat(rawValue: dataFormatString) ?? DataFormat.US
        }
        set {
            dataFormatString = newValue.rawValue
        }
    }
    
    var gender: Gender {
        get {
            return Gender(rawValue: genderString) ?? Gender.SheMale
        }
        set {
            genderString = newValue.rawValue
        }
    }

    private static var settingsStorage: Settings?
    
    class var sharedSettings: Settings {
        if let settings = settingsStorage {
            return settings
        } else {
            let objects = CoreDataManager.sharedInstance.fetchObjectsWithEntityName(Settings.EntityName, sortDescriptors: [Settings.SortDescriptor])
            if let fetchedSettings = objects?.first as? Settings {
                settingsStorage = fetchedSettings
                return fetchedSettings
            } else {
                settingsStorage = Settings.createDeafultSettings()
                return settingsStorage!
            }
        }
    }
    
    // MARK: Mapping
    
    private static let propertyMapping = ["isProVersion":"isUpgraded", "dayOfBirth": "birthDate", "numberOfLessons": "countLesson", "genderString": "gender", "height": "height", "weight": "weight"]
    
    private static let entityPropertyMapping = propertyMapping + ["sleepTimeWeekdays.start": "sleepTime.start", "sleepTimeWeekdays.end": "sleepTime.end", "sleepTimeWeekends.start": "sleepTimeWeekEnd.start", "sleepTimeWeekends.end": "sleepTimeWeekEnd.end"]

    private static let transformers: [String: JSONValueTransformerProtocol] = ["dayOfBirth": LessonDateTransformer(), "sleepTimeWeekdays.start": SleepTimeEntityTransformer(), "sleepTimeWeekdays.end": SleepTimeEntityTransformer(), "sleepTimeWeekends.start": SleepTimeEntityTransformer(), "sleepTimeWeekends.end": SleepTimeEntityTransformer()]
    
    class var entityMapping: EntityMapping {
        return EntityMapping(entityName: Settings.EntityName, propertyMapping: entityPropertyMapping, primaryProperty: "numberOfLessons", valueTransformers: transformers)
    }
    
    class func updateWithJSON(json: JSONObject) {
        CoreDataManager.sharedInstance.updateEntityObject(Settings.sharedSettings, withJSON: json, entityMapping: entityMapping)
    }
    
    class var objectMapping: RCObjectMapping {
        let requestPropertyMapping = propertyMapping + ["name": "name"]
        let mapping = RCObjectMapping(objectClass: Settings.self, mappingDictionary: requestPropertyMapping)
        mapping.addRelationshipMapping(RCRelationshipMapping(fromKeyPath: "sleepTime", toKeyPath: "sleepTimeWeekdays", objectMapping: SleepTime.objectMapping))
        mapping.addRelationshipMapping(RCRelationshipMapping(fromKeyPath: "sleepTimeWeekEnd", toKeyPath: "sleepTimeWeekends", objectMapping: SleepTime.objectMapping))
        return mapping
    }
    
    class var requestDescriptor: RCRequestDescriptor {
        return RCRequestDescriptor(objectMapping: Settings.objectMapping.inversMapping(), pathPattern: APIManager.APIPath.Settings)
    }
    
    // MARK: Private
    
    private class func createDeafultSettings() -> Settings {
        let settings = CoreDataManager.sharedInstance.createObjectForEntityWithName(Settings.EntityName) as! Settings
        settings.name = ""
        settings.isProVersion = NSNumber(bool: false)
        settings.dataFormat = Settings.defaultDataFormat
        settings.sleepTimeWeekdays = SleepTime.sleepTimeWithStartTimeStrng(Constants.DefaultStartSleepTime, endTimeString: Constants.DefaultEndSleepTime)
        settings.sleepTimeWeekends = SleepTime.sleepTimeWithStartTimeStrng(Constants.DefaultStartSleepTime, endTimeString: Constants.DefaultEndSleepTime)
        return settings
    }
    
    private class var defaultDataFormat: DataFormat {
        if let isMetric = NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem) as? NSNumber where isMetric.boolValue {
            return DataFormat.Metric
        }
        return DataFormat.US
    }
}

class SleepTimeEntityTransformer: JSONValueTransformerProtocol {
    
    func valueFromString(string: String) -> AnyObject? {
        return SleepTime.timeFormatter.dateFromString(string)
    }
    
    func stringFromValue(value: AnyObject) -> String? {
        if let date = value as? NSDate {
            return SleepTime.timeFormatter.stringFromDate(date)
        }
        return nil
    }
}
