//
//  Question.swift
//  Sensei
//
//  Created by Sauron Black on 5/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

enum AnswerType {
    case Text
    case Date
    case Choice(options: [String])
}

class Question: Message {
    
    var answerType = AnswerType.Text
    var required = false
}