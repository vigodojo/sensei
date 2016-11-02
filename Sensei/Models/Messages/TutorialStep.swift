//
//  TutorialStep.swift
//  Sensei
//
//  Created by Sauron Black on 7/15/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

enum StepIndexes: Int {
    case WhatInYourNameIndex = 1
    case MayIAskYourSexIndex = 3
    case AfterThankYouIndex = 5
    case CreatedAffirmationIndex = 12
    case CreatedVisualizationIndex = 18
    case YouCanHideMeByTappingIndex = 29
}

class TutorialStep: Message {
    
    private struct Keys {
        static let Number = "Number"
        static let DelayBefore = "DelayBefore"
        static let ScreenName = "ScreenName"
        static let Message = "Message"
        static let AnimatableImage = "AnimatableImage"
        static let EnabledContols = "EnabledContols"
        static let AllowedActionName = "AllowedActionName"
        static let RequiresActionToProceed = "RequiresActionToProceed"
    }
    
    private struct Constants {
        static let NamePlaceholder = "<#Name>"
        static let PersonalTitlePlaceholder = "<#PersonalTitle>"
    }

    let number: Int
    let screen: ScreenName
    var message: String?
    var animatableImage: AnimatableImage?
    var delayBefore: Float = 0
    let enabledContols: [String]
    let allowedAction: ActionName?
    let requiresActionToProceed: Bool
    
    var id: String {
        return "\(number)"
    }
    var attributedText: NSAttributedString?
    var text: String {
        get {
            if let message = message {
                if let range = message.rangeOfString(Constants.NamePlaceholder, options: .CaseInsensitiveSearch, range: nil, locale: nil) {
                    return message.stringByReplacingCharactersInRange(range, withString: Settings.sharedSettings.name)
                } else if let range = message.rangeOfString(Constants.PersonalTitlePlaceholder, options: .CaseInsensitiveSearch, range: nil, locale: nil) {
                    return message.stringByReplacingCharactersInRange(range, withString: Settings.sharedSettings.gender.personalTitle)
                } else {
                    return message
                }
            } else {
                return ""
            }
        }
        set {
            message = newValue
        }
    }
    var date = NSDate()

    init(dictionary: [String: AnyObject]) {
        number = (dictionary[Keys.Number] as! NSNumber).integerValue
        screen = ScreenName(rawValue: dictionary[Keys.ScreenName] as! String)!
        delayBefore = (dictionary[Keys.DelayBefore] as? NSNumber)?.floatValue ?? 0
        message = dictionary[Keys.Message] as? String
        if let animatableImageDictionary = dictionary[Keys.AnimatableImage] as? [String: AnyObject] {
            animatableImage = AnimatableImage(dictionary: animatableImageDictionary)
        }
        enabledContols = dictionary[Keys.EnabledContols] as? [String] ?? []
        if let allowedActionString = dictionary[Keys.AllowedActionName] as? String {
            allowedAction = ActionName(rawValue: allowedActionString)
        } else {
            allowedAction = nil
        }
        requiresActionToProceed = (dictionary[Keys.RequiresActionToProceed] as! NSNumber).boolValue
    }
    
    func isLast() -> Bool {
        return number == TutorialManager.sharedInstance.stepsCount()
    }
}

extension TutorialStep: CustomStringConvertible {
    
    var description: String {
        return "№: \(number); DelayBefore: \(delayBefore); Screen: \(screen.rawValue); Requires Action To Proceed: \(requiresActionToProceed)"
    }
}
