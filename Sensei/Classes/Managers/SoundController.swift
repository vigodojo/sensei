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
    
    static var player = AVAudioPlayer()
    
    class func playTock() {
        var tockURL = NSURL(string:"file:///System/Library/Audio/UISounds/Tock.caf")
        
        if let URL = NSUserDefaults.standardUserDefaults().stringForKey("SoundURL") {
            tockURL = NSURL(string:URL)
        } else {
            NSUserDefaults.standardUserDefaults().setObject(tockURL?.absoluteString, forKey: "SoundURL")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        do {
            if let url = tockURL {
                self.player = try AVAudioPlayer(contentsOfURL: url)
                self.player.volume = AVAudioSession.sharedInstance().outputVolume
                self.player.play()
            }
        } catch {
            print(error)
        }
    }
}