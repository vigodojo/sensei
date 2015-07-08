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

enum ReceiveTime: String, Printable {
    
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

    @NSManaged dynamic var number: NSNumber
    @NSManaged dynamic var text: String
    @NSManaged dynamic var savedOnServer: NSNumber
    @NSManaged private  dynamic var receiveTimeString: String
    
    var id: String { return "\(number)"}
    var date = NSDate()

    var receiveTime: ReceiveTime {
        get {
            return ReceiveTime(string: receiveTimeString)
        }
        set {
            receiveTimeString = newValue.rawValue
        }
    }
    
    // MARK: Mapping
    
    class var objectMapping: RCObjectMapping {
        let mapping = RCObjectMapping(objectClass: UserMessage.self, mappingArray: ["text"])
        mapping.addPropertyMappingFromDictionary(["receiveTimeString": "timeToSend"])
        return mapping
    }
}
