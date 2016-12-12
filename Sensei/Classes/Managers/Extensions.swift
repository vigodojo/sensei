//
//  Extensions.swift
//  Sensei
//
//  Created by Sauron Black on 6/8/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit


// MARK: - NSDate

extension NSDate {
    
    func dateLessDate() -> NSDate {
        let components = NSCalendar.currentCalendar().components([NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.TimeZone], fromDate: self)
        return NSCalendar.currentCalendar().dateFromComponents(components)!
    }
    
    func timeless() -> NSDate {
        let components = NSCalendar.currentCalendar().components([NSCalendarUnit.Era, NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: self)
        return NSCalendar.currentCalendar().dateFromComponents(components)!
    }
    
    func dateBetweenDates(firstDate: NSDate, lastDate: NSDate) -> Bool {
        return self.compare(firstDate) == .OrderedDescending && self.compare(lastDate) == .OrderedAscending
    }

    func timeComponents() -> NSDateComponents {
        return NSCalendar.currentCalendar().components([NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.TimeZone], fromDate: self)
    }
    
    func fullDaysSinceNow() -> Int {
        let interval = self.timeIntervalSinceNow
        print(self)
        
        return Int(floor(abs(interval)/60.0))//*60.0*24.0))
    }
    
    func minutesSinceLastMidnight() -> NSInteger {
        let components = self.timeComponents()
        let hours = components.hour
        let minutes = components.minute
        return hours * 60 + minutes
    }
}

// MARK: - NSObject

extension NSObject {
    func addLoader() {
        removeLoader()
        
        let loaderView = UIView(frame: UIScreen.mainScreen().bounds)
        loaderView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        loaderView.tag = 999
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activityIndicator.center = CGPoint(x: UIScreen.mainScreen().bounds.size.width/2, y: UIScreen.mainScreen().bounds.size.height/2)
        activityIndicator.startAnimating()
        loaderView.addSubview(activityIndicator)
        UIApplication.sharedApplication().keyWindow?.addSubview(loaderView)
    }
    
    func removeLoader() {
        guard let subviews = UIApplication.sharedApplication().keyWindow?.subviews else { return }
        for view in subviews {
            if view.tag == 999 {
                view.removeFromSuperview()
            }
        }
    }
}

// MARK: - UIViewController

extension UIViewController {
    func dispatchInMainThreadAfter(delay delay: Float, completion: () -> Void) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(delay) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
            completion()
        }
    }
}

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
    
    func appendText(textToAppend: String, autoscroll: Bool) {
        layoutManager.allowsNonContiguousLayout = false
        textContainerInset = UIEdgeInsetsZero
        let prevText = self.text
        self.text = textToAppend
        self.font = UIFont.speechBubbleTextFont
        layoutIfNeeded()
        let textSize = self.contentSize
        self.text = prevText
        layoutIfNeeded()

        if self.contentSize.height % 64 > 0 {
            let mult = ceil(self.contentSize.height / 64)
            self.contentSize = CGSize(width: self.contentSize.width, height: 64*mult)
        }
        
        let offset = self.contentSize.height
        if !self.text.isEmpty {
            self.text.appendContentsOf("\n")
        }
        self.text.appendContentsOf(textToAppend)

        self.font = UIFont.speechBubbleTextFont
        layoutIfNeeded()

        var numberOfLines = Int(ceil(textSize.height/(self.frame.size.height/4)))
        
        if numberOfLines > 4 {
            numberOfLines-=4
        }
        numberOfLines = 4-numberOfLines
        
        if numberOfLines > 0 {
            for _ in 0...(numberOfLines-1) {
                self.text.appendContentsOf("\n")
            }
        }

        self.font = UIFont.speechBubbleTextFont
        layoutIfNeeded()
        if autoscroll == true {
            setContentOffset(CGPointMake(0, offset), animated: true)
        }
    }

    func textInFrame(receivedFrame: CGRect) -> String {
        var receivedFrame = receivedFrame
        self.selectable = true

        receivedFrame.origin = CGPoint(x: contentInset.left, y: CGRectGetHeight(self.frame) - CGRectGetHeight(receivedFrame))

        let startCharacterRange = self.closestPositionToPoint(receivedFrame.origin)
        if startCharacterRange == nil {
            return ""
        }
        
        let endCharacterRange = self.closestPositionToPoint(CGPointMake(CGRectGetWidth(receivedFrame), CGRectGetMaxY(receivedFrame)))
        if endCharacterRange == nil {
            return ""
        }

        let startIndex = self.offsetFromPosition(self.beginningOfDocument, toPosition: startCharacterRange!)
        let endIndex = self.offsetFromPosition(startCharacterRange!, toPosition: endCharacterRange!)
            
        return (self.text as NSString).substringWithRange(NSMakeRange(startIndex, endIndex)) as String
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
        
        let context = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), CGImageGetBitsPerComponent(CGImage!), 0, CGImageGetColorSpace(CGImage!)!, CGImageGetBitmapInfo(CGImage!).rawValue)
        CGContextConcatCTM(context!, transform)
        switch imageOrientation {
            case .Left, .LeftMirrored, .Right, .RightMirrored:
                CGContextDrawImage(context!, CGRect(origin: CGPointZero, size: CGSize(width: size.height, height: size.width)), CGImage!)
            default:
                CGContextDrawImage(context!, CGRect(origin: CGPointZero, size: size), CGImage!)
        }
        
        let newCGImage = CGBitmapContextCreateImage(context!)
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
        let newSize = CGSizeMake(floor(size.width * coef), floor(size.height * coef));
        UIGraphicsBeginImageContext(newSize);
        drawInRect(CGRect(origin: CGPointZero, size: newSize))
        let fullScreenImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return fullScreenImage!;
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
