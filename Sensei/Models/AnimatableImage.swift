//
//  AnimatableImage.swift
//  Sensei
//
//  Created by Sauron Black on 7/15/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class AnimatableImage {
 
    private struct Keys {
        static let ImageNames = "ImageNames"
        static let AnimationDuration = "AnimationDuration"
        static let AnimationRepeatCount = "AnimationRepeatCount"
    }
    
    var imageNames = [String]()
    var images = [UIImage]()
    var animationDuration: Double = 1
    var animationRepeatCount = 1
    
    init(dictionary: [String: AnyObject]) {
        imageNames = dictionary[Keys.ImageNames] as? [String] ?? []
        images = imagesWithImageNames(imageNames)
        animationDuration = (dictionary[Keys.AnimationDuration] as? NSNumber)?.doubleValue ?? 1
        animationRepeatCount = (dictionary[Keys.AnimationRepeatCount] as? NSNumber)?.integerValue ?? 1
    }
    
    private func imagesWithImageNames(imageNames: [String]) -> [UIImage] {
        var images = [UIImage]()
        for name in imageNames {
            if let image = UIImage(named: name) {
                images.append(image)
            }
        }
        return images
    }
}