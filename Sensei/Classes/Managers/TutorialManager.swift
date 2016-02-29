 //
//  TutorialManager.swift
//  Sensei
//
//  Created by Sauron Black on 7/15/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import UIKit

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
        static let LastAffirmationInstrucitonNumebr = "LastAffirmationInstrucitonNumebr"
        static let LastVisualizationInstructionNumber = "LastVisualizationInstructionNumber"
    }
    
    static let sharedInstance = TutorialManager()

    private var steps = [TutorialStep]()
    private var upgradedSteps = [TutorialStep]()
    
    private var stepCounter = -1
    private var upgradedStepCounter = -1

    private(set) var lastCompletedStepNumber: Int?
    private(set) var completed = false
    private(set) var upgradeCompleted = false
    
    private var lastAffirmationInstrucitonNumber: Int
    private var lastVisualizationInstructionNumber: Int
    
    private var affirmationInstructions = [String]()
    private var visualizationInstructions = [String]()
    
    var notFinishedTutorialScreenName: ScreenName? {
        return ((stepCounter + 1) < steps.count) ? steps[stepCounter + 1].screen: nil
    }
    
    var currentStep: TutorialStep? {
        if completed || stepCounter < 0 {
            return nil
        }
        if stepCounter < steps.count {
            return steps[stepCounter]
        }
        return nil
    }
    
    var currentUpgradedStep: TutorialStep? {
        if upgradedStepCounter < upgradedSteps.count {
            return upgradedSteps[upgradedStepCounter]
        }
        return nil
    }
    
    var prevTutorialStep: TutorialStep? {
        if completed {
            return nil
        }
        if stepCounter - 1 >= 0 && stepCounter < steps.count{
            return steps[stepCounter - 1]
        }
        return nil
    }
    
    var prevUpgradedStep: TutorialStep? {
        if upgradedStepCounter - 1 >= 0 && upgradedStepCounter < upgradedSteps.count{
            return upgradedSteps[upgradedStepCounter - 1]
        }
        return nil
    }
    
    // MARK: - Lifecycle
    
    init() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        completed = userDefaults.boolForKey(UserDefaultsKeys.Completed)
        upgradeCompleted = userDefaults.boolForKey(UserDefaultsKeys.UpgradeCompleted)

        lastCompletedStepNumber = (userDefaults.objectForKey(UserDefaultsKeys.LastCompletedStepNumber) as? NSNumber)?.integerValue
        if lastCompletedStepNumber == nil {
            if let stringStepNumber = userDefaults.objectForKey(UserDefaultsKeys.LastCompletedStepNumber) as? String {
                lastCompletedStepNumber = NSNumber(integer: Int(stringStepNumber)!).integerValue
            }
        }
        if let lastCompletedStepNumber = lastCompletedStepNumber {
            stepCounter = lastCompletedStepNumber
        }
        
        lastAffirmationInstrucitonNumber = (userDefaults.objectForKey(UserDefaultsKeys.LastAffirmationInstrucitonNumebr) as? NSNumber)?.integerValue ?? 0
        lastVisualizationInstructionNumber = (userDefaults.objectForKey(UserDefaultsKeys.LastVisualizationInstructionNumber) as? NSNumber)?.integerValue ?? 0
        
        if !completed {
            loadStepsFromPlist()
        }
        if !upgradeCompleted {
            loadUpgradedStepsFromPlist()
        }
        loadInstructions()
    }
    
    func delayForCurrentStep() -> Double {
        if !TutorialManager.sharedInstance.completed {
            if let currentStep = TutorialManager.sharedInstance.currentStep {
                if let prevStep = TutorialManager.sharedInstance.prevTutorialStep {
                    let delayBefore = (prevStep.text.characters.count == 0 || currentStep.delayBefore == 0) ? currentStep.delayBefore : Double(prevStep.text.characters.count) * 0.03
                    return  delayBefore
                }
                return currentStep.delayBefore
            }
        } else {
            if let currentStep = TutorialManager.sharedInstance.currentUpgradedStep {
                if let prevStep = TutorialManager.sharedInstance.prevUpgradedStep {
                    let delayBefore = (prevStep.text.characters.count == 0 || currentStep.delayBefore == 0) ? currentStep.delayBefore : Double(prevStep.text.characters.count) * 0.03
                    return delayBefore
                }
                return currentStep.delayBefore
            }
        }
        return 0
    }
    
    func nextAffInstruction() -> String {
        let instruction = affirmationInstructions[lastAffirmationInstrucitonNumber]

        lastAffirmationInstrucitonNumber += 1
        if lastAffirmationInstrucitonNumber > affirmationInstructions.count - 1 {
            lastAffirmationInstrucitonNumber = 0
        }
        NSUserDefaults.standardUserDefaults().setObject(NSNumber(integer: lastAffirmationInstrucitonNumber), forKey: UserDefaultsKeys.LastAffirmationInstrucitonNumebr)
        NSUserDefaults.standardUserDefaults().synchronize()
        return instruction
    }

    func nextVisInstruction() -> String {
        let instruction = visualizationInstructions[lastVisualizationInstructionNumber]
        
        lastVisualizationInstructionNumber += 1
        if lastVisualizationInstructionNumber > visualizationInstructions.count - 1 {
            lastVisualizationInstructionNumber = 0
        }
        NSUserDefaults.standardUserDefaults().setObject(NSNumber(integer: lastVisualizationInstructionNumber), forKey: UserDefaultsKeys.LastVisualizationInstructionNumber)
        NSUserDefaults.standardUserDefaults().synchronize()
        return instruction
    }
    
    private func loadInstructions() {
        if let affPlistURL = NSBundle.mainBundle().URLForResource("AffInstructions", withExtension: "plist") {
            if let affsArray = NSArray(contentsOfURL: affPlistURL) as? [String] {
                for affInstuction in affsArray {
                    affirmationInstructions.append(affInstuction)
                }
            }
        }
        if let visPlistURL = NSBundle.mainBundle().URLForResource("VisInstructions", withExtension: "plist") {
            if let vissArray = NSArray(contentsOfURL: visPlistURL) as? [String] {
                for visInstuction in vissArray {
                    visualizationInstructions.append(visInstuction)
                }
            }
        }
    }
    
    // MARK: - Public
    
    func lastStepNumber() -> Int {
        return stepCounter
    }
    
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
        if stepCounter >= (35) {
            let firstInstallTime = NSUserDefaults.standardUserDefaults().objectForKey("AppInstalationDateTime") as? NSDate
            if firstInstallTime == nil {
                NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "AppInstalationDateTime")
                NSUserDefaults.standardUserDefaults().synchronize()
            }
            completed = true
            NSUserDefaults.standardUserDefaults().setBool(completed, forKey: UserDefaultsKeys.Completed)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(4) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidFinishTutorial, object: nil)
            }
            saveToServerCreatedData()
        }
    }
    
    private func checkUpgradeCompletin() {
        if  upgradedStepCounter >= upgradedSteps.count {
            upgradeCompleted = true
            NSUserDefaults.standardUserDefaults().setBool(upgradeCompleted, forKey: UserDefaultsKeys.UpgradeCompleted)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(2) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidFinishUpgrade, object: nil)
            }
            saveToServerCreatedData()
        }
    }
    
    private func loadStepsFromPlist() {
        if let stepsPlistURL = NSBundle.mainBundle().URLForResource("Tutorial", withExtension: "plist") {
            if let stepDictionariesArray = NSArray(contentsOfURL: stepsPlistURL) as? [[String: AnyObject]] {
                for stepDictionary in stepDictionariesArray {
                    let step = tutorialStepFromDictionary(stepDictionary)
                    steps.append(step)
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
