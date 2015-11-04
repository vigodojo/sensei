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
    
    static func showDialogAlert(title: String?, message: String?, fromController: UIViewController, completion: ((UIAlertAction, Bool) -> Void)?) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (alertAction) -> Void in
            if let result = completion {
                result(alertAction, false)
            }
        }
        let confirmAction = UIAlertAction(title: "OK", style: .Default) { (alertAction) -> Void in
            if let result = completion {
                result(alertAction, true)
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        
        fromController.presentViewController(alertController, animated: true, completion: nil)
    }
}