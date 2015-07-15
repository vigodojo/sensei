//
//  QuestionTutorialStep.swift
//  Sensei
//
//  Created by Sauron Black on 7/15/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

enum QuestionType: String {
    
    case Text = "TEXT"
    case Number = "NUMBER"
    case Date = "DATE"
    case Choice = "RADIO"
    case Length = "LENGTH"
    case Mass = "MASS"
}

enum QuestionSubject: String {
    
    case Unkonwn = "Unkonwn"
    case Name = "Name"
    case Gender = "Gender"
}

protocol QuestionProtocol: Message {
    
    var questionType: QuestionType { get set }
    var questionSubject: QuestionSubject { get set }
    var answers: [String] { get set }
}

class QuestionTutorialStep: TutorialStep, QuestionProtocol {
    
    private struct Keys {
        static let QuestionType = "QuestionType"
        static let QuestionSubject = "QuestionSubject"
        static let Answers = "Answers"
    }
    
    class func isDictionaryQuestionTutorialStep(dictionary: [String: AnyObject]) -> Bool {
        return (dictionary[Keys.QuestionType] as? String) != nil
    }
    
    var questionType: QuestionType
    var questionSubject: QuestionSubject
    var answers: [String]
    
    override init(dictionary: [String : AnyObject]) {
        answers = dictionary[Keys.Answers] as? [String] ?? []
        if let questionTypeString =  (dictionary[Keys.QuestionType] as? String), questionType = QuestionType(rawValue: questionTypeString) {
            self.questionType = questionType
        } else {
            self.questionType = QuestionType.Text
        }
        if let questionSubjectString =  (dictionary[Keys.QuestionSubject] as? String), questionSubject = QuestionSubject(rawValue: questionSubjectString) {
            self.questionSubject = questionSubject
        } else {
            self.questionSubject = QuestionSubject.Unkonwn
        }
        super.init(dictionary: dictionary)
    }
}