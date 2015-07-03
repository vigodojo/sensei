//
//  PushNotification.swift
//  Sensei
//
//  Created by Sauron Black on 7/3/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

enum PushType: String {
    case Lesson = "L"
    case Affirmation = "A"
    case Visualisation = "V"
}

struct PushNotification: Printable {
    let id: String
    let date: NSDate?
    let type: PushType
    
    init?(userInfo: [NSObject: AnyObject]) {
        let idString = userInfo["id"] as? String
        let typeString = userInfo["type"] as? String
        if let id = idString, typeString = typeString, type = PushType(rawValue: typeString) {
            self.id = id
            self.type = type
            if let dateString = userInfo["date"] as? String {
                date = LessonDateTransformer().valueFromString(dateString) as? NSDate
            } else {
                date = nil
            }
        } else {
            return nil
        }
    }
    
    var description: String {
        return "id = \(id); date = \(date); timeInterval = \(date?.timeIntervalSince1970); type = \(type)"
    }
}