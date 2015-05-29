//
//  Question.swift
//  Sensei
//
//  Created by Sauron Black on 5/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import RestClient

enum AnswerType: String {
    
    case Text = "TEXT"
    case Number = "NUMBER"
    case Date = "DATE"
    case Choice = "RADIO"
}

class Question: NSObject, Message {
    
    var id: String?
    var questionText: String?
    var potentialAnswers: [AnyObject]?
    var answerTypeRawValue: String?
    
    var text: String {
        get {
            return questionText ?? ""
        }
        set {
            questionText = newValue
        }
    }
    
    var answerType: AnswerType {
        if let rawValue = answerTypeRawValue {
            return AnswerType(rawValue: rawValue) ?? AnswerType.Text
        }
        return AnswerType.Text
    }
    
    var answers: [String] {
        return (potentialAnswers as? [String]) ?? [String]()
    }

    
    class var objectMapping: RCObjectMapping {
        let mapping = RCObjectMapping(objectClass: Question.self, mappingArray: ["text", "potentialAnswers"])
        mapping.addPropertyMappingFromDictionary(["id": "_id", "answerTypeRawValue": "type"])
        return mapping
    }
    
    class var responseDescriptor: RCResponseDescriptor {
        return RCResponseDescriptor(objectMapping: Question.objectMapping, pathPattern: APIManager.APIPath.NextQuestion)
    }
}

