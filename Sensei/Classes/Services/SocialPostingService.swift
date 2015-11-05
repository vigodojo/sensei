//
//  SocialPostingService.swift
//  Sensei
//
//  Created by Eugenity on 03.11.15.
//  Copyright © 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import Social

enum SocialPostingType: String {
    case Facebook = "Facebook"
    case Twitter = "Twitter"

    var chosenService: String {
        switch self {
        case .Facebook: return SLServiceTypeFacebook
        case .Twitter: return SLServiceTypeTwitter
        }
    }
}

class SocialPostingService {
    
    private struct Constants {
        static let AttachedText         = "#ViGoSensei app. It is making a positive difference in my life."
        static let AttachedImageName    = "SenseiIconForPosting"
    }
    
    static func postToSocialNetworksWithType(socialPostingType: SocialPostingType, fromController: UIViewController, completion: SLComposeViewControllerCompletionHandler) {

        if SLComposeViewController.isAvailableForServiceType(socialPostingType.chosenService) {
            let socialController = SLComposeViewController(forServiceType: socialPostingType.chosenService)
            
            let initialTextSet  = socialController.setInitialText(Constants.AttachedText)
            let urlSet          = socialController.addURL(LinkToAppOnAppStore)
            let imageSet        = socialController.addImage(UIImage(named: Constants.AttachedImageName))
            
            socialController.completionHandler = completion
            
            if initialTextSet && imageSet && urlSet {
                fromController.presentViewController(socialController, animated: true, completion: nil)
            }
            
        } else {
            AlertMessagesService.showDialogAlert(socialPostingType.rawValue + " unavailable", message: "Please enter you login and password in Settings.app", fromController: fromController, completion: { (alertAction, isConfirmed) -> Void in
                
                if isConfirmed {
                    if let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString) {
                        UIApplication.sharedApplication().openURL(settingsURL)
                    }
                }
                
            })
        }
    }
}