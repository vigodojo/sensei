//
//  AnimationManager.swift
//  Sensei
//
//  Created by Sergey Sheba on 1/25/16.
//  Copyright © 2016 ThinkMobiles. All rights reserved.
//

import UIKit

class AnimationManager: NSObject {
    
    static let sharedManager = AnimationManager()
    
    func bowsAnimatableImage() -> AnimatableImage? {
        return animatableImageWithAnimationName("StandsBow")
    }
    
    func sitsBowAnimatableImage() -> AnimatableImage? {
        return animatableImageWithAnimationName("SitsBow")
    }
    
    func sitStandAnimatableImage() -> AnimatableImage? {
        return animatableImageWithAnimationName("SitStand")
    }
    
    func sitDownAnimatableImage() -> AnimatableImage? {
        if let animatableImage = sitStandAnimatableImage() {
            return reversedAnimatableImage(animatableImage)
        }
        return nil
    }
    
    func reversedAnimatableImage(animatableImage: AnimatableImage) -> AnimatableImage? {
        let reversedImage = animatableImage
        reversedImage.imageNames = reversedImage.imageNames.reverse()
        reversedImage.images = reversedImage.images.reverse()
        return reversedImage
    }
    
    func animatableImageWithAnimationName(name: String) -> AnimatableImage? {
        if let animationsURL = NSBundle.mainBundle().URLForResource("Animations", withExtension: "plist") {
            if let animationsArray = NSArray(contentsOfURL: animationsURL) as? [[String: AnyObject]] {
                for animationDictionary in animationsArray {
                    if animationDictionary["Name"] as! String == name {
                        return AnimatableImage(dictionary: animationDictionary["AnimatableImage"] as! Dictionary)
                    }
                }
            }
        }
        return nil
    }
}
