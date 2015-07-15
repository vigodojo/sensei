//
//  AnimatableImageView.swift
//  Sensei
//
//  Created by Sauron Black on 7/15/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class AnimatableImageView: UIImageView {
    
    private struct Constants {
        static let KeyPathContents = "contents"
    }

    private var completionClosure: ((finished: Bool) -> Void)?
    
    func  animateAnimatableImage(animatableImage: AnimatableImage, completion: ((finished: Bool) -> Void)?) {
        completionClosure = completion
        let animation = CAKeyframeAnimation()
        animation.keyPath = Constants.KeyPathContents
        animation.values = animatableImage.images.map { $0.CGImage }
        animation.duration = animatableImage.animationDuration
        animation.repeatCount = Float(animatableImage.animationRepeatCount)
        animation.delegate = self
        
        layer.addAnimation(animation, forKey: nil)
    }
 
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if let completionClosure = completionClosure {
            completionClosure(finished: flag)
        }
    }

}
