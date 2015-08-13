//
//  PlainMessage.swift
//  Sensei
//
//  Created by Sauron Black on 8/13/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

class PlainMessage: Message {
    
    var id: String { return "0" }
    var text = ""
    var date = NSDate()
    var attributedText: NSAttributedString?
    
    init(text: String) {
        self.text = text
    }
    
    init(attributedText: NSAttributedString) {
        self.attributedText = attributedText
    }
}