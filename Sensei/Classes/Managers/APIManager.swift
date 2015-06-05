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
        static let Affirmation = "/user/affirmation/"
        static let AffirmationPathPattern = "/user/affirmation/:id"
        static let Visualization = "/user/visualisation/"
        static let VisualizationPathPattern = "/user/visualisation/:id"
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
    
    func lessonsHistory() {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.LessonsHistory
            builder.requestMethod = RCRequestMethod.GET
        }, completion: { (response) -> Void in
            if response.error == nil {
                CoreDataManager.sharedInstance.mergeJSONs(response.object as? [[NSObject: AnyObject]], entityMapping: Lesson.entityMapping)
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
            let question = (response.object as? Question)?.id != nil ? (response.object as? Question): nil
            if let handler = handler {
                handler(question: question , error: response.error)
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
    
    // MARK: - User Message 
    
    func saveUserMessage(userMessage: UserMessage, handler: ErrorHandlerClosure?) {
        if userMessage is Affirmation {
            saveAffirmation(userMessage as! Affirmation, handler: handler)
        } else if userMessage is Visualization {
            saveVisualization(userMessage as! Visualization, handler: handler)
        }
    }
    
    func deleteUserMessage(userMessage: UserMessage, handler: ErrorHandlerClosure?) {
        if userMessage is Affirmation {
            deleteAffirmation(userMessage as! Affirmation, handler: handler)
        } else if userMessage is Visualization {
            deleteVisualization(userMessage as! Visualization, handler: handler)
        }
    }
    
    // MARK: - Affirmations
    
    func saveAffirmation(affirmation: Affirmation, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.Affirmation + "\(affirmation.number.integerValue)"
            builder.requestMethod = RCRequestMethod.POST
            builder.object = affirmation
        }, completion: { (response) -> Void in
            println("\(response)")
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    func deleteAffirmation(affirmation: Affirmation, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.Affirmation + "\(affirmation.number.integerValue)"
            builder.requestMethod = RCRequestMethod.DELETE
        }, completion: { (response) -> Void in
            println("\(response)")
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    // MARK: - Visualizations
    
    func saveVisualization(visualization: Visualization, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.Visualization + "\(visualization.number.integerValue)"
            builder.requestMethod = RCRequestMethod.POST
            builder.object = visualization
            }, completion: { (response) -> Void in
                if let handler = handler {
                    handler(error: response.error)
                }
        })
    }
    
    func deleteVisualization(visualization: Visualization, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.Visualization + "\(visualization.number)"
            builder.requestMethod = RCRequestMethod.DELETE
        }, completion: { (response) -> Void in
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    // MARK: - Private
    
    private func addResponseDescriptoresForSessionManager(manager: RCSessionManager) {
        manager.addResponseDescriptor(Question.responseDescriptor)
    }
    
    private func addRequestDescriptoresForSessionManager(manager: RCSessionManager) {
        manager.addRequestDescriptor(Affirmation.requestDescriptor)
    }
}

extension APIManager: RCSessionManagerDelegate {
    
    func sessionManager(sessionManager: RCSessionManager!, didReceivedResponse response: RCResponse!) {
        //
    }
}

// MARK: - Test Data

extension APIManager {
    
    func testLessonJSONsForFirstWeek() -> [[NSObject: AnyObject]] {
        let lessonJSON0 = ["lessonId": "0", "text": "Eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, aus.", "date": "2015-05-22T09:00:00.755Z"]
        let lessonJSON1 = ["lessonId": "1", "text": "Alle warten auf das Licht\nFürchtet euch fürchtet euch nicht\nDie Sonne scheint mir aus den Augen\nsie wird heut Nacht nicht untergehen\nund die Welt zählt laut bis zehn", "date": "2015-05-22T010:00:00.755Z"]
        let lessonJSON2 = ["lessonId": "2", "text": "eins\nHier kommt die Sonne\nzwei\n Hier kommt die Sonne \ndrei\nSie ist der hellste Stern von allen\nvier\nHier kommt die Sonne", "date": "2015-05-23T09:40:00.755Z"]
        let lessonJSON3 = ["lessonId": "0", "text": "Eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, aus.", "date": "2015-05-24T09:10:00.755Z"]
        return [lessonJSON0, lessonJSON1, lessonJSON2, lessonJSON3]
    }
    
    func testLessonJSONsForSecondWeek() -> [[NSObject: AnyObject]] {
        let lessonJSON0 = ["lessonId": "1", "text": "Alle warten auf das Licht\nFürchtet euch fürchtet euch nicht\nDie Sonne scheint mir aus den Augen\nsie wird heut Nacht nicht untergehen\nund die Welt zählt laut bis zehn", "date": "2015-05-22T10:00:00.755Z"]
        let lessonJSON1 = ["lessonId": "2", "text": "Schwarzalbenheims Gewurm\nSchmiedet solch schimmerndes Gold\nDer Gotter Glorie gestaltend\nAus der erde Geader", "date": "2015-05-23T09:40:00.755Z"]
        let lessonJSON2 = ["lessonId": "0", "text": "Eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, aus.", "date": "2015-05-24T09:10:00.755Z"]
        let lessonJSON3 = ["lessonId": "3", "text": "Eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, aus.", "date": "2015-05-25T16:30:00.755Z"]
        let lessonJSON4 = ["lessonId": "2", "text": "Schwarzalbenheims Gewurm\nSchmiedet solch schimmerndes Gold\nDer Gotter Glorie gestaltend\nAus der erde Geader", "date": "2015-05-27T13:00:00.755Z"]
        return [lessonJSON0, lessonJSON1, lessonJSON2, lessonJSON3, lessonJSON4]
    }
}