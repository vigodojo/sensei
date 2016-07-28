//
//  SettingsTextField.swift
//  Sensei
//
//  Created by Sergey Sheba on 07.06.16.
//  Copyright © 2016 ThinkMobiles. All rights reserved.
//

import UIKit

class SettingsTextField: UITextField {
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject!) -> Bool {
        return false
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer && ((gestureRecognizer as! UITapGestureRecognizer).numberOfTapsRequired == 1) {
            let touchPoint = gestureRecognizer.locationOfTouch(0, inView: self)
            if let cursorPosition = closestPositionToPoint(touchPoint) {
                selectedTextRange = textRangeFromPosition(cursorPosition, toPosition: cursorPosition)
            }
            return true
        } else {
            return false
        }
    }
    
}
