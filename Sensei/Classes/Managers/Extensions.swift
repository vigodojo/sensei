//
//  Extensions.swift
//  Sensei
//
//  Created by Sauron Black on 6/8/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

// MARK: - UIView

extension UIView {
    
    func addEdgePinnedSubview(view: UIView) {
        view.frame = bounds
        addSubview(view)
        view.setTranslatesAutoresizingMaskIntoConstraints(false)
        let bindings = ["view": view]
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0.0-[view]-0.0-|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: bindings))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0.0-[view]-0.0-|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: bindings))
    }
    
    var borderColor: UIColor? {
        get {
            return UIColor(CGColor: layer.borderColor)
        }
        set {
            layer.borderColor = newValue?.CGColor ?? UIColor.clearColor().CGColor
        }
    }
}

// MARK: - UIColor+Hex

extension UIColor {
    
    convenience init(hexColor: Int, alpha: CGFloat) {
        let red: CGFloat = CGFloat((hexColor >> 16) & 0xff) / 255.0
        let green: CGFloat = CGFloat((hexColor >> 8) & 0xff) / 255.0
        let blue: CGFloat = CGFloat(hexColor & 0xff) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    convenience init(hexColor: Int) {
        self.init(hexColor: hexColor, alpha: 1.0)
    }
}

// MARK: - Array+Find

extension Array {
    
    func find(includedElement: T -> Bool) -> Int? {
        for (idx, element) in enumerate(self) {
            if includedElement(element) {
                return idx
            }
        }
        return nil
    }
}

// MARK: - UIImage+Text

extension UIImage {
    
    var upOrientedImage: UIImage {
        if imageOrientation == .Up {
            return self
        }
        
        var transform = CGAffineTransformIdentity
        
        switch imageOrientation {
            case .Down, .DownMirrored:
                transform = CGAffineTransformTranslate(transform, size.width, size.height)
                transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
            case .Left, .LeftMirrored:
                transform = CGAffineTransformTranslate(transform, size.width, 0)
                transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
            case .Right, .RightMirrored:
                transform = CGAffineTransformTranslate(transform, 0, size.height)
                transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
            default:
                break
        }
        
        switch imageOrientation {
            case .UpMirrored, .DownMirrored:
                transform = CGAffineTransformTranslate(transform, size.width, 0)
                transform = CGAffineTransformScale(transform, -1, 1)
            case .LeftMirrored, .RightMirrored:
                transform = CGAffineTransformTranslate(transform, size.height, 0);
                transform = CGAffineTransformScale(transform, -1, 1);
            default:
                break;
        }
        
        let context = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), CGImageGetBitsPerComponent(CGImage), 0, CGImageGetColorSpace(CGImage), CGImageGetBitmapInfo(CGImage))
        CGContextConcatCTM(context, transform)
        switch imageOrientation {
            case .Left, .LeftMirrored, .Right, .RightMirrored:
                CGContextDrawImage(context, CGRect(origin: CGPointZero, size: CGSize(width: size.height, height: size.width)), CGImage)
            default:
                CGContextDrawImage(context, CGRect(origin: CGPointZero, size: size), CGImage)
        }
        
        let newCGImage = CGBitmapContextCreateImage(context)
        let newImage = UIImage(CGImage: newCGImage)
        return newImage!
    }
    
    var fullScreenImage: UIImage {
        let screenBounds = UIScreen.mainScreen().bounds
        let scale = UIScreen.mainScreen().nativeScale
        let screenDimension = min(CGRectGetWidth(screenBounds), CGRectGetHeight(screenBounds)) * scale
        let imageDimension = min(self.size.width, self.size.height)
        let coef = screenDimension / imageDimension
        if coef >= 1 {
            return self
        }
        let newSize = CGSizeMake(size.width * coef, size.height * coef);
        UIGraphicsBeginImageContext(newSize);
        drawInRect(CGRect(origin: CGPointZero, size: newSize))
        let fullScreenImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return fullScreenImage;
    }
}
