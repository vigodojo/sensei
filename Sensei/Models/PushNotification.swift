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
    var preMessage: String = ""
    
    init?(userInfo: [NSObject: AnyObject]) {
        let idString = userInfo["id"] as? String
        let typeString = userInfo["type"] as? String
        let alertString = userInfo["aps"]!["alert"] as? String
        let preMessage = userInfo["preMessage"] as? String
        
        if let id = idString, typeString = typeString, type = PushType(rawValue: typeString), alert = alertString {
            self.id = id
            self.type = type
            self.alert = alert
            
            if let pre = preMessage {
                self.preMessage = pre
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
    
    static func pushExample(id: Int = 0, preMessage: String = "Test premessage:", message: String = "Test Message", type: PushType) -> PushNotification? {
        let preMessage = "\(type.rawValue) | \(preMessage)"
        let alert = "\(preMessage) \(message)"
        let type = type
        let id = id
        let str = "{\"id\": \"\(id)\", \"aps\": { \"alert\" : \"\(alert)\", \"sound\" : \"default\" }, \"preMessage\": \"\(preMessage)\", \"type\": \"\(type.rawValue)\", \"date\": \"2016-11-28T16:49:07.319Z\"}"
        let data = str.dataUsingEncoding(NSUTF8StringEncoding)
        let dict = try? NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
        
        if let userInfo = dict as? [NSObject: AnyObject] {
            return PushNotification(userInfo: userInfo)
        }
        return nil
    }

    var description: String {
        return "id = \(id); date = \(date); timeInterval = \(date?.timeIntervalSince1970); type = \(type); alert =\(alert)"
    }
}
