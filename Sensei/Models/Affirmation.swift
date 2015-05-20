//
//  Affirmation.swift
//  Sensei
//
//  Created by Sauron Black on 5/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

enum ReceivingTime {
    case AnyTime
    case Morning
    case Evening
}

class Affirmation: Message {
    
    var text = ""
    var receivingTime = ReceivingTime.AnyTime
}