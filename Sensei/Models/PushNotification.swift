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

struct PushNotification: CustomStringConvertible {
    let id: String
    let date: NSDate?
    let type: PushType
    let alert: String
    
    init?(userInfo: [NSObject: AnyObject]) {
        let idString = userInfo["id"] as? String
        let typeString = userInfo["type"] as? String
        let alertString = userInfo["aps"]!["alert"] as? String
        
        if let id = idString, typeString = typeString, type = PushType(rawValue: typeString), alert = alertString {
            self.id = id
            self.type = type
            
            if type == .Affirmation || type == .Visualisation {
                self.alert = alert
            } else {
                self.alert = ""
            }

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
        return "id = \(id); date = \(date); timeInterval = \(date?.timeIntervalSince1970); type = \(type); alert =\(alert)"
    }
}