//
//  Answer.swift
//  Sensei
//
//  Created by Sauron Black on 5/20/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

enum Answer {
    case Text(String)
    case Date(NSDate)
}

class AnswerMessage: Message, Printable {
    
    private lazy var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        return dateFormatter
    }()
    
    var answer = Answer.Text("")
    
    var text: String {
        get {
            switch answer {
                case .Text(let string):
                    return string
                case .Date(let date):
                    return dateFormatter.stringFromDate(date)
            }
        }
        set {}
    }
    
    var description: String {
        switch answer {
            case .Text(let string):
                return string
            case .Date(let date):
                return LessonDateTransformer().stringFromValue(date)!
        }
    }
    
    var date = NSDate()
    
    init(answer: Answer) {
        self.answer = answer
    }
}