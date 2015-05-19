//
//  BaseViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/19/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    func addKeyboardObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShowNotification:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHideNotification:"), name: UIKeyboardWillHideNotification, object: nil)
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
}
