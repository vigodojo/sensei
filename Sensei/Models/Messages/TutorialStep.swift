//
//  TutorialStep.swift
//  Sensei
//
//  Created by Sauron Black on 7/15/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import Foundation

class TutorialStep: Message {
    
    private struct Keys {
        static let Number = "Number"
        static let ScreenName = "ScreenName"
        static let Message = "Message"
        static let AnimatableImage = "AnimatableImage"
        static let EnabledContols = "EnabledContols"
        static let AllowedActionName = "AllowedActionName"
        static let RequiresActionToProceed = "RequiresActionToProceed"
    }
    
    private struct Constants {
        static let StringPlaceholder = "%@"
    }

    let number: Int
    let screen: ScreenName
    var message: String?
    var animatableImage: AnimatableImage?
    let enabledContols: [String]
    let allowedAction: ActionName?
    let requiresActionToProceed: Bool
    var id: String {
        return "\(number)"
    }
    var text: String {
        get {
            if let message = message {
                if let range = message.rangeOfString(Constants.StringPlaceholder, options: .CaseInsensitiveSearch, range: nil, locale: nil) {
                    return String(format: message, Settings.sharedSettings.name)
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
}