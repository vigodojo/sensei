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

    struct UpgradeKey {
        static let IsProVersion = "IsProVersion"
    }
    
    struct Notifications {
        static let DidUpgrade = "UpgradeManagerDidUpgrade"
    }

    static let sharedInstance = UpgradeManager()

    func askForUpgrade() {
        let alert = UIAlertView(title: "Alert", message: "Are you sure you want to upgrade Sensei app to Premium version?", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Upgrade")
        alert.show()
    }
    
    func isProVersion() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey(UpgradeKey.IsProVersion)
    }
}

extension UpgradeManager: UIAlertViewDelegate{
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: UpgradeKey.IsProVersion)
            NSUserDefaults.standardUserDefaults().synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidUpgrade, object: nil);
        }
    }
}