//
//  UserMessage.swift
//  Sensei
//
//  Created by Sauron Black on 5/25/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import CoreData
import RestClient

enum ReceiveTime: String, CustomStringConvertible {
    
    case AnyTime = "any"
    case Morning = "morning"
    case Evening = "evening"
    
    init(string: String) {
        switch string {
            case "morning": self = .Morning
            case "evening": self = .Evening
            default: self = .AnyTime
        }
    }
    
    var description: String {
        switch self {
            case .AnyTime: return "ANY TIME"
            case .Morning: return "START OF DAY"
            case .Evening: return "END OF DAY"
        }
    }
}

class UserMessage: NSManagedObject, Message {

    @NSManaged var number: NSNumber
    @NSManaged var text: String
    @NSManaged var savedOnServer: NSNumber
    @NSManaged var updatedOffline: NSNumber
    @NSManaged private var receiveTimeString: String
    
    var id: String { return "\(number)"}
    var date = NSDate()
    var attributedText: NSAttributedString?
    var preMessage: String?
    
    var receiveTime: ReceiveTime {
        get {
            return ReceiveTime(string: receiveTimeString)
        }
        set {
            receiveTimeString = newValue.rawValue
        }
    }
    
    func fullMessage() -> String {
        if  let prefix = self.preMessage {
            if self is Affirmation {
                return "\(prefix) \(text)"
            }
            
            if self is Visualization {
                return prefix
            }
        }
        return text
    }
    
    // MARK: Mapping
    
    class var objectMapping: RCObjectMapping {
        let mapping = RCObjectMapping(objectClass: UserMessage.self, mappingArray: ["text"])
        mapping.addPropertyMappingFromDictionary(["receiveTimeString": "timeToSend"])
        return mapping
    }
}
