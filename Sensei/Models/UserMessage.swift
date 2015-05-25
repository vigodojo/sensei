//
//  UserMessage.swift
//  Sensei
//
//  Created by Sauron Black on 5/25/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import CoreData

enum ReceiveTime: String {
    
    case AnyTime = "ANY TIME"
    case Morning = "START OF DAY"
    case Evening = "END OF DAY"
    
    init(string: String) {
        switch string {
        case "START OF DAY": self = .Morning
        case "END OF DAY": self = .Evening
        default: self = .AnyTime
        }
    }
}

class UserMessage: NSManagedObject, Message {

    @NSManaged var number: NSNumber
    @NSManaged var text: String
    @NSManaged var savedOnServer: NSNumber
    @NSManaged private var receiveTimeString: String

    var receiveTime: ReceiveTime {
        get {
            return ReceiveTime(string: receiveTimeString)
        }
        set {
            receiveTimeString = newValue.rawValue
        }
    }
}
