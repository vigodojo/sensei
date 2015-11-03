//
//  AlertMessagesService.swift
//  Sensei
//
//  Created by Eugenity on 03.11.15.
//  Copyright © 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class AlertMessagesService {
    
    static func showWarningAlert(title: String?, message: String?, fromController: UIViewController, completion: ((UIAlertAction) -> Void)?) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "OK", style: .Default, handler: completion)
        alertController.addAction(cancelAction)
        fromController.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
}