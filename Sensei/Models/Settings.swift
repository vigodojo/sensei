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

enum DataFormat: String {
    case US = "US"
    case Metric = "METRIC"
}

enum Gender: String, Printable {
    case Male = "M"
    case Female = "F"
    
    var description: String {
        switch self {
            case .Male:
                return "MALE"
            case .Female:
                return "FEMALE"
        }
    }
}

class Settings: NSManagedObject {
    
    struct Constants {
        static let DefaultStartSleepTime = "10:00"
        static let DefaultEndSleepTime = "06:00"
        static let MaxNumberOfLessons = 6
    }
    
    private static let EntityName = "Settings"
    private static let SortDescriptor = NSSortDescriptor(key: "numberOfLessons", ascending: true)

    @NSManaged private var dataFormatString: String
    @NSManaged private var genderString: String
    @NSManaged var numberOfLessons: NSNumber
    @NSManaged var tutorialOn: NSNumber
    @NSManaged var height: NSNumber?
    @NSManaged var weight: NSNumber?
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
            return Gender(rawValue: genderString) ?? Gender.Male
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
    
    private static let propertyMapping = ["dayOfBirth": "birthDate", "numberOfLessons": "countLesson", "genderString": "gender", "height": "height", "weight": "weight",
        "sleepTimeWeekdays.start": "sleepTime.start", "sleepTimeWeekdays.end": "sleepTime.end", "sleepTimeWeekends.start": "sleepTimeWeekEnd.start", "sleepTimeWeekends.end": "sleepTimeWeekEnd.end"]
    
    private static let transformers: [String: JSONValueTransformerProtocol] = ["dayOfBirth": LessonDateTransformer(), "sleepTimeWeekdays.start": SleepTimeEntityTransformer(), "sleepTimeWeekdays.end": SleepTimeEntityTransformer(), "sleepTimeWeekends.start": SleepTimeEntityTransformer(), "sleepTimeWeekends.end": SleepTimeEntityTransformer()]
    
    class var entityMapping: EntityMapping {
        return EntityMapping(entityName: Settings.EntityName, propertyMapping: Settings.propertyMapping, primaryProperty: "numberOfLessons", valueTransformers: transformers)
    }
    
    class func updateWithJSON(json: JSONObject) {
        if CoreDataManager.sharedInstance.updateEntityObject(Settings.sharedSettings, withJSON: json, entityMapping: Settings.entityMapping) {
            CoreDataManager.sharedInstance.saveContext()
        }
    }
    
    class var objectMapping: RCObjectMapping {
        let mapping = RCObjectMapping(objectClass: Settings.self, mappingDictionary: Settings.propertyMapping)
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
        settings.sleepTimeWeekdays = SleepTime.sleepTimeWithStartTimeStrng(Constants.DefaultStartSleepTime, endTimeString: Constants.DefaultEndSleepTime)
        settings.sleepTimeWeekends = SleepTime.sleepTimeWithStartTimeStrng(Constants.DefaultStartSleepTime, endTimeString: Constants.DefaultEndSleepTime)
        CoreDataManager.sharedInstance.saveContext()
        return settings
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
