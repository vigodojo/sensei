//
//  Message.swift
//  Sensei
//
//  Created by Sauron Black on 5/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

protocol Message {
    
    var text: String { get set }
}

class Lesson: Message {
    
    var id = ""
    var text = ""
    init(id: String, text: String) {
        self.id = id
        self.text = text
    }
    
    convenience init(text: String) {
        self.init(id: "", text: text)
    }
}