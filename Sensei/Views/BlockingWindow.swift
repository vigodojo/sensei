//
//  BlockingWindow.swift
//  Sensei
//
//  Created by Sauron Black on 7/1/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class BlockingWindow: UIWindow {
    
    static var shardeInstance: BlockingWindow = {
        let window = BlockingWindow(frame: UIScreen.mainScreen().bounds)
        window.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
        window.windowLevel = UIWindowLevelStatusBar
        return window
    }()
    
    class func showWithStartFrame(startFrame: CGRect, endFrame: CGRect) {
        shardeInstance.frame = startFrame
        shardeInstance.hidden = false
        shardeInstance.alpha = 0.0
        UIView.animateWithDuration(AnimationDuration, animations: { () -> Void in
            self.shardeInstance.alpha = 1.0
            self.shardeInstance.frame = endFrame
        })

    }
    
    class func hideWithStartFrame(startFrame: CGRect, endFrame: CGRect) {
        shardeInstance.frame = startFrame
        UIView.animateWithDuration(AnimationDuration, animations: { () -> Void in
            self.shardeInstance.alpha = 0.0
            self.shardeInstance.frame = endFrame
        }, completion: { finished in
            self.shardeInstance.hidden = true
        })
    }
}