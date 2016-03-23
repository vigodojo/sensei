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
    var attributedText: NSAttributedString? { get set }
}

class Lesson: NSManagedObject, Message {

    static let EntityName = "Lesson"
    
    @NSManaged var itemId: String
    @NSManaged var preText: String
    @NSManaged var text: String
    @NSManaged var date: NSDate
    @NSManaged var type: String
    
    var id: String { return itemId }
    var attributedText: NSAttributedString?
    
    override var description: String {
        return "id = \(id); text = \(text); date = \(date)"
    }
    
    private func typeEquals(receivedType: String) -> Bool {
        return type.lowercaseString == receivedType.lowercaseString
    }
    
    func isTypeLesson() -> Bool {
        return typeEquals("L")
    }

    func isTypeAffirmation() -> Bool {
        return typeEquals("A")
    }
    
    func isTypeVisualization() -> Bool {
        return typeEquals("V")
    }
    
    class var entityMapping: EntityMapping {
        let propertyMapping = ["itemId": "itemId", "text": "text", "date": "date", "preText": "preMessage", "type" : "msgType"]
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
