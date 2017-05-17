//
//  BaseViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/19/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    
    // MARK: - Keyboard

    func addKeyboardObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseViewController.keyboardWillShowNotification(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseViewController.keyboardWillHideNotification(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func removeKeyboardObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    private func getSizeAnimationDurationAndOptionsFromUserInfo(userInfo: [NSObject: AnyObject]) -> (CGSize, Double, UIViewAnimationOptions) {
        let size = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().size
        let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let animationOptionRaw = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16
        let animationOptions = UIViewAnimationOptions(rawValue: UInt(animationOptionRaw))
        return (size, animationDuration, animationOptions)
    }
    
    func keyboardWillShowNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardInfo = getSizeAnimationDurationAndOptionsFromUserInfo(userInfo)
            keyboardWillShowWithSize(keyboardInfo.0, animationDuration: keyboardInfo.1, animationOptions: keyboardInfo.2)
        }
    }
    
    func keyboardWillHideNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardInfo = getSizeAnimationDurationAndOptionsFromUserInfo(userInfo)
            keyboardWillHideWithSize(keyboardInfo.0, animationDuration: keyboardInfo.1, animationOptions: keyboardInfo.2)
        }
    }
    
    func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        
    }
    
    func keyboardWillHideWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        
    }
    
    // MARK: - Tutorial
    
    func addTutorialObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseViewController.visualizationTapped(_:)), name: TutorialBubbleCollectionViewCell.Notifications.VisualizationTap, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseViewController.affirmationTapped(_:)), name: TutorialBubbleCollectionViewCell.Notifications.AfirmationTap, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseViewController.didMoveToNextTutorialNotification(_:)), name: TutorialManager.Notifications.DidMoveToNextStep, object: nil)
    }
    
    func removeTutorialObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: TutorialManager.Notifications.DidMoveToNextStep, object: nil)
    }
    
    func affirmationTapped(notification: NSNotification) { }
    func visualizationTapped(notification: NSNotification) { }
    
    func didMoveToNextTutorialNotification(notification: NSNotification) {
        if let tutorialStep = notification.userInfo?[TutorialManager.UserInfoKeys.TutorialStep] as? TutorialStep {
            didMoveToNextTutorial(tutorialStep)
        }
    }
    
    func didMoveToNextTutorial(tutorialStep: TutorialStep) {
        var delay: Float = 0
        if tutorialStep.enabledContols.contains("BackButton") ||
           tutorialStep.enabledContols.contains("MoreTab") {
           delay = TutorialManager.sharedInstance.delayForCurrentStep()
        }
        dispatchInMainThreadAfter(delay: delay) { 
            self.enableControls(tutorialStep.enabledContols)
        }
    }

    func enableControls(controlNames: [String]?) {
        
    }
}
