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
    private var stepCounter = -1
    private(set) var lastCompletedStepNumber: Int?
    private(set) var completed = false
    
    var notFinishedTutorialScreenName: ScreenName? {
        return ((stepCounter + 1) < steps.count) ? steps[stepCounter + 1].screen: nil
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
        increaseStepCounter()
        if stepCounter < steps.count {
            let step = steps[stepCounter]
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidMoveToNextStep, object: nil, userInfo: [UserInfoKeys.TutorialStep: step])
        }
        checkCompletion()
    }
    
    func skipStep() {
        increaseStepCounter()
        checkCompletion()
    }
    
    // MARK: - Private
    
    private func increaseStepCounter() {
        stepCounter++
        if stepCounter > 0 {
            lastCompletedStepNumber = stepCounter - 1
            NSUserDefaults.standardUserDefaults().setObject(NSNumber(integer: lastCompletedStepNumber!), forKey: UserDefaultsKeys.LastCompletedStepNumber)
        }
    }
    
    private func checkCompletion() {
        if stepCounter >= (steps.count) {
            completed = true
            NSUserDefaults.standardUserDefaults().setBool(completed, forKey: UserDefaultsKeys.Completed)
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidFinishTutorial, object: nil)
            saveToServerCreatedData()
        }
    }
    
    private func loadStepsFromPlist() {
        if let stepsPlistURL = NSBundle.mainBundle().URLForResource("Tutorial", withExtension: "plist") {
            if let stepDictionariesArray = NSArray(contentsOfURL: stepsPlistURL) as? [[String: AnyObject]] {
                for stepDictionary in stepDictionariesArray {
                    let step = tutorialStepFromDictionary(stepDictionary)
                    steps.append(step)
                    println("Step: \(step)")
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
    
    private func saveToServerCreatedData() {
        APIManager.sharedInstance.saveSettings(Settings.sharedSettings) {  error in
            if let affirmation = Affirmation.affirmationWithNumber(NSNumber(integer: 0)) {
                APIManager.sharedInstance.saveAffirmation(affirmation, handler: nil)
            }
            if let visualisation = Visualization.visualizationWithNumber(NSNumber(integer: 0)) {
                APIManager.sharedInstance.saveVisualization(visualisation, handler: nil)
            }
        }
    }
}