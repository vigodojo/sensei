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
    
    func imageWithAttributedText(text: NSAttributedString) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        drawInRect(CGRect(origin: CGPointZero, size: size))
        let textSize = txtSizeForText(text)
        let textOrigin = textOriginForTextSize(textSize)
        text.drawInRect(CGRect(origin: textOrigin, size: textSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func imageWithAttributedText(text: NSAttributedString, completion: (image: UIImage) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { [unowned self] () -> Void in
            let image = self.imageWithAttributedText(text)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(image: image)
            })
        })
    }
    
    private func txtSizeForText(text: NSAttributedString) -> CGSize {
        return text.boundingRectWithSize(CGSize(width: size.width, height: CGFloat.max), options: .UsesLineFragmentOrigin | .UsesFontLeading, context: nil).size
    }
    
    private func textOriginForTextSize(textSize: CGSize) -> CGPoint {
        var textOrigin = CGPointZero
        textOrigin.x = (size.width - textSize.width) / 2.0
        textOrigin.y = size.height - textSize.height
        return textOrigin
    }
}

