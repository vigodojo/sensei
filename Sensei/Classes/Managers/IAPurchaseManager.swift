//
//  IAPurchaseManager.swift
//  habi-v2
//
//  Created by Sergey Sheba on 3/21/16.
//  Copyright © 2016 Thinkmobiles. All rights reserved.
//

import UIKit

class IAPurchaseManager: IAPHelper {
    static let sharedManager = IAPurchaseManager(productIdentifiers: ["VS01"])
    
    class func saveDefaultsToUserDefault(productIdentifier: String) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: productIdentifier)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
