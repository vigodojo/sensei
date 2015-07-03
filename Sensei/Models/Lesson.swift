//
//  Lesson.swift
//  Sensei
//
//  Created by Sauron Black on 6/4/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import CoreData

protocol Message {
    
    var id: String { get }
    var text: String { get set }
    var date: NSDate { get set }
}

class Lesson: NSManagedObject, Message {

    static let EntityName = "Lesson"
    
    @NSManaged var lessonId: String
    @NSManaged var text: String
    @NSManaged var date: NSDate
    var id: String { return lessonId }

    override var description: String {
        return "id = \(id); text = \(text); date = \(date)"
    }
    
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
