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
    case Height(Length)
    case Weight(Mass)
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
                case .Height(let length):
                    return "\(length)"
                case .Weight(let mass):
                    return "\(mass)"
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
            case .Height(let length):
                return "\(length.realValue)"
            case .Weight(let mass):
                return "\(mass.realValue)"
            case .Date(let date):
                return LessonDateTransformer().stringFromValue(date)!
        }
    }
    
    var date = NSDate()
    
    init(answer: Answer) {
        self.answer = answer
    }
}