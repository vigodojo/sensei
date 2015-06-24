//
//  Question.swift
//  Sensei
//
//  Created by Sauron Black on 5/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import RestClient

enum QuestionType: String {
    
    case Text = "TEXT"
    case Number = "NUMBER"
    case Date = "DATE"
    case Choice = "RADIO"
    case Length = "LENGTH"
    case Mass = "MASS"
}

class Question: NSObject, Message {
    
    var id: String?
    var questionText: String?
    var potentialAnswers: [AnyObject]?
    var questionTypeRawValue: String?
    var date = NSDate()
    
    var text: String {
        get {
            return questionText ?? ""
        }
        set {
            questionText = newValue
        }
    }
    
    var questionType: QuestionType {
        if let rawValue = questionTypeRawValue {
            return QuestionType(rawValue: rawValue) ?? QuestionType.Text
        }
        return QuestionType.Text
    }
    
    var answers: [String] {
        return (potentialAnswers as? [String]) ?? [String]()
    }

    
    class var objectMapping: RCObjectMapping {
        let mapping = RCObjectMapping(objectClass: Question.self, mappingArray: ["text", "potentialAnswers"])
        mapping.addPropertyMappingFromDictionary(["id": "_id", "questionTypeRawValue": "type"])
        return mapping
    }
    
    class var responseDescriptor: RCResponseDescriptor {
        return RCResponseDescriptor(objectMapping: Question.objectMapping, pathPattern: APIManager.APIPath.NextQuestion)
    }
}

