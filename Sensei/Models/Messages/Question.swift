//
//  Question.swift
//  Sensei
//
//  Created by Sauron Black on 5/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import RestClient

class Question: NSObject, QuestionProtocol {
    
    var questionId: String?
    var questionText: String?
    var potentialAnswers: [AnyObject]?
    var questionTypeRawValue: String?
    var date = NSDate()
    var id: String { return questionId ?? "0"}
    var text: String {
        get {
            return questionText ?? ""
        }
        set {
            questionText = newValue
        }
    }
    
    var questionType: QuestionType {
        get {
            if let rawValue = questionTypeRawValue {
                return QuestionType(rawValue: rawValue) ?? QuestionType.Text
            }
            return QuestionType.Text
        }
        set {
            questionTypeRawValue = newValue.rawValue
        }
    }
    
    var answers: [String] {
        get {
            return (potentialAnswers as? [String]) ?? [String]()
        }
        set {
            potentialAnswers = newValue
        }
    }

    var questionSubject = QuestionSubject.Unkonwn
    
    class var objectMapping: RCObjectMapping {
        let mapping = RCObjectMapping(objectClass: Question.self, mappingArray: ["text", "potentialAnswers"])
        mapping.addPropertyMappingFromDictionary(["questionId": "_id", "questionTypeRawValue": "type"])
        return mapping
    }
    
    class var responseDescriptor: RCResponseDescriptor {
        return RCResponseDescriptor(objectMapping: Question.objectMapping, pathPattern: APIManager.APIPath.NextQuestion)
    }
}

