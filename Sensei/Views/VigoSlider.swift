//
//  VigoSlider.swift
//  Sensei
//
//  Created by Sauron Black on 6/15/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

@IBDesignable
class VigoSlider: UIControl {
    
    @IBInspectable var minValue = 0
    @IBInspectable var maxValue = 6
    @IBInspectable var stepValue = 1
    @IBInspectable var currentValue = 0
    
    @IBInspectable var lineWidth: CGFloat = 1.0
    @IBInspectable var lineColor: UIColor = UIColor.blackColor()
    @IBInspectable var divisionHeight: CGFloat = 10.0
    
    private weak var thumbView: VigoSliderThumbView!
    private weak var tapGesture: UITapGestureRecognizer!
    
    override var bounds: CGRect {
        didSet {
            updateThumbViewCenterAnimated(false)
            setNeedsDisplay()
        }
    }
    
    private var scaleWidth: CGFloat {
        return CGRectGetWidth(bounds) - CGRectGetWidth(thumbView.bounds)
    }
    
    private var scaleStartX: CGFloat {
        return CGRectGetMidX(thumbView.bounds)
    }
    
    private var scaleCenterY: CGFloat {
        return CGRectGetMidY(bounds)
    }
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print("awakeFromNib: \(thumbView)")
        if thumbView == nil {
            setCustomThumbView(createDefaultTumbView())
        }
    }

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context!)
        drawScaleInContext(context!)
        CGContextRestoreGState(context!)
    }
    
    // MARK: Public
    
    func setCustomThumbView(view: VigoSliderThumbView) {
        if thumbView != nil {
            thumbView.removeFromSuperview()
        }
        view.userInteractionEnabled = false
        addSubview(view)
        thumbView = view
        // TODO: Set Center
    }
    
    func setCurrentValue(value: Int, animated: Bool) {
        currentValue = min(max(value, minValue), maxValue)
        updateThumbViewCenterAnimated(animated)
    }
    
    // MARK: Private
    
    private func setup() {
        setCustomThumbView(createDefaultTumbView())
        createTapGesture()
    }
    
    private func createTapGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(VigoSlider.tap(_:)))
        addGestureRecognizer(gesture)
        tapGesture = gesture
    }
    
    private func createDefaultTumbView() -> VigoSliderThumbView {
        let size = CGSize(width: CGRectGetHeight(frame), height: CGRectGetHeight(frame))
        let view = NumberThumbView(frame: CGRect(origin: CGPointZero, size: size))
        return view
    }
    
    private func drawScaleInContext(context: CGContextRef) {
        CGContextSetLineWidth(context, lineWidth)
        CGContextSetStrokeColorWithColor(context, lineColor.CGColor)
        
        CGContextMoveToPoint(context, scaleStartX, scaleCenterY)
        CGContextAddLineToPoint(context, CGRectGetWidth(bounds) - scaleStartX, scaleCenterY)
        
        var value = minValue
        while value <= maxValue {
            let x = thumbXPositionForValue(value)
            CGContextMoveToPoint(context, x, scaleCenterY - divisionHeight / 2.0)
            CGContextAddLineToPoint(context, x, scaleCenterY + divisionHeight / 2.0)
            value += stepValue
        }
        CGContextStrokePath(context)
    }
    
    private func thumbXPositionForValue(value: Int) -> CGFloat {
        return CGFloat(value - minValue) / CGFloat(maxValue - minValue) * scaleWidth + scaleStartX
    }
    
    private func valueForThumbXPosition(x: CGFloat, rounded: Bool) -> Int {
        let realValue = (x - scaleStartX) / scaleWidth * CGFloat(maxValue - minValue)
        return Int(rounded ? round(realValue): realValue) + minValue
    }
    
    private func updateThumbViewCenterAnimated(animated: Bool) {
        let x = thumbXPositionForValue(currentValue)
        if x == thumbView.center.x {
            return
        }
        
        self.thumbView.didChangeValue(self.currentValue)
        if !animated {
            thumbView.center = CGPoint(x: x, y: scaleCenterY)
        } else {
            UIView.animateWithDuration(AnimationDuration, animations: { [unowned self] () -> Void in
                self.thumbView.center = CGPoint(x: x, y: self.scaleCenterY)
            })
        }
    }
    
    private func setCurrentValueFromThumbXPosition(x: CGFloat, rounded: Bool) {
        var value = valueForThumbXPosition(x, rounded: rounded)
        value = min(max(minValue, value), maxValue)
        if value != currentValue {
            thumbView.didChangeValue(value)
            currentValue = value
            sendActionsForControlEvents(UIControlEvents.ValueChanged)
        }
    }
    
    // MARK: Tracking
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let shouldBegin = thumbView.frame.contains(touch.locationInView(self))
        tapGesture.enabled = !shouldBegin
        return shouldBegin
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let locationX = touch.locationInView(self).x
        if locationX >= scaleStartX && locationX <= (1.2 * scaleStartX + scaleWidth) {
            thumbView.center = CGPoint(x: locationX, y: scaleCenterY)
            setCurrentValueFromThumbXPosition(locationX, rounded: false)
        }
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        setCurrentValueFromThumbXPosition(touch!.locationInView(self).x, rounded: true)
        updateThumbViewCenterAnimated(true)
        tapGesture.enabled = true
    }
    
    // MARK: Taping 
    
    func tap(sender: UITapGestureRecognizer) {
        let location = sender.locationInView(self)
        if !thumbView.frame.contains(location) {
            setCurrentValueFromThumbXPosition(location.x, rounded: true)
            updateThumbViewCenterAnimated(true)
        }
    }
}

class VigoSliderThumbView: UIView {
    
    func didChangeValue(newValue: Int) {}
}
