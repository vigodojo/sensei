//
//  SoundController.swift
//  Sensei
//
//  Created by Sergey Sheba on 16.05.16.
//  Copyright © 2016 ThinkMobiles. All rights reserved.
//

import UIKit
import AVFoundation

class SoundController: NSObject {
    
    
    
    class func playTock() {
        var tockURL = NSURL(string:"file:///System/Library/Audio/UISounds/Tock.caf")
        
        if let URL = NSUserDefaults.standardUserDefaults().stringForKey("SoundURL") {
            tockURL = NSURL(string:URL)
        } else {
            NSUserDefaults.standardUserDefaults().setObject(tockURL?.absoluteString, forKey: "SoundURL")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(tockURL!, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
}
