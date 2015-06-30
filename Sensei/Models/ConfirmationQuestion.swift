//
//  ConfirmationQuestion.swift
//  Sensei
//
//  Created by Sauron Black on 6/30/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

class ConfirmationQuestion: Message {
    
    var text = ""
    var date = NSDate()
    
    init(text: String) {
        self.text = text
    }
}