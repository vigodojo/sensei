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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShowNotification:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHideNotification:"), name: UIKeyboardWillHideNotification, object: nil)
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("visualizationTapped:"), name: TutorialBubbleCollectionViewCell.Notifications.VisualizationTap, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("affirmationTapped:"), name: TutorialBubbleCollectionViewCell.Notifications.AfirmationTap, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didMoveToNextTutorialNotification:"), name: TutorialManager.Notifications.DidMoveToNextStep, object: nil)
    }
    
    func removeTutorialObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: TutorialManager.Notifications.DidMoveToNextStep, object: nil)
    }
    
    func affirmationTapped(notification: NSNotification) {
    }
  
    func visualizationTapped(notification: NSNotification) {
    }
    
    func didMoveToNextTutorialNotification(notification: NSNotification) {
        if let tutorialStep = notification.userInfo?[TutorialManager.UserInfoKeys.TutorialStep] as? TutorialStep {
            didMoveToNextTutorial(tutorialStep)
        }
    }
    
    func didMoveToNextTutorial(tutorialStep: TutorialStep) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(tutorialStep.delayBefore) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
            self.enableControls(tutorialStep.enabledContols)
        }
    }
    
    func enableControls(controlNames: [String]?) {
        
    }
}
