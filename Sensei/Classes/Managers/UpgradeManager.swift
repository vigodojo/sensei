//
//  UpgradeManager.swift
//  Sensei
//
//  Created by Sergey Sheba on 12/11/15.
//  Copyright © 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import UIKit



class UpgradeManager:NSObject {
    
    struct Notifications {
        static let DidUpgrade = "UpgradeManagerDidUpgrade"
    }

    static let sharedInstance = UpgradeManager()

    func askForUpgrade() {
        let alert = UIAlertView(title: "Alert", message: "Are you sure you want to upgrade Sensei app to Premium version?", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Upgrade")
        alert.show()
    }
    
    func isProVersion() -> Bool {
        return Settings.sharedSettings.isProVersion?.boolValue == true
    }
}

extension UpgradeManager: UIAlertViewDelegate{
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            Settings.sharedSettings.isProVersion = NSNumber(bool: true)
            CoreDataManager.sharedInstance.saveContext()
            APIManager.sharedInstance.saveSettings(Settings.sharedSettings, handler: nil)
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidUpgrade, object: nil);
        }
    }
}