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
        view.translatesAutoresizingMaskIntoConstraints = false
        let bindings = ["view": view]
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0.0-[view]-0.0-|", options: NSLayoutFormatOptions(), metrics: nil, views: bindings))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0.0-[view]-0.0-|", options: NSLayoutFormatOptions(), metrics: nil, views: bindings))
    }
    
    var borderColor: UIColor? {
        get {
			if let borderColor = layer.borderColor {
				return UIColor(CGColor: borderColor)
			} else {
				return nil
			}
        }
        set {
            layer.borderColor = newValue?.CGColor ?? UIColor.clearColor().CGColor
        }
    }
}

// MARK: - UITextView+Append

extension UITextView {
    
    func appendText(text: String) {
        layoutManager.allowsNonContiguousLayout = false
        let prevText = self.text
        self.text = text
        self.font = UIFont(name: "HelveticaNeue-Bold", size: 13.0)
        layoutIfNeeded()
        let size = self.contentSize
        self.text = prevText

        if !self.text.isEmpty {
            self.text.appendContentsOf("\n\n")
        }
        self.text.appendContentsOf(text)

        var bottomOffset = CGRectGetHeight(frame) - size.height
        if bottomOffset < 0 {
            bottomOffset = 0
        }
        
        self.font = UIFont(name: "HelveticaNeue-Bold", size: 13.0)
        layoutIfNeeded()
        let finalSize = self.contentSize
        let contentOffset = finalSize.height - size.height

        textContainerInset = UIEdgeInsetsMake(0, 0, bottomOffset, 0)
        setContentOffset(CGPointMake(0, contentOffset), animated: true)
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
    
    func find(includedElement: Element -> Bool) -> Int? {
        for (idx, element) in self.enumerate() {
            if includedElement(element) {
                return idx
            }
        }
        return nil
    }
    
    func contains<T : Equatable>(obj: T) -> Bool {
        let filtered = self.filter { $0 as? T == obj }
        return filtered.count > 0
    }
}

// MARK: - Dictionary

func + <K,V>(left: [K:V], right: [K:V]) -> [K:V] {
    var map = [K:V]()
    for (k, v) in left {
        map[k] = v
    }
    for (k, v) in right {
        map[k] = v
    }
    return map
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
        
        let context = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), CGImageGetBitsPerComponent(CGImage), 0, CGImageGetColorSpace(CGImage), CGImageGetBitmapInfo(CGImage).rawValue)
        CGContextConcatCTM(context, transform)
        switch imageOrientation {
            case .Left, .LeftMirrored, .Right, .RightMirrored:
                CGContextDrawImage(context, CGRect(origin: CGPointZero, size: CGSize(width: size.height, height: size.width)), CGImage)
            default:
                CGContextDrawImage(context, CGRect(origin: CGPointZero, size: size), CGImage)
        }
        
        let newCGImage = CGBitmapContextCreateImage(context)
        let newImage = UIImage(CGImage: newCGImage!)
        return newImage
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

// MARK: - UIFont

extension UIFont {
    class func helveticaNeueBlackOfSize(fontSize: CGFloat) -> UIFont {
        return UIFont(name: "HelveticaNeue-CondensedBlack", size: fontSize)!
    }
    
    class var speechBubbleTextFont: UIFont {
        return UIFont(name: "HelveticaNeue-Bold", size: 13)!
    }
}

// MARK: - String

extension String {

	func rangeFromNSRange(nsRange: NSRange) -> Range<String.Index>? {
		let from16 = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
		if let from = String.Index(from16, within: self),
			let to = String.Index(from16.advancedBy(nsRange.length, limit: utf16.endIndex), within: self) {
				return from ..< to
		}
		return nil
	}

	func substringWithNSRange(nsRange: NSRange) -> String {
		if let range = rangeFromNSRange(nsRange) {
			return substringWithRange(range)
		} else {
			return (self as NSString).substringWithRange(nsRange)
		}
	}
}

// MARK: - UIScrollView

extension UIScrollView {
    /**
     Check whether scroll view has been scrolled to bottom
     */
    func scrollViewDidScrollToTop() -> Bool
    {
        let scrollOffset        = self.contentOffset
        return scrollOffset.y == 0
    }
    
    func scrollViewDidScrollToBottom() -> Bool
    {
        let scrollOffset        = self.contentOffset
        let scrollBounds        = self.bounds
        let scrollContentSize   = self.contentSize
        let scrollInsets        = self.contentInset
        
        let y = scrollOffset.y + CGRectGetHeight(scrollBounds) - scrollInsets.bottom
        let h = scrollContentSize.height
        
        return y >= h
    }
}

// MARK: - CFRange - NSRange

func NSRangeFromCFRange(range: CFRange) -> NSRange {
	return NSMakeRange(range.location, range.length)
}
