//
//  UpgradeManager.swift
//  Sensei
//
//  Created by Sergey Sheba on 12/11/15.
//  Copyright © 2015 ThinkMobiles. All rights reserved.
//

import Foundation
import UIKit
import StoreKit

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
//        return IAPurchaseManager.sharedManager.isProductPurchased("Sensei01")
        return Settings.sharedSettings.isProVersion?.boolValue == true
    }
    
    func openAppStoreURL() {
        if UIApplication.sharedApplication().canOpenURL(LinkToAppOnAppStore) {
            UIApplication.sharedApplication().openURL(LinkToAppOnAppStore)
        }
    }
    
    func buyUpgrade() {
        IAPurchaseManager.sharedManager.delegate = self
        addLoader()
        IAPurchaseManager.sharedManager.requestProducts { (success, products) in

            guard let products = products, let product = products.first else {
                self.removeLoader()
                UIAlertView(title: "Warning", message: "Something went wrong. Cannot find any products to buy", delegate: nil, cancelButtonTitle: "Okay").show()
                return
            }
            IAPurchaseManager.sharedManager.buyProduct(product)
        }
    }
}

extension UpgradeManager: IAPurchaseDelegate {
    func didPurchase(identifier productIdentifier: String, transaction: SKPaymentTransaction, success: Bool, error: NSError?) {
        if success {
            Settings.sharedSettings.isProVersion = NSNumber(bool: true)
            CoreDataManager.sharedInstance.saveContext()
            APIManager.sharedInstance.saveSettings(Settings.sharedSettings, handler: nil)
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DidUpgrade, object: nil);
        }
    }
}

extension UpgradeManager: UIAlertViewDelegate{
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            buyUpgrade()
        }
    }
}
