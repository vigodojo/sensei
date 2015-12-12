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
        static let DidFinishUpgrade = "TutorialManagerNotificationsDidFinishUpgrade"

    }
    
    struct UserInfoKeys {
        static let TutorialStep = "TutorialStep"
    }
    
    private struct UserDefaultsKeys {
        static let Completed = "TutorialManagerCompleted"
        static let UpgradeCompleted = "TutorialUpgradeCompleted"
        static let LastCompletedStepNumber = "TutorialManagerLastCompletedStepNumber"
    }
    
    static let sharedInstance = TutorialManager()

    private var steps = [TutorialStep]()
    private var upgradedSteps = [TutorialStep]()
    
    private var stepCounter = -1
    private var upgradedStepCounter = -1

    private(set) var lastCompletedStepNumber: Int?
    private(set) var completed = false
    private(set) var upgradeCompleted = false
    
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
    
    var currentUpgradedStep: TutorialStep? {
        if UpgradeManager.sharedInstance.isProVersion() {
            return nil
        }
        if upgradedStepCounter < upgradedSteps.count {
            return upgradedSteps[upgradedStepCounter]
        }
        return nil
    }
    
    var prevTutorialStep: TutorialStep? {
        if completed {
            return nil
        }
        if stepCounter - 1 > 0 && stepCounter < steps.count{
            return steps[stepCounter - 1]
        }
        return nil
    }
    
    // MARK: - Lifecycle
    
    init() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        completed = userDefaults.boolForKey(UserDefaultsKeys.Completed)
        upgradeCompleted = userDefaults.boolForKey(UserDefaultsKeys.UpgradeCompleted)

        lastCompletedStepNumber = (userDefaults.objectForKey(UserDefaultsKeys.LastCompletedStepNumber) as? NSNumber)?.integerValue
        if let lastCompletedStepNumber = lastCompletedStepNumber {
            stepCounter = lastCompletedStepNumber
        }
        if !completed {
            loadStepsFromPlist()
        }
        loadUpgradedStepsFromPlist()
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
    
    func nextUpgradedStep() {
        if !UpgradeManager.sharedInstance.isProVersion() || upgradeCompleted {
            return
        }
        upgradedStepCounter++
        if upgradedStepCounter < upgradedSteps.count {
            let step = upgradedSteps[upgradedStepCounter]
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidMoveToNextStep, object: nil, userInfo: [UserInfoKeys.TutorialStep: step])
        }
        checkUpgradeCompletin()
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

    private func decreaseStepCounter() {
        stepCounter--
        if stepCounter > 0 {
            lastCompletedStepNumber = stepCounter - 1
            NSUserDefaults.standardUserDefaults().setObject(NSNumber(integer: lastCompletedStepNumber!), forKey: UserDefaultsKeys.LastCompletedStepNumber)
        }
    }
    
    private func checkCompletion() {
        if stepCounter >= (30) {
            completed = true
            NSUserDefaults.standardUserDefaults().setBool(completed, forKey: UserDefaultsKeys.Completed)
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidFinishTutorial, object: nil)
            saveToServerCreatedData()
        }
    }
    
    private func checkUpgradeCompletin() {
        if  upgradedStepCounter >= upgradedSteps.count {
            upgradeCompleted = true
            NSUserDefaults.standardUserDefaults().setBool(upgradeCompleted, forKey: UserDefaultsKeys.UpgradeCompleted)
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidFinishUpgrade, object: nil)
            saveToServerCreatedData()
        }
    }
    
    private func loadStepsFromPlist() {
        if let stepsPlistURL = NSBundle.mainBundle().URLForResource("Tutorial", withExtension: "plist") {
            if let stepDictionariesArray = NSArray(contentsOfURL: stepsPlistURL) as? [[String: AnyObject]] {
                for stepDictionary in stepDictionariesArray {
                    let step = tutorialStepFromDictionary(stepDictionary)
                    steps.append(step)
                    print("Step: \(step)")
                }
            }
        }
    }
    
    private func loadUpgradedStepsFromPlist() {
        if let stepsPlistURL = NSBundle.mainBundle().URLForResource("Tutorial", withExtension: "plist") {
            if let stepDictionariesArray = NSArray(contentsOfURL: stepsPlistURL) as? [[String: AnyObject]] {
                for stepDictionary in stepDictionariesArray {
                    if stepDictionary["Upgraded"]?.boolValue == true {
                        let step = tutorialStepFromDictionary(stepDictionary)
                        upgradedSteps.append(step)
                        print("UpgradedStep: \(step)")
                    }
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
                APIManager.sharedInstance.saveAffirmation(affirmation) { error in
                    if let visualisation = Visualization.visualizationWithNumber(NSNumber(integer: 0)) {
                        APIManager.sharedInstance.saveVisualization(visualisation, handler: nil)
                    }
                }
            }
        }
    }
}
