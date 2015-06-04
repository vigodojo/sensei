//
//  Lesson.swift
//  Sensei
//
//  Created by Sauron Black on 6/4/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import RestClient
import CoreData

class Lesson: NSManagedObject, Message {

    static let EntityName = "Lesson"
    
    @NSManaged var lessonId: String
    @NSManaged var text: String
    @NSManaged var date: NSDate

    class var entityMapping: EntityMapping {
        let propertyMapping = ["lessonId": "lessonId", "text": "text", "date": "date"]
        return EntityMapping(entityName: "Lesson", propertyMapping: propertyMapping, primaryProperty: "date", valueTransformers: ["date": LessonDateTransformer()])
    }
}

class LessonDateTransformer: JSONValueTransformerProtocol {
    
    static var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    
    func valueFromString(string: String) -> AnyObject? {
        return LessonDateTransformer.dateFormatter.dateFromString(string)
    }
    
    func stringFromValue(value: AnyObject) -> String? {
        if let date = value as? NSDate {
            return LessonDateTransformer.dateFormatter.stringFromDate(date)
        }
        return nil
    }
}
