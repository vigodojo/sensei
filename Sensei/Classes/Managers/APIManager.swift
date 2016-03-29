//
//  APIManager.swift
//  Sensei
//
//  Created by Sauron Black on 5/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import RestClient

typealias JSONObject = [NSObject: AnyObject]

class APIManager: NSObject {
    
    typealias ErrorHandlerClosure = (error: NSError?) -> Void
    typealias ResultHandlerClosure = (error: NSError?, result: AnyObject?) -> Void
    
    static let sharedInstance = APIManager()

//	static let BaseURL = NSURL(string: "http://54.183.230.244:8831")! //LA
//	static let BaseURL = NSURL(string: "http://54.183.230.244:8832")! //LA test
    static let BaseURL = NSURL(string: "http://192.168.88.181:8831")! //Alex Local
    
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
        static let DeviceToken = "/push/pushURL"
        static let Settings = "/user/settings"
        static let Instructions = "/user/instructions"
    }
    
    var logined = false
    var loggingIn = false
    var deviceToken: String?
    
    lazy var reachability: Reachability = { [unowned self] in
        return try! Reachability.reachabilityForInternetConnection()
    }()
    
    override init() {
        super.init()
        do {
            try reachability.startNotifier()
        } catch {
            print("could not start notifier")
        }
    }
    
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
        sessionManager.performRequestWithBuilderBlock({ [unowned self] (requestBuilder) -> Void in
            self.loggingIn = true
            requestBuilder.path = APIPath.Login
            requestBuilder.requestMethod = RCRequestMethod.POST
            requestBuilder.object = ["deviceId": deveiceId, "timeZone": NSNumber(integer: timeZone)]
        }, completion: { [unowned self] (response) -> Void in
            self.loggingIn = false
            self.addToLog("POST \(APIManager.BaseURL)\(APIPath.Login) \(response.statusCode)")
            
            APIManager.sharedInstance.instructions({ (error) in
                
            })
            self.logined = response.successful
            if self.logined {
                OfflineManager.sharedManager.synchronizeWithServer()
            }
            if let token = self.deviceToken {
                self.sendDeviceToken(token)
            }
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    // MARK: Share And Rate 
    
    func didShare(handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ [unowned self] (requestBuilder) -> Void in
            self.loggingIn = true
            requestBuilder.path = APIPath.Login
            requestBuilder.requestMethod = RCRequestMethod.POST
            requestBuilder.object = ["param": "value"]
        }, completion: { (response) -> Void in
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    func didRate(handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ [unowned self] (requestBuilder) -> Void in
            self.loggingIn = true
            requestBuilder.path = APIPath.Login
            requestBuilder.requestMethod = RCRequestMethod.POST
            requestBuilder.object = ["param": "value"]
        }, completion: { (response) -> Void in
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    // MARK: Instructions
    
    func instructions(handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ [unowned self] (requestBuilder) -> Void in
            self.loggingIn = true
            requestBuilder.path = APIPath.Instructions
            requestBuilder.requestMethod = RCRequestMethod.GET
//            requestBuilder.object = ["param": "value"]
        }, completion: { (response) -> Void in
            if response.error == nil {
                CoreDataManager.sharedInstance.updateInstructions(response.object as? JSONObject)
            }
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }

    
    // MARK: Push Notifications
    
    func sendDeviceToken(token: String) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.DeviceToken
            builder.requestMethod = RCRequestMethod.POST
            let deviceId = NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") as! String
            builder.object = ["provider": "APPLE", "deviceURL": token, "deviceId": deviceId]
        }, completion: { (response) -> Void in
            print(String(data: response.request.HTTPBody!, encoding: NSUTF8StringEncoding))
            self.addToLog("POST \(APIManager.BaseURL)\(APIPath.DeviceToken) \(response.statusCode)")
        })
    }
    
    // MARK: Lessons
    
    func lessonsHistoryCompletion(handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.LessonsHistory
            builder.requestMethod = RCRequestMethod.GET
        }, completion: { (response) -> Void in
            if let object = response.object {
                print(object)
            }
            self.addToLog("GET \(APIManager.BaseURL)\(APIPath.LessonsHistory) \(response.statusCode)")
            if response.error == nil && TutorialManager.sharedInstance.completed {
                CoreDataManager.sharedInstance.mergeJSONs(response.object as? [JSONObject], entityMapping: Lesson.entityMapping)
            }
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    func blockLessonWithId(id: String, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.BlockLesson
            builder.requestMethod = RCRequestMethod.POST
            builder.object = ["blockMsg": id]
        }, completion: { (response) -> Void in
            self.addToLog("POST \(APIManager.BaseURL)\(APIPath.BlockLesson) [blockMsg: \(id)] \(response.statusCode)")
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    // MARK: Questions
    
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
    
    // MARK: Affirmations
    
    func saveAffirmation(affirmation: Affirmation, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.Affirmation + "\(affirmation.number)"
            builder.requestMethod = RCRequestMethod.POST
            builder.object = affirmation
        }, completion: { (response) -> Void in
            print("\(response.request.HTTPBody)")
            print("POST \(APIManager.BaseURL)\(APIPath.Affirmation)\(affirmation.number) \(response.statusCode)")
            self.addToLog("POST \(APIManager.BaseURL)\(APIPath.Affirmation)\(affirmation.number) \(response.statusCode)")
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    func deleteAffirmation(affirmation: Affirmation, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.Affirmation + "\(affirmation.number)"
            builder.requestMethod = RCRequestMethod.DELETE
        }, completion: { (response) -> Void in
            print("DELETE \(APIManager.BaseURL)\(APIPath.Affirmation)\(affirmation.number) \(response.statusCode)")
            self.addToLog("DELETE \(APIManager.BaseURL)\(APIPath.Affirmation)\(affirmation.number) \(response.statusCode)")
//            print("\(response)")
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    func deleteAffirmationWithNumber(affirmationNumber: NSNumber, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.Affirmation + "\(affirmationNumber)"
            builder.requestMethod = RCRequestMethod.DELETE
        }, completion: { (response) -> Void in
//            print("\(response)")
            print("DELETE \(APIManager.BaseURL)\(APIPath.Affirmation)\(affirmationNumber) \(response.statusCode)")
            self.addToLog("DELETE \(APIManager.BaseURL)\(APIPath.Affirmation)\(affirmationNumber) \(response.statusCode)")
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    // MARK: Visualizations
    
    func saveVisualization(visualization: Visualization, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.Visualization + "\(visualization.number)"
            builder.requestMethod = RCRequestMethod.POST
            builder.object = visualization
        }, completion: { (response) -> Void in
//            print("\(response)")
            print("POST \(APIManager.BaseURL)\(APIPath.Visualization)\(visualization.number) \(response.statusCode)")
            self.addToLog("POST \(APIManager.BaseURL)\(APIPath.Visualization)\(visualization.number) \(response.statusCode)")
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
//            print("\(response)")
            
            print("DELETE \(APIManager.BaseURL)\(APIPath.Visualization)\(visualization.number) \(response.statusCode)")
            self.addToLog("DELETE \(APIManager.BaseURL)\(APIPath.Visualization)\(visualization.number) \(response.statusCode)")
            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    func deleteVisualizationWithNumber(visualizationNumber: NSNumber, handler: ErrorHandlerClosure?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.Visualization + "\(visualizationNumber)"
            builder.requestMethod = RCRequestMethod.DELETE
        }, completion: { (response) -> Void in
//            print("\(response)")
            print("DELETE \(APIManager.BaseURL)\(APIPath.Visualization)\(visualizationNumber) \(response.statusCode)")
            self.addToLog("DELETE \(APIManager.BaseURL)\(APIPath.Visualization)\(visualizationNumber) \(response.statusCode)")

            if let handler = handler {
                handler(error: response.error)
            }
        })
    }
    
    // MARK: Settings 
    
    func addToLog(string: String) {
        if let tutorialViewController = (UIApplication.sharedApplication().delegate as! AppDelegate).window?.rootViewController as? TutorialViewController {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "HH:mm:ss:SSS"
            tutorialViewController.logTextView.text = "\(formatter.stringFromDate(NSDate())) \(string)\n\(tutorialViewController.logTextView.text)"
        }
    }
    
    func updateSettingsWithCompletion(handler: ((settings: Settings, error: NSError?) -> Void)?) {
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.Settings
            builder.requestMethod = RCRequestMethod.GET
        }, completion: { (response) -> Void in
//            print("\(response)")
            print("GET \(APIManager.BaseURL)\(APIPath.Settings) \(response.statusCode)")
            self.addToLog("GET \(APIManager.BaseURL)\(APIPath.Settings) \(response.statusCode)")
            print("\(response.object)")
            if let json = response.object as? JSONObject {
                Settings.updateWithJSON(json)
            }
            if let handler = handler {
                handler(settings: Settings.sharedSettings, error: response.error)
            }
        })
    }
    
    func saveSettings(settings: Settings, handler: ErrorHandlerClosure?) {
//        settings.gender = .SheMale
        sessionManager.performRequestWithBuilderBlock({ (builder) -> Void in
            builder.path = APIPath.Settings
            builder.requestMethod = RCRequestMethod.POST
            builder.object = settings
        }, completion: { (response) -> Void in
            print(String(data: response.request.HTTPBody!, encoding: NSUTF8StringEncoding))
            print("POST \(APIManager.BaseURL)\(APIPath.Settings) \(response.statusCode)")
            self.addToLog("POST \(APIManager.BaseURL)\(APIPath.Settings) \(response.statusCode)")
            print("Request Corpse = \(NSString(data: response.request.HTTPBody!, encoding: 4))")
            print("\(response)")
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
        manager.addRequestDescriptor(Visualization.requestDescriptor)
        manager.addRequestDescriptor(Settings.requestDescriptor)
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