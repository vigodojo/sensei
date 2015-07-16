//
//  TutorialManager.swift
//  Sensei
//
//  Created by Sauron Black on 7/15/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

class TutorialManager {
    
    struct Notifications {
        static let DidMoveToNextStep = "TutorialManagerNotificationsDidMoveToNextStep"
        static let DidFinishTutorial = "TutorialManagerNotificationsDidFinishTutorial"
    }
    
    struct UserInfoKeys {
        static let TutorialStep = "TutorialStep"
    }
    
    private struct UserDefaultsKeys {
        static let Completed = "TutorialManagerCompleted"
        static let LastCompletedStepNumber = "TutorialManagerLastCompletedStepNumber"
    }
    
    static let sharedInstance = TutorialManager()

    private var steps = [TutorialStep]()
    private var stepCounter = 0
    private(set) var lastCompletedStepNumber: Int?
    private(set) var completed = false
    
    var notFinishedTutorialScreenName: ScreenName? {
        return currentStep?.screen
    }
    
    var currentStep: TutorialStep? {
        if completed {
            return nil
        }
        if stepCounter < steps.count {
            return steps[stepCounter]
        }
        return nil
    }
    
    // MARK: - Lifecycle
    
    init() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        completed = userDefaults.boolForKey(UserDefaultsKeys.Completed)
        lastCompletedStepNumber = (userDefaults.objectForKey(UserDefaultsKeys.LastCompletedStepNumber) as? NSNumber)?.integerValue
        if let lastCompletedStepNumber = lastCompletedStepNumber {
            stepCounter = lastCompletedStepNumber
        }
        if !completed {
            loadStepsFromPlist()
        }
    }
    
    // MARK: - Public
    
    func nextStep() {
        if completed {
            return
        }
        if stepCounter < steps.count {
            let step = steps[stepCounter]
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidMoveToNextStep, object: nil, userInfo: [UserInfoKeys.TutorialStep: step])
        }
        increaseStepCounter()
    }
    
    func skipStep() {
        increaseStepCounter()
    }
    
    // MARK: - Private
    
    private func increaseStepCounter() {
        if stepCounter > 0 {
            lastCompletedStepNumber = stepCounter
            NSUserDefaults.standardUserDefaults().setObject(NSNumber(integer: stepCounter), forKey: UserDefaultsKeys.LastCompletedStepNumber)
        }
        stepCounter++
        if stepCounter > steps.count {
            completed = true
            NSUserDefaults.standardUserDefaults().setBool(completed, forKey: UserDefaultsKeys.Completed)
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidFinishTutorial, object: nil)
        }
    }
    
    private func loadStepsFromPlist() {
        if let stepsPlistURL = NSBundle.mainBundle().URLForResource("Tutorial", withExtension: "plist") {
            if let stepDictionariesArray = NSArray(contentsOfURL: stepsPlistURL) as? [[String: AnyObject]] {
                println("\(stepDictionariesArray)")
                for stepDictionary in stepDictionariesArray {
                    steps.append(tutorialStepFromDictionary(stepDictionary))
                }
            }
        }
    }
    
    private func tutorialStepFromDictionary(dictionary: [String: AnyObject]) -> TutorialStep {
        if QuestionTutorialStep.isDictionaryQuestionTutorialStep(dictionary) {
            return QuestionTutorialStep(dictionary: dictionary)
        } else {
            return TutorialStep(dictionary: dictionary)
        }
    }
}