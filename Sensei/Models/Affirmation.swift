//
//  Affirmation.swift
//  Sensei
//
//  Created by Sauron Black on 5/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

enum ReceiveTime: Printable {
    
    case AnyTime
    case Morning
    case Evening
    
    var description: String {
        switch self {
            case .AnyTime: return "ANY TIME"
            case .Morning: return "START OF DAY"
            case .Evening: return "END OF DAY"
        }
    }
}

class Affirmation: Message {
    
    var text = ""
    var receiveTime = ReceiveTime.AnyTime
}