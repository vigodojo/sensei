//
//  SpeechBubbleView.swift
//  Sensei
//
//  Created by Sauron Black on 5/14/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

@IBDesignable
class SpeechBubbleView: UIView {
    
    enum PointerPosition: Int {
        case Left = 0
        case Right
    }
    
    @IBInspectable var strokeColor: UIColor = UIColor.blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var fillColor: UIColor = UIColor.whiteColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var cornerRadius: CGFloat = 6.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var lineWidth: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var pointerOffset: CGFloat = 6.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var pointerSize: CGSize = CGSize(width: 20, height: 10){
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var pointerPositionNumber: Int = PointerPosition.Right.rawValue {
        didSet {
            pointerPosition = PointerPosition(rawValue: pointerPositionNumber) ?? .Right
        }
    }
    
    var pointerPosition: PointerPosition = PointerPosition.Right {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        var beziePath: UIBezierPath
        switch pointerPosition {
            case .Left: beziePath = bezierPathForLeft()
            case .Right: beziePath = bezierPathForRight()
        }
        beziePath.lineWidth = lineWidth
        strokeColor.setStroke()
        fillColor.setFill()
        beziePath.stroke()
        beziePath.fill()
    }
    
    private func bezierPathForLeft() -> UIBezierPath {
        var beziePath = UIBezierPath()
        var point = CGPoint(x: CGRectGetWidth(bounds) - cornerRadius - 0.5, y: cornerRadius + 0.5)
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(-M_PI_2), clockwise: false)
        point = beziePath.currentPoint
        point.x = cornerRadius + pointerSize.width
        beziePath.addLineToPoint(point)
        point.y = cornerRadius + 0.5
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(-M_PI_2), endAngle: CGFloat(M_PI), clockwise: false)
        point = beziePath.currentPoint
        point.y += pointerOffset
        beziePath.addLineToPoint(point)
        point.x -= pointerSize.width
        point.y += pointerSize.height
        beziePath.addLineToPoint(point)
        point.x += pointerSize.width
        beziePath.addLineToPoint(point)
        point.y = CGRectGetHeight(bounds) - cornerRadius - CGFloat(0.5)
        beziePath.addLineToPoint(point)
        point.x += cornerRadius
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI_2), clockwise: false)
        point = beziePath.currentPoint
        point.x = CGRectGetWidth(bounds) - cornerRadius - 0.5
        beziePath.addLineToPoint(point)
        point.y -= cornerRadius
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(M_PI_2), endAngle: 0.0, clockwise: false)
        beziePath.closePath()
        return beziePath
    }
    
    private func bezierPathForRight() -> UIBezierPath {
        var beziePath = UIBezierPath()
        var point = CGPoint(x: cornerRadius + 0.5, y: cornerRadius + 0.5)
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(-M_PI_2), clockwise: true)
        point = beziePath.currentPoint
        point.x = CGRectGetWidth(bounds) - cornerRadius - pointerSize.width
        beziePath.addLineToPoint(point)
        point.y = cornerRadius + 0.5
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(-M_PI_2), endAngle: 0.0, clockwise: true)
        point = beziePath.currentPoint
        point.y += pointerOffset
        beziePath.addLineToPoint(point)
        point.x += pointerSize.width
        point.y += pointerSize.height
        beziePath.addLineToPoint(point)
        point.x -= pointerSize.width
        beziePath.addLineToPoint(point)
        point.y = CGRectGetHeight(bounds) - cornerRadius - CGFloat(0.5)
        beziePath.addLineToPoint(point)
        point.x -= cornerRadius
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: 0, endAngle: CGFloat(M_PI_2), clockwise: true)
        point = beziePath.currentPoint
        point.x = cornerRadius + 0.5
        beziePath.addLineToPoint(point)
        point.y -= cornerRadius
        beziePath.addArcWithCenter(point, radius: cornerRadius, startAngle: CGFloat(M_PI_2), endAngle: CGFloat(M_PI), clockwise: true)
        beziePath.closePath()
        return beziePath
    }
}

extension UIView {
    
    var borderColor: UIColor? {
        get {
            return UIColor(CGColor: layer.borderColor)
        }
        set {
             layer.borderColor = newValue?.CGColor ?? UIColor.clearColor().CGColor
        }
    }
}
