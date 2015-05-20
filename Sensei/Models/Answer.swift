//
//  Answer.swift
//  Sensei
//
//  Created by Sauron Black on 5/20/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

class Answer: Message {
    
    var text = ""
    init(answer: String) {
        text = answer
    }
}