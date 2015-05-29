//
//  APIManager.swift
//  Sensei
//
//  Created by Sauron Black on 5/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import RestClient

class APIManager: NSObject {
    
    typealias ErrorHandlerClosure = (error: NSError?) -> Void
    
    static let sharedInstance = APIManager()
    static let BaseURL = NSURL(string: "http://134.249.164.53:8831")!
    
    struct APIPath {
        static let Login = "/user/signIn"
        static let LessonsHistory = "/user/history"
        static let BlockLesson = "/user/blockLesson"
        static let NextQuestion = "/question/next"
        static let AnswerQuestion = "/question/answer/"
        static let AnswerQuestionPathPattern = "/question/answer/:id"
    }
    
    var logined = false
    
    lazy var sessionManager: RCSessionManager = { [unowned self] in
        let manager = RCSessionManager(baseURL: APIManager.BaseURL)
        manager.delegate = self
        self.addResponseDescriptoresForSessionManager(manager)
        self.addRequestDescriptoresForSessionManager(manager)
        return manager
    }()
    
     // MARK: - Public
     // MARK: - Login
    
    func loginWithDeviceId(deveiceId: String, timeZone: Int, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (requestBuilder) -> Void in
            requestBuilder.path = APIPath.Login
            requestBuilder.requestMethod = RCRequestMethod.POST
            requestBuilder.object = ["deviceId": deveiceId, "timeZone": NSNumber(integer: timeZone)]
        }, completion: { (response) -> Void in
            self.logined = response.error == nil
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    // MARK: - Lessons
    
    func lessonsHistoryWithCompletion(handler: ((lessons: [Lesson]?, error: NSError?) -> Void)?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.LessonsHistory
            builder.requestMethod = RCRequestMethod.GET
        }, completion: { (response) -> Void in
            if let handler = handler {
                handler(lessons: response.object as? [Lesson], error: response.error)
            }
        })
    }
    
    func blockLessonWithId(id: String, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.BlockLesson
            builder.requestMethod = RCRequestMethod.POST
            builder.object = ["blockMsg": id]
        }, completion: { (response) -> Void in
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    // MARK: - Questions
    
    func nextQuestionyWithCompletion(handler: ((question: Question?, error: NSError?) -> Void)?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.NextQuestion
            builder.requestMethod = RCRequestMethod.GET
        }, completion: { (response) -> Void in
            if let handler = handler {
                handler(question: response.object as? Question , error: response.error)
            }
        })
    }
    
    func answerQuestionWithId(questionId: String, answerText: String, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.AnswerQuestion + questionId
            builder.requestMethod = RCRequestMethod.POST
            builder.object = ["answer": answerText]
        }, completion: { (response) -> Void in
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    // MARK: - Private
    
    private func addResponseDescriptoresForSessionManager(manager: RCSessionManager) {
        manager.addResponseDescriptor(Lesson.responseDescriptor)
        //manager.addResponseDescriptor(Question.responseDescriptor)
    }
    
    private func addRequestDescriptoresForSessionManager(manager: RCSessionManager) {
        
    }
}

extension APIManager: RCSessionManagerDelegate {
    
    func sessionManager(sessionManager: RCSessionManager!, didReceivedResponse response: RCResponse!) {
        //
    }
}